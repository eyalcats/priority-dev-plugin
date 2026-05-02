const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { readQueue, appendCandidate, removeCandidate, mergeUserLocal, countByClassification } = require("./pending-queue");

function tmpFile(contents) {
  const p = path.join(os.tmpdir(), `pq-test-${Date.now()}-${Math.random().toString(36).slice(2)}.yaml`);
  fs.writeFileSync(p, contents, "utf8");
  return p;
}

test("readQueue on empty seed returns empty array", () => {
  const p = tmpFile("candidates: []\n");
  assert.deepEqual(readQueue(p), []);
});

test("appendCandidate adds an entry with an id and added_at", () => {
  const p = tmpFile("candidates: []\n");
  const id = appendCandidate(p, {
    source_mode: "bootstrap",
    source_ref: "FNCIVITEMS",
    classification: "missing",
    pattern_name: "Dynamic zoom resolver",
    pattern_signature: "dyn-zoom-logfile",
    evidence: { metadata_table: "FORMTRIGTEXT", snippet: "SELECT EXEC INTO :X FROM EXEC WHERE ENAME = 'Y';" },
    proposed_edit: { target: "references/triggers.md §Dynamic Access", diff: "..." },
    notes: "New pattern"
  });
  const queue = readQueue(p);
  assert.equal(queue.length, 1);
  assert.equal(queue[0].id, id);
  assert.ok(queue[0].added_at, "added_at should be set");
  assert.equal(queue[0].classification, "missing");
});

test("removeCandidate drops the matching id", () => {
  const p = tmpFile("candidates: []\n");
  const idA = appendCandidate(p, { source_mode: "bootstrap", source_ref: "A", classification: "missing", pattern_name: "A", pattern_signature: "a", evidence: {}, proposed_edit: {}, notes: "" });
  const idB = appendCandidate(p, { source_mode: "bootstrap", source_ref: "B", classification: "missing", pattern_name: "B", pattern_signature: "b", evidence: {}, proposed_edit: {}, notes: "" });
  removeCandidate(p, idA);
  const remaining = readQueue(p);
  assert.equal(remaining.length, 1);
  assert.equal(remaining[0].id, idB);
});

test("countByClassification tallies entries", () => {
  const p = tmpFile("candidates: []\n");
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "A", classification: "missing", pattern_name: "A", pattern_signature: "a", evidence: {}, proposed_edit: {}, notes: "" });
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "B", classification: "partial", pattern_name: "B", pattern_signature: "b", evidence: {}, proposed_edit: {}, notes: "" });
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "C", classification: "missing", pattern_name: "C", pattern_signature: "c", evidence: {}, proposed_edit: {}, notes: "" });
  const counts = countByClassification(p);
  assert.deepEqual(counts, { missing: 2, partial: 1, "new-category": 0 });
});

test("mergeUserLocal moves entries from user-local file into project queue, then empties user-local", () => {
  const projectP = tmpFile("candidates: []\n");
  const userP = tmpFile("candidates: []\n");
  appendCandidate(userP, { source_mode: "continuous", source_ref: "sess-1", classification: "missing", pattern_name: "X", pattern_signature: "x", evidence: {}, proposed_edit: {}, notes: "" });
  const moved = mergeUserLocal(projectP, userP);
  assert.equal(moved, 1);
  assert.equal(readQueue(projectP).length, 1);
  assert.equal(readQueue(userP).length, 0);
});

test("round-trip preserves multiline snippet with colons", () => {
  const p = tmpFile("candidates: []\n");
  const snippet = "SELECT EXEC INTO :X\nFROM EXEC\nWHERE ENAME = 'Y';";
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "T", classification: "missing", pattern_name: "T", pattern_signature: "t", evidence: { metadata_table: "FORMTRIGTEXT", snippet }, proposed_edit: { target: "references/triggers.md §X", diff: "..." }, notes: "" });
  const q = readQueue(p);
  assert.equal(q[0].evidence.snippet, snippet);
});

test("round-trip preserves string containing double quotes", () => {
  const p = tmpFile("candidates: []\n");
  const notes = 'he said "hello" and left';
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "Q", classification: "missing", pattern_name: "Q", pattern_signature: "q", evidence: {}, proposed_edit: {}, notes });
  const q = readQueue(p);
  assert.equal(q[0].notes, notes);
});

test("string 'true' stays a string, not a boolean", () => {
  const p = tmpFile("candidates: []\n");
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "B", classification: "missing", pattern_name: "true", pattern_signature: "true", evidence: {}, proposed_edit: {}, notes: "" });
  const q = readQueue(p);
  assert.equal(q[0].pattern_signature, "true");
  assert.equal(typeof q[0].pattern_signature, "string");
});

test("digit-only string stays a string, not a number", () => {
  const p = tmpFile("candidates: []\n");
  appendCandidate(p, { source_mode: "bootstrap", source_ref: "N", classification: "missing", pattern_name: "N", pattern_signature: "12345", evidence: {}, proposed_edit: {}, notes: "" });
  const q = readQueue(p);
  assert.equal(q[0].pattern_signature, "12345");
  assert.equal(typeof q[0].pattern_signature, "string");
});

test("readQueue on nonexistent file returns []", () => {
  const p = path.join(os.tmpdir(), `pq-nonexistent-${Date.now()}.yaml`);
  assert.deepEqual(readQueue(p), []);
});

const { partitionForEval, deriveSandboxPrefix, validateVerdict, applyVerdicts } = require("./pending-queue");

test("partitionForEval splits queue by deferral rule", () => {
  const p = tmpFile("candidates: []\n");
  // partial w/ 1 source → deferred
  appendCandidate(p, { source_mode: "continuous", source_ref: "S1", classification: "partial",
    pattern_name: "P1", pattern_signature: "p1", evidence: {}, proposed_edit: {}, notes: "" });
  // partial w/ 2 distinct sources → admit-eligible
  const id2 = appendCandidate(p, { source_mode: "continuous", source_ref: "S1", classification: "partial",
    pattern_name: "P2", pattern_signature: "p2", evidence: {}, proposed_edit: {}, notes: "" });
  appendCandidate(p, { source_mode: "continuous", source_ref: "S2", classification: "partial",
    pattern_name: "P2", pattern_signature: "p2", evidence: {}, proposed_edit: {}, notes: "" });
  // missing → admit-eligible regardless of count
  appendCandidate(p, { source_mode: "continuous", source_ref: "S1", classification: "missing",
    pattern_name: "P3", pattern_signature: "p3", evidence: {}, proposed_edit: {}, notes: "" });

  const queue = readQueue(p);
  const { admitEligible, deferred } = partitionForEval(queue);

  assert.equal(deferred.length, 1, "one partial w/ <2 sources should be deferred");
  assert.equal(deferred[0].pattern_signature, "p1");
  assert.equal(admitEligible.length, 3, "P2 group + P3 missing should be admit-eligible");
});

test("deriveSandboxPrefix uses last 8 hex chars of UUID", () => {
  assert.equal(
    deriveSandboxPrefix("a1b2c3d4-e5f6-7890-abcd-ef1234567801"),
    "EVAL_34567801"
  );
  assert.equal(
    deriveSandboxPrefix("f13a9b2c-d4e5-6f78-90ab-cdef12345613"),
    "EVAL_12345613"
  );
});

test("deriveSandboxPrefix rejects non-uuid input", () => {
  assert.throws(() => deriveSandboxPrefix("not-a-uuid"), /invalid uuid/i);
  assert.throws(() => deriveSandboxPrefix(""), /invalid uuid/i);
  assert.throws(() => deriveSandboxPrefix(null), /invalid uuid/i);
});

test("validateVerdict accepts a well-formed verified envelope", () => {
  const v = {
    candidate_id: "a1b2c3d4-e5f6-7890-abcd-ef1234567801",
    pattern_signature: "sig",
    verdict: "verified",
    verdict_subtype: "live-probe-confirmed",
    probe_class: "read-only",
    evidence: { commands_run: [], skill_files_checked: [], summary: "ok" },
    sandbox: { prefix: "EVAL_34567801", entities_created: [], entities_cleaned: [], orphans: [] },
    duration_seconds: 5
  };
  const r = validateVerdict(v);
  assert.equal(r.ok, true, JSON.stringify(r.errors));
});

test("validateVerdict rejects bad verdict value", () => {
  const v = { candidate_id: "id", pattern_signature: "s", verdict: "approved",
    verdict_subtype: "x", probe_class: "read-only",
    evidence: { commands_run: [], skill_files_checked: [], summary: "" },
    sandbox: { prefix: "p", entities_created: [], entities_cleaned: [], orphans: [] },
    duration_seconds: 0 };
  const r = validateVerdict(v);
  assert.equal(r.ok, false);
  assert.ok(r.errors.some(e => e.includes("verdict")), "should error on verdict field");
});

test("validateVerdict rejects orphan reported with verified verdict + no ack flag", () => {
  // Verified with orphans is suspicious — caller (curator) requires explicit handling.
  // The validator flags this as a structural warning, not an error.
  const v = {
    candidate_id: "id", pattern_signature: "s", verdict: "verified", verdict_subtype: "live-probe-confirmed",
    probe_class: "sandbox-write",
    evidence: { commands_run: [], skill_files_checked: [], summary: "" },
    sandbox: { prefix: "EVAL_x", entities_created: ["EVAL_x_PROC"], entities_cleaned: [],
               orphans: ["EVAL_x_PROC"] },
    duration_seconds: 1
  };
  const r = validateVerdict(v);
  assert.equal(r.ok, true, "structural validation passes");
  assert.ok(r.warnings && r.warnings.some(w => w.includes("orphan")), "should warn about orphans");
});

test("applyVerdicts produces three buckets", () => {
  const candidates = [
    { id: "id-v", classification: "partial", pattern_name: "V" },
    { id: "id-d", classification: "partial", pattern_name: "D" },
    { id: "id-i", classification: "partial", pattern_name: "I" },
    { id: "id-x", classification: "partial", pattern_name: "X" }, // no verdict
  ];
  const verdicts = [
    { candidate_id: "id-v", verdict: "verified", evidence: { summary: "ok" } },
    { candidate_id: "id-d", verdict: "disproven", verdict_subtype: "live-probe-contradicted",
      evidence: { summary: "no, that's wrong" } },
    { candidate_id: "id-i", verdict: "inconclusive", verdict_subtype: "timeout",
      evidence: { summary: "took too long" } },
  ];
  const r = applyVerdicts(candidates, verdicts);
  assert.equal(r.admitted.length, 1);
  assert.equal(r.admitted[0].id, "id-v");
  assert.equal(r.autoRejected.length, 1);
  assert.equal(r.autoRejected[0].id, "id-d");
  assert.equal(r.stillDeferred.length, 2, "id-i (inconclusive) + id-x (no verdict) stay deferred");
  assert.deepEqual(r.stillDeferred.map(c => c.id).sort(), ["id-i", "id-x"]);
});

test("partitionForEval defers a mixed-classification group when partial source-count is insufficient", () => {
  // A pattern_signature appears twice — once as `missing`, once as `partial`,
  // with the same source_ref. The partial keeps the whole group behind the gate
  // until ≥2 distinct sources accumulate. Must be order-independent.
  const candidates1 = [
    { id: "a", source_ref: "S1", classification: "partial",  pattern_signature: "shared" },
    { id: "b", source_ref: "S1", classification: "missing",  pattern_signature: "shared" },
  ];
  const candidates2 = [
    { id: "b", source_ref: "S1", classification: "missing",  pattern_signature: "shared" },
    { id: "a", source_ref: "S1", classification: "partial",  pattern_signature: "shared" },
  ];
  const r1 = partitionForEval(candidates1);
  const r2 = partitionForEval(candidates2);
  assert.equal(r1.deferred.length, 2, "partial in group → all deferred (order 1)");
  assert.equal(r2.deferred.length, 2, "partial in group → all deferred (order 2)");
  assert.equal(r1.admitEligible.length, 0);
  assert.equal(r2.admitEligible.length, 0);
});

test("validateVerdict returns warnings:[] on non-object input so downstream destructuring is safe", () => {
  for (const bad of [null, undefined, "string", 42, true]) {
    const r = validateVerdict(bad);
    assert.equal(r.ok, false, `bad input ${JSON.stringify(bad)} should fail`);
    assert.ok(Array.isArray(r.warnings), `warnings must be an array for input ${JSON.stringify(bad)}`);
    assert.equal(r.warnings.length, 0);
  }
});
