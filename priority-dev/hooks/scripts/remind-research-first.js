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

const MANDATE = [
  'Before answering this Priority question, you MUST:',
  '  1. Identify which priority-sdk/references/*.md applies and read it.',
  '  2. Grep priority-sdk/examples/ for similar patterns.',
  '  3. Search live Priority code via run_inline_sqli on CODEREF, FORMCLMNS,',
  '     FORMTRIG for canonical examples actually running in the system.',
  'Do NOT answer from memory. Cite what you read.',
].join('\n');

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
