#!/usr/bin/env node
// PostToolUse hook (matcher: Read) — stamp reads of priority-sdk reference
// files into the freshness state so PreToolUse knows what's fresh.

const path = require('node:path');
const { stampReference } = require('./lib/freshness-state');

const SDK_MARKER = /[\\/]priority-sdk[\\/](references[\\/][^\\/]+\.md|SKILL\.md|examples[\\/][^\\/]+)$/i;

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

  if (payload.tool_name !== 'Read') { process.exit(0); }
  const filePath = payload.tool_input?.file_path;
  if (typeof filePath !== 'string') { process.exit(0); }

  if (!SDK_MARKER.test(filePath)) { process.exit(0); }

  try {
    stampReference(path.basename(filePath));
  } catch { /* non-fatal */ }

  process.exit(0);
})();
