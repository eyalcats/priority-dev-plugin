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
