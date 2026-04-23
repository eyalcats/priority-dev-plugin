const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { computeNudge } = require("./session-start-consolidate");

function tmp(ext, contents = "") {
  const p = path.join(os.tmpdir(), `sst-${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  fs.writeFileSync(p, contents, "utf8");
  return p;
}

test("no nudge when queue empty and no unprocessed sessions", () => {
  const pending = tmp(".yaml", "candidates: []\n");
  const todo = tmp(".jsonl", "");
  const nudge = computeNudge({ pendingPath: pending, todoPath: todo, threshold: 5, insidePluginRepo: true });
  assert.equal(nudge, null);
});

test("nudge when queue size >= threshold", () => {
  const pending = tmp(".yaml", "candidates:\n  - id: a\n    source_mode: bootstrap\n    source_ref: X\n    classification: missing\n    pattern_name: P1\n    pattern_signature: p1\n    evidence:\n      metadata_table: FORMTRIGTEXT\n      snippet: x\n    proposed_edit:\n      target: references/triggers.md\n      diff: y\n    notes: n\n");
  const todo = tmp(".jsonl", "");
  const nudge = computeNudge({ pendingPath: pending, todoPath: todo, threshold: 1, insidePluginRepo: true });
  assert.ok(nudge);
  assert.match(nudge, /review-pending/);
});

test("nudge when unprocessed sessions exist", () => {
  const pending = tmp(".yaml", "candidates: []\n");
  const todo = tmp(".jsonl", JSON.stringify({ session_id: "s1", transcript_path: "/tmp/s1.jsonl", cwd: "/x", ended_at: "2026-04-23T00:00:00Z", processed: false }) + "\n");
  const nudge = computeNudge({ pendingPath: pending, todoPath: todo, threshold: 5, insidePluginRepo: true });
  assert.ok(nudge);
  assert.match(nudge, /learning-extractor/);
});

test("no nudge if we're outside the priority-dev repo and there are pending sessions to process there (cross-repo case)", () => {
  const pending = tmp(".yaml", "candidates: []\n");
  const todo = tmp(".jsonl", JSON.stringify({ session_id: "s1", transcript_path: "/tmp/s1.jsonl", cwd: "/x", ended_at: "2026-04-23T00:00:00Z", processed: false }) + "\n");
  const nudge = computeNudge({ pendingPath: pending, todoPath: todo, threshold: 5, insidePluginRepo: false });
  assert.equal(nudge, null);
});

test("isInsidePluginRepo returns false for sibling dir with matching prefix (priority-dev vs priority-dev-plugin)", () => {
  const { isInsidePluginRepo } = require("./session-start-consolidate");
  // Simulate: pluginRoot is C:\repos\priority-dev\plugin. repoRoot derived = C:\repos\priority-dev.
  // cwd inside the sibling priority-dev-plugin should NOT match.
  const pluginRoot = path.join(os.tmpdir(), "fake-repos", "priority-dev", "plugin");
  const inside = path.join(os.tmpdir(), "fake-repos", "priority-dev", "plugin", "skills");
  const sibling = path.join(os.tmpdir(), "fake-repos", "priority-dev-plugin", "some", "folder");
  assert.equal(isInsidePluginRepo(inside, pluginRoot), true);
  assert.equal(isInsidePluginRepo(sibling, pluginRoot), false);
});
