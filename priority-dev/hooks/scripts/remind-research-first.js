#!/usr/bin/env node
// UserPromptSubmit hook — for Priority-flavored prompts, inject a mandate
// that Claude must consult the skill, grep examples, and mine live code
// BEFORE answering. Stays silent on non-Priority prompts.
//
// Once-per-session: the MANDATE is identical every time, so we only emit
// it on the FIRST matching prompt of a session. Subsequent matching prompts
// exit silently. The flag is reset at SessionStart by reset-skill-freshness.js.

const { matchesPriorityPrompt } = require('./lib/priority-keywords');
const { getMandateEmitted, setMandateEmitted } = require('./lib/freshness-state');

const MANDATE =
  'Priority work — invoke /priority-sdk if not already invoked this session. ' +
  'The skill tells you which references and examples to consult for this task.';

(async function main() {
  let payload = {};
  try {
    const stdin = await new Promise((resolve) => {
      let buf = '';
      process.stdin.on('data', (c) => (buf += c));
      process.stdin.on('end', () => resolve(buf));
    });
    if (stdin.trim()) payload = JSON.parse(stdin);
  } catch { /* non-fatal */ }

  if (!matchesPriorityPrompt(payload.prompt)) {
    process.exit(0);
  }

  // Already emitted this session — stay silent. Re-injecting the same
  // MANDATE every Priority prompt just consumes context.
  try {
    if (getMandateEmitted()) {
      process.exit(0);
    }
  } catch { /* state read failure → fall through and emit */ }

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: MANDATE,
    },
  }));

  try { setMandateEmitted(); } catch { /* state write failure non-fatal */ }

  process.exit(0);
})();
