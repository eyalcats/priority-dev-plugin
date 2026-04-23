#!/usr/bin/env node
// SessionEnd hook: records an entry in ~/.claude/priority-dev-session-todo.jsonl
// so the next SessionStart can nudge Claude to extract lessons from this session.
//
// Reads the hook event payload from stdin (Claude Code hooks API). Expected payload
// shape includes session_id, transcript_path, cwd. We record all three so the
// SessionStart hook can decide whether we're inside the priority-dev repo.
//
// Never fails the session: on any error, log to stderr and exit 0 so the session ends cleanly.

const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const TODO_PATH = path.join(os.homedir(), ".claude", "priority-dev-session-todo.jsonl");

function recordSessionEnd(todoPath, payload) {
  if (!payload || !payload.session_id || !payload.transcript_path) {
    return { ok: false, reason: "missing session_id or transcript_path" };
  }
  const entry = {
    session_id: payload.session_id,
    transcript_path: payload.transcript_path,
    cwd: payload.cwd || "",
    ended_at: new Date().toISOString(),
    processed: false,
  };
  fs.mkdirSync(path.dirname(todoPath), { recursive: true });
  fs.appendFileSync(todoPath, JSON.stringify(entry) + "\n", "utf8");
  return { ok: true };
}

function readUnprocessed(todoPath) {
  if (!fs.existsSync(todoPath)) return [];
  const text = fs.readFileSync(todoPath, "utf8");
  return text.split("\n").filter(Boolean).map(l => JSON.parse(l)).filter(e => !e.processed);
}

function markProcessed(todoPath, sessionId) {
  if (!fs.existsSync(todoPath)) return;
  const text = fs.readFileSync(todoPath, "utf8");
  const lines = text.split("\n").filter(Boolean).map(l => JSON.parse(l));
  for (const line of lines) {
    if (line.session_id === sessionId) line.processed = true;
  }
  fs.writeFileSync(todoPath, lines.map(l => JSON.stringify(l)).join("\n") + "\n", "utf8");
}

// Entry point: only run as script if invoked directly (not imported by tests)
if (require.main === module) {
  let raw = "";
  process.stdin.on("data", chunk => raw += chunk);
  process.stdin.on("end", () => {
    try {
      const payload = raw.trim() ? JSON.parse(raw) : {};
      recordSessionEnd(TODO_PATH, payload);
    } catch (err) {
      process.stderr.write(`session-end-track: ${err.message}\n`);
    }
    process.exit(0);
  });
  // Small grace for empty stdin
  setTimeout(() => { if (!raw) process.exit(0); }, 100);
}

module.exports = { recordSessionEnd, readUnprocessed, markProcessed };
