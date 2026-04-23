#!/usr/bin/env node
// SessionStart hook: checks if there's work waiting and emits a nudge via stdout.
// Claude Code picks up hook stdout as additional context for the session.
//
// Two conditions trigger a nudge:
//   1. Pending queue has >= threshold entries (default 5).
//   2. There are unprocessed session transcripts in the session-todo file.
// Nudges only emit when we're inside the priority-dev repo — otherwise the
// user can't act on them without switching repos.

const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT || path.join(__dirname, "..", "..");
const PENDING_PATH = path.join(PLUGIN_ROOT, "skills", "priority-sdk", "_pending.yaml");
const TODO_PATH = path.join(os.homedir(), ".claude", "priority-dev-session-todo.jsonl");
const THRESHOLD = 5;

function countCandidates(pendingPath) {
  if (!fs.existsSync(pendingPath)) return 0;
  const text = fs.readFileSync(pendingPath, "utf8");
  if (text.match(/^candidates:\s*\[\s*\]\s*$/m)) return 0;
  const matches = text.match(/^\s{2}-\s+id:/gm);
  return matches ? matches.length : 0;
}

function countUnprocessed(todoPath) {
  if (!fs.existsSync(todoPath)) return 0;
  const text = fs.readFileSync(todoPath, "utf8");
  return text.split("\n").filter(Boolean).map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(e => e && !e.processed).length;
}

function isInsidePluginRepo(cwd, pluginRoot) {
  // The priority-dev repo contains the plugin at plugin/. Check if cwd is at or under
  // the repo root (two levels up from pluginRoot) using path.relative so sibling directories
  // with a matching prefix (e.g. priority-dev-plugin) don't false-match.
  const repoRoot = path.resolve(pluginRoot, "..");
  const rel = path.relative(repoRoot, path.resolve(cwd));
  // Inside if the relative path is empty or doesn't start with ".." and isn't absolute
  return rel === "" || (!rel.startsWith("..") && !path.isAbsolute(rel));
}

function computeNudge({ pendingPath, todoPath, threshold, insidePluginRepo }) {
  if (!insidePluginRepo) return null;

  const pending = countCandidates(pendingPath);
  const unprocessed = countUnprocessed(todoPath);

  if (pending < threshold && unprocessed === 0) return null;

  const lines = ["Priority SDK skill — self-improvement queue status:"];
  if (pending >= threshold) {
    lines.push(`  - ${pending} pending candidates in _pending.yaml (>= ${threshold} threshold). Run /review-pending to consolidate + approve.`);
  } else if (pending > 0) {
    lines.push(`  - ${pending} pending candidates in _pending.yaml. /review-pending available.`);
  }
  if (unprocessed > 0) {
    lines.push(`  - ${unprocessed} unprocessed session transcript(s) waiting for lesson extraction. Dispatch the learning-extractor agent with the oldest transcript path (see ~/.claude/priority-dev-session-todo.jsonl).`);
  }
  return lines.join("\n");
}

if (require.main === module) {
  let raw = "";
  process.stdin.on("data", chunk => raw += chunk);
  process.stdin.on("end", () => {
    try {
      const payload = raw.trim() ? JSON.parse(raw) : {};
      const cwd = payload.cwd || process.cwd();
      const insidePluginRepo = isInsidePluginRepo(cwd, PLUGIN_ROOT);
      const nudge = computeNudge({
        pendingPath: PENDING_PATH,
        todoPath: TODO_PATH,
        threshold: THRESHOLD,
        insidePluginRepo,
      });
      if (nudge) process.stdout.write(nudge + "\n");
    } catch (err) {
      process.stderr.write(`session-start-consolidate: ${err.message}\n`);
    }
    process.exit(0);
  });
  setTimeout(() => { if (!raw) process.exit(0); }, 100);
}

module.exports = { computeNudge, countCandidates, countUnprocessed, isInsidePluginRepo };
