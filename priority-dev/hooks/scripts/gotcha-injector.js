#!/usr/bin/env node
// PreToolUse hook (matcher: websdk_form_action|run_inline_sqli|write_to_editor)
// — inspect the current tool input against the gotcha catalog. Inject a
// 1-line hint when a known dead-end pattern is detected; stay silent
// otherwise. Never blocks.

const { findGotcha } = require('./lib/gotcha-catalog');

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

  const match = findGotcha(payload.tool_name, payload.tool_input);
  if (!match) { process.exit(0); }

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: `Heads up: ${match.hint}`,
    },
  }));
  process.exit(0);
})();
