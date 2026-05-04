const test = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const HOOKS_DIR = path.resolve(__dirname, '..');

const TMP_DIRS = [];
process.on('exit', () => {
  for (const d of TMP_DIRS) {
    try { fs.rmSync(d, { recursive: true, force: true }); } catch {}
  }
});

function runHook(script, stdinJson) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'hook-e2e-'));
  TMP_DIRS.push(tmp);
  const statePath = path.join(tmp, 'state.json');
  const result = spawnSync(process.execPath, [path.join(HOOKS_DIR, script)], {
    input: JSON.stringify(stdinJson),
    encoding: 'utf8',
    env: { ...process.env, PRIORITY_SDK_FRESHNESS_PATH: statePath },
  });
  return { ...result, statePath };
}

test('reset-skill-freshness writes empty state with session_id', () => {
  const { status, statePath } = runHook('reset-skill-freshness.js', {
    session_id: 'e2e-sess-1',
  });
  assert.strictEqual(status, 0);
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
  assert.strictEqual(state.session_id, 'e2e-sess-1');
  assert.deepStrictEqual(state.references_read, {});
});

test('reset-skill-freshness tolerates missing session_id', () => {
  const { status, statePath } = runHook('reset-skill-freshness.js', {});
  assert.strictEqual(status, 0);
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
  assert.strictEqual(state.session_id, null);
});

test('track-reference-reads stamps priority-sdk reference reads', () => {
  const { status, statePath } = runHook('track-reference-reads.js', {
    tool_name: 'Read',
    tool_input: { file_path: '/path/to/priority-sdk/references/websdk-cookbook.md' },
    tool_response: {},
  });
  assert.strictEqual(status, 0);
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
  assert.ok(state.references_read['websdk-cookbook.md']);
});

test('track-reference-reads stamps SKILL.md reads', () => {
  const { status, statePath } = runHook('track-reference-reads.js', {
    tool_name: 'Read',
    tool_input: { file_path: 'C:\\Users\\x\\.claude\\skills\\priority-sdk\\SKILL.md' },
  });
  assert.strictEqual(status, 0);
  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
  assert.ok(state.references_read['SKILL.md']);
});

test('track-reference-reads ignores non-priority-sdk reads', () => {
  const { status, statePath } = runHook('track-reference-reads.js', {
    tool_name: 'Read',
    tool_input: { file_path: '/some/other/file.md' },
  });
  assert.strictEqual(status, 0);
  assert.strictEqual(fs.existsSync(statePath), false);
});

test('track-reference-reads ignores non-Read tools', () => {
  const { status, statePath } = runHook('track-reference-reads.js', {
    tool_name: 'Edit',
    tool_input: { file_path: '/any/priority-sdk/references/forms.md' },
  });
  assert.strictEqual(status, 0);
  assert.strictEqual(fs.existsSync(statePath), false);
});

test('remind-research-first injects mandate for Priority prompt', () => {
  const { status, stdout } = runHook('remind-research-first.js', {
    prompt: 'how do I add a CHECK-FIELD trigger?',
  });
  assert.strictEqual(status, 0);
  const out = JSON.parse(stdout);
  assert.strictEqual(out.hookSpecificOutput.hookEventName, 'UserPromptSubmit');
  assert.match(out.hookSpecificOutput.additionalContext, /you MUST/);
  assert.match(out.hookSpecificOutput.additionalContext, /priority-sdk/);
  assert.match(out.hookSpecificOutput.additionalContext, /CODEREF|FORMCLMNS|FORMTRIG/);
});

test('remind-research-first stays silent for non-Priority prompt', () => {
  const { status, stdout } = runHook('remind-research-first.js', {
    prompt: 'what is 2+2?',
  });
  assert.strictEqual(status, 0);
  assert.strictEqual(stdout.trim(), '');
});

test('remind-research-first tolerates missing prompt field', () => {
  const { status, stdout } = runHook('remind-research-first.js', {});
  assert.strictEqual(status, 0);
  assert.strictEqual(stdout.trim(), '');
});

test('remind-research-first emits once per session, then stays silent', () => {
  // Shared state file across two invocations to simulate same session.
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'hook-mandate-'));
  TMP_DIRS.push(tmp);
  const statePath = path.join(tmp, 'state.json');
  const env = { ...process.env, PRIORITY_SDK_FRESHNESS_PATH: statePath };

  // SessionStart resets the flag.
  spawnSync(process.execPath, [path.join(HOOKS_DIR, 'reset-skill-freshness.js')], {
    input: JSON.stringify({ session_id: 'mandate-sess' }), encoding: 'utf8', env,
  });

  // First Priority prompt → MANDATE injected.
  const first = spawnSync(process.execPath, [path.join(HOOKS_DIR, 'remind-research-first.js')], {
    input: JSON.stringify({ prompt: 'how do I add a CHECK-FIELD trigger?' }),
    encoding: 'utf8', env,
  });
  assert.strictEqual(first.status, 0);
  const firstOut = JSON.parse(first.stdout);
  assert.match(firstOut.hookSpecificOutput.additionalContext, /you MUST/);

  // Verify the flag was persisted.
  const s = JSON.parse(fs.readFileSync(statePath, 'utf8'));
  assert.strictEqual(s.mandate_emitted, true);

  // Second Priority prompt in the same session → silent.
  const second = spawnSync(process.execPath, [path.join(HOOKS_DIR, 'remind-research-first.js')], {
    input: JSON.stringify({ prompt: 'now look at FORMTRIG for the same form' }),
    encoding: 'utf8', env,
  });
  assert.strictEqual(second.status, 0);
  assert.strictEqual(second.stdout.trim(), '');

  // SessionStart for a new session resets the flag → MANDATE re-injects.
  spawnSync(process.execPath, [path.join(HOOKS_DIR, 'reset-skill-freshness.js')], {
    input: JSON.stringify({ session_id: 'mandate-sess-2' }), encoding: 'utf8', env,
  });
  const third = spawnSync(process.execPath, [path.join(HOOKS_DIR, 'remind-research-first.js')], {
    input: JSON.stringify({ prompt: 'check FORMCLMN for COL X' }),
    encoding: 'utf8', env,
  });
  assert.strictEqual(third.status, 0);
  const thirdOut = JSON.parse(third.stdout);
  assert.match(thirdOut.hookSpecificOutput.additionalContext, /you MUST/);
});

test('nudge-priority-sdk nudges when websdk-cookbook.md not read', () => {
  const { status, stdout } = runHook('nudge-priority-sdk.js', {
    tool_name: 'websdk_form_action',
    tool_input: { operations: [] },
  });
  assert.strictEqual(status, 0);
  const out = JSON.parse(stdout);
  assert.strictEqual(out.hookSpecificOutput.hookEventName, 'PreToolUse');
  assert.match(out.hookSpecificOutput.additionalContext, /websdk-cookbook\.md/);
  assert.match(out.hookSpecificOutput.additionalContext, /not read/);
});

test('nudge-priority-sdk silent when required reference is fresh', () => {
  // Pre-stamp the reference by running track-reference-reads first.
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'hook-fresh-'));
  TMP_DIRS.push(tmp);
  const statePath = path.join(tmp, 'state.json');
  const env = { ...process.env, PRIORITY_SDK_FRESHNESS_PATH: statePath };

  spawnSync(process.execPath, [path.join(HOOKS_DIR, 'reset-skill-freshness.js')], {
    input: JSON.stringify({ session_id: 'fresh-sess' }), encoding: 'utf8', env,
  });
  spawnSync(process.execPath, [path.join(HOOKS_DIR, 'track-reference-reads.js')], {
    input: JSON.stringify({
      tool_name: 'Read',
      tool_input: { file_path: '/x/priority-sdk/references/websdk-cookbook.md' },
    }),
    encoding: 'utf8', env,
  });

  const result = spawnSync(process.execPath, [path.join(HOOKS_DIR, 'nudge-priority-sdk.js')], {
    input: JSON.stringify({ tool_name: 'websdk_form_action', tool_input: {} }),
    encoding: 'utf8', env,
  });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout.trim(), '');
});

test('nudge-priority-sdk picks triggers.md for trigger-shaped write_to_editor', () => {
  const { status, stdout } = runHook('nudge-priority-sdk.js', {
    tool_name: 'write_to_editor',
    tool_input: {
      entityType: 'FORM',
      content: 'SELECT :RETVAL = 1 FROM DUMMY; GOTO 99;',
    },
  });
  assert.strictEqual(status, 0);
  const out = JSON.parse(stdout);
  assert.match(out.hookSpecificOutput.additionalContext, /triggers\.md/);
});

test('nudge-priority-sdk picks tables-and-dbi.md for DBI mode', () => {
  const { status, stdout } = runHook('nudge-priority-sdk.js', {
    tool_name: 'run_inline_sqli',
    tool_input: { mode: 'dbi', sql: 'CREATE TABLE X' },
  });
  assert.strictEqual(status, 0);
  const out = JSON.parse(stdout);
  assert.match(out.hookSpecificOutput.additionalContext, /tables-and-dbi\.md/);
});

test('nudge-priority-sdk silent for unrelated tool', () => {
  const { status, stdout } = runHook('nudge-priority-sdk.js', {
    tool_name: 'Read',
    tool_input: { file_path: '/x/y.md' },
  });
  assert.strictEqual(status, 0);
  assert.strictEqual(stdout.trim(), '');
});
