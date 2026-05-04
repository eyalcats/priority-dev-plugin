// Shared read/write helper for the priority-sdk freshness state file.
// Single JSON file, reset on SessionStart, stamped on reference reads,
// checked on tool calls. Path is overridable via env var for testing.
//
// Storage is per-machine, not per-project. The design considered a
// per-project path but the SessionStart hook resets state every session,
// so cross-project contamination only matters if two Priority dev sessions
// run concurrently against different project roots — rare, and the worst
// case is a reduced nudge, not a correctness issue.

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const DEFAULT_PATH = path.join(os.homedir(), '.claude', 'priority-sdk-freshness.json');

function statePath() {
  return process.env.PRIORITY_SDK_FRESHNESS_PATH || DEFAULT_PATH;
}

function emptyState() {
  return { session_id: null, references_read: {}, mandate_emitted: false };
}

function loadState() {
  try {
    const raw = fs.readFileSync(statePath(), 'utf8');
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') return emptyState();
    return {
      session_id: parsed.session_id ?? null,
      references_read: parsed.references_read ?? {},
      mandate_emitted: parsed.mandate_emitted === true,
    };
  } catch {
    return emptyState();
  }
}

function writeState(state) {
  const p = statePath();
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(state, null, 2));
}

function resetState(sessionId) {
  writeState({ session_id: sessionId ?? null, references_read: {}, mandate_emitted: false });
}

function stampReference(filename) {
  const s = loadState();
  s.references_read[filename] = new Date().toISOString();
  writeState(s);
}

function isFresh(filename, ttlMinutes) {
  const s = loadState();
  const iso = s.references_read[filename];
  if (!iso) return false;
  const age = Date.now() - Date.parse(iso);
  if (!Number.isFinite(age)) return false;
  return age <= ttlMinutes * 60 * 1000;
}

function getMandateEmitted() {
  return loadState().mandate_emitted === true;
}

function setMandateEmitted() {
  const s = loadState();
  s.mandate_emitted = true;
  writeState(s);
}

module.exports = {
  STATE_PATH: statePath,
  loadState,
  writeState,
  resetState,
  stampReference,
  isFresh,
  getMandateEmitted,
  setMandateEmitted,
};
