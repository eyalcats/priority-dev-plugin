const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { recordSessionEnd, readUnprocessed, markProcessed } = require("./session-end-track");

function tmpTodoPath() {
  return path.join(os.tmpdir(), `todo-${Date.now()}-${Math.random().toString(36).slice(2)}.jsonl`);
}

test("recordSessionEnd appends one line per call", () => {
  const p = tmpTodoPath();
  recordSessionEnd(p, { session_id: "s1", transcript_path: "/tmp/s1.jsonl", cwd: "/repos/x" });
  recordSessionEnd(p, { session_id: "s2", transcript_path: "/tmp/s2.jsonl", cwd: "/repos/y" });
  const lines = fs.readFileSync(p, "utf8").trim().split("\n");
  assert.equal(lines.length, 2);
  assert.equal(JSON.parse(lines[0]).session_id, "s1");
  assert.equal(JSON.parse(lines[1]).session_id, "s2");
});

test("readUnprocessed returns entries not marked processed", () => {
  const p = tmpTodoPath();
  recordSessionEnd(p, { session_id: "s1", transcript_path: "/tmp/s1.jsonl", cwd: "/repos/x" });
  recordSessionEnd(p, { session_id: "s2", transcript_path: "/tmp/s2.jsonl", cwd: "/repos/y" });
  markProcessed(p, "s1");
  const unproc = readUnprocessed(p);
  assert.equal(unproc.length, 1);
  assert.equal(unproc[0].session_id, "s2");
});

test("recordSessionEnd returns gracefully on missing fields", () => {
  const p = tmpTodoPath();
  const result = recordSessionEnd(p, { session_id: "", transcript_path: "" });
  assert.equal(result.ok, false);
  assert.ok(result.reason.length > 0);
  assert.equal(fs.existsSync(p), false);
});
