#!/usr/bin/env node
// UserPromptSubmit hook — for Priority-flavored prompts, inject a mandate
// that Claude must consult the skill, grep examples, and mine live code
// BEFORE answering. Stays silent on non-Priority prompts.

const { matchesPriorityPrompt } = require('./lib/priority-keywords');

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

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: MANDATE,
    },
  }));
  process.exit(0);
})();
