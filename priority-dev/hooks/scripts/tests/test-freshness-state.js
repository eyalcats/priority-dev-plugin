const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const {
  resetState,
  stampReference,
  isFresh,
  loadState,
  STATE_PATH,
  getMandateEmitted,
  setMandateEmitted,
} = require('../lib/freshness-state');

function withTempState(fn) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'freshness-'));
  const prev = process.env.PRIORITY_SDK_FRESHNESS_PATH;
  process.env.PRIORITY_SDK_FRESHNESS_PATH = path.join(tmp, 'state.json');
  try { fn(); } finally {
    process.env.PRIORITY_SDK_FRESHNESS_PATH = prev;
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

test('resetState writes an empty state keyed by session id', () => withTempState(() => {
  resetState('sess-1');
  const s = loadState();
  assert.strictEqual(s.session_id, 'sess-1');
  assert.deepStrictEqual(s.references_read, {});
}));

test('stampReference records filename with ISO timestamp', () => withTempState(() => {
  resetState('sess-1');
  stampReference('websdk-cookbook.md');
  const s = loadState();
  assert.ok(s.references_read['websdk-cookbook.md']);
  assert.match(s.references_read['websdk-cookbook.md'], /^\d{4}-\d{2}-\d{2}T/);
}));

test('isFresh returns false for unread reference', () => withTempState(() => {
  resetState('sess-1');
  assert.strictEqual(isFresh('triggers.md', 30), false);
}));

test('isFresh returns true for reference stamped within TTL', () => withTempState(() => {
  resetState('sess-1');
  stampReference('triggers.md');
  assert.strictEqual(isFresh('triggers.md', 30), true);
}));

test('isFresh returns false for reference older than TTL', () => withTempState(() => {
  resetState('sess-1');
  const oldIso = new Date(Date.now() - 40 * 60 * 1000).toISOString();
  fs.writeFileSync(process.env.PRIORITY_SDK_FRESHNESS_PATH, JSON.stringify({
    session_id: 'sess-1',
    references_read: { 'triggers.md': oldIso },
  }));
  assert.strictEqual(isFresh('triggers.md', 30), false);
}));

test('loadState returns empty shape on missing file', () => withTempState(() => {
  const s = loadState();
  assert.strictEqual(s.session_id, null);
  assert.deepStrictEqual(s.references_read, {});
}));

test('loadState returns empty shape on malformed JSON', () => withTempState(() => {
  fs.writeFileSync(process.env.PRIORITY_SDK_FRESHNESS_PATH, 'not json');
  const s = loadState();
  assert.strictEqual(s.session_id, null);
  assert.deepStrictEqual(s.references_read, {});
  assert.strictEqual(s.mandate_emitted, false);
}));

test('getMandateEmitted returns false on fresh state', () => withTempState(() => {
  resetState('sess-1');
  assert.strictEqual(getMandateEmitted(), false);
}));

test('setMandateEmitted flips the flag and persists across loads', () => withTempState(() => {
  resetState('sess-1');
  setMandateEmitted();
  assert.strictEqual(getMandateEmitted(), true);
  // Persists across re-load
  const s = loadState();
  assert.strictEqual(s.mandate_emitted, true);
}));

test('resetState clears mandate_emitted', () => withTempState(() => {
  resetState('sess-1');
  setMandateEmitted();
  assert.strictEqual(getMandateEmitted(), true);
  resetState('sess-2');
  assert.strictEqual(getMandateEmitted(), false);
}));

test('setMandateEmitted preserves references_read', () => withTempState(() => {
  resetState('sess-1');
  stampReference('triggers.md');
  setMandateEmitted();
  const s = loadState();
  assert.ok(s.references_read['triggers.md']);
  assert.strictEqual(s.mandate_emitted, true);
}));
