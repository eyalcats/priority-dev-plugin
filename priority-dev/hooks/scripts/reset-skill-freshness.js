#!/usr/bin/env node
// SessionStart hook — reset priority-sdk freshness state so the first
// Priority tool call in this session always nudges.

const { resetState } = require('./lib/freshness-state');

(async function main() {
  let payload = {};
  try {
    const stdin = await new Promise((resolve) => {
      let buf = '';
      process.stdin.on('data', (c) => (buf += c));
      process.stdin.on('end', () => resolve(buf));
    });
    if (stdin.trim()) payload = JSON.parse(stdin);
  } catch {
    // Any parse error → reset with null session id; never block session startup.
  }

  try {
    resetState(payload.session_id || null);
  } catch {
    // State write failure is non-fatal.
  }

  process.exit(0);
})();
