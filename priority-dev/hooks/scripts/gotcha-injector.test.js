const test = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const SCRIPT = path.join(__dirname, 'gotcha-injector.js');

function run(payload) {
  return spawnSync(process.execPath, [SCRIPT], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
  });
}

test('emits hint for matching tool input', () => {
  const r = run({ tool_name: 'run_inline_sqli', tool_input: { sql: 'SELECT * FROM PROG' } });
  assert.equal(r.status, 0);
  const obj = JSON.parse(r.stdout);
  assert.equal(obj.hookSpecificOutput.hookEventName, 'PreToolUse');
  assert.match(obj.hookSpecificOutput.additionalContext, /PROG\/PROGTEXT are EPROG subforms/);
});

test('emits nothing for non-matching tool input', () => {
  const r = run({ tool_name: 'run_inline_sqli', tool_input: { sql: 'SELECT * FROM EXEC FORMAT;' } });
  assert.equal(r.status, 0);
  assert.equal(r.stdout.trim(), '');
});

test('emits nothing for unrelated tool', () => {
  const r = run({ tool_name: 'Read', tool_input: { file_path: '/x' } });
  assert.equal(r.status, 0);
  assert.equal(r.stdout.trim(), '');
});

test('exits 0 even on malformed JSON input', () => {
  const r = spawnSync(process.execPath, [SCRIPT], { input: 'not json', encoding: 'utf8' });
  assert.equal(r.status, 0);
  assert.equal(r.stdout.trim(), '');
});
