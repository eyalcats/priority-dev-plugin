#!/usr/bin/env node
// PreToolUse hook (matcher: websdk_form_action|run_inline_sqli|write_to_editor)
// — if the reference this tool needs isn't fresh in state, nudge Claude
// to read it first. Never blocks.

const { isFresh } = require('./lib/freshness-state');
const { requiredReferenceFor } = require('./lib/tool-reference-map');

// 60 min — long enough to work on the same form/procedure without nagging.
// The skill markdown files don't change while you work; the original 30-min
// TTL was a guard against DB state drift, but that concern is covered by the
// bridge directly, not by re-reading reference docs.
const TTL_MINUTES = 60;

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

  const ref = requiredReferenceFor(payload.tool_name, payload.tool_input);
  if (!ref) { process.exit(0); }

  if (isFresh(ref, TTL_MINUTES)) { process.exit(0); }

  const msg =
    `priority-sdk/references/${ref} not read (or stale >${TTL_MINUTES}min). ` +
    `Invoke /priority-sdk and read references/${ref} before this tool call. ` +
    `Do not answer from memory.`;

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: msg,
    },
  }));
  process.exit(0);
})();
