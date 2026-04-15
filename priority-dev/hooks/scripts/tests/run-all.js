#!/usr/bin/env node
// Run every test-*.js file in this directory and exit non-zero on any failure.
// Workaround for `node --test <dir>` failing on Windows paths containing spaces.

const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const files = fs.readdirSync(__dirname)
  .filter((f) => f.startsWith('test-') && f.endsWith('.js'))
  .map((f) => path.join(__dirname, f));

if (files.length === 0) {
  console.error('No test-*.js files found in', __dirname);
  process.exit(1);
}

const result = spawnSync(process.execPath, ['--test', ...files], {
  stdio: 'inherit',
});

process.exit(result.status ?? 1);
