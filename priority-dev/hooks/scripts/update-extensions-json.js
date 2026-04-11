#!/usr/bin/env node
// Register (or re-register) the Priority Claude Bridge extension in VSCode's
// installed-extensions registry. This is a required step after extracting a
// VSIX directly into ~/.vscode/extensions/ — VSCode does NOT auto-discover
// new extensions on startup; it loads only what's listed in extensions.json.
//
// Usage:
//   node update-extensions-json.js <extensions-dir> <target-folder-name> <version>
//
// Example:
//   node update-extensions-json.js \
//     "C:\Users\me\.vscode\extensions" \
//     "priority-software.priority-claude-bridge-1.6.5" \
//     "1.6.5"
//
// Exit codes:
//   0 — success (entry added or updated)
//   1 — bad arguments
//   2 — file I/O or JSON parse error (non-fatal to the caller — VSCode may
//       still auto-discover or the user can fix it manually)

'use strict';

const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

const EXTENSION_ID = 'priority-software.priority-claude-bridge';

function die(code, msg) {
  process.stderr.write(msg + '\n');
  process.exit(code);
}

const [, , extDir, targetFolder, version] = process.argv;
if (!extDir || !targetFolder || !version) {
  die(1, 'Usage: node update-extensions-json.js <extensions-dir> <target-folder-name> <version>');
}

const extsFile = path.join(extDir, 'extensions.json');
const targetPath = path.join(extDir, targetFolder);

// Build the location object in the shape VSCode itself writes — tested
// against a real installed extension on Windows. On Linux/macOS the
// colon-encoding step is a no-op.
function buildLocation(absPath) {
  // On Windows, VSCode canonicalizes drive letters to lowercase (e.g.
  // 'c:\\Users\\...'). Normalize to match so the file looks identical to
  // one written by VSCode itself.
  let canonical = absPath;
  if (process.platform === 'win32' && /^[A-Z]:/.test(canonical)) {
    canonical = canonical[0].toLowerCase() + canonical.slice(1);
  }

  let external = pathToFileURL(canonical).href;
  // VSCode normalizes the drive-letter colon to %3A on Windows.
  // pathToFileURL leaves it as 'file:///c:/...' — rewrite to 'file:///c%3A/...'
  external = external.replace(/^file:\/\/\/([a-zA-Z]):/, 'file:///$1%3A');

  // `path` in VSCode's URI serialization is the pathname without the scheme.
  // On Windows it looks like '/c:/Users/...' (leading slash, lowercase drive
  // letter, colon kept). On Linux/macOS it's just the absolute path.
  const uriPath =
    process.platform === 'win32'
      ? '/' + canonical.replace(/\\/g, '/')
      : canonical;

  return {
    $mid: 1,
    fsPath: canonical,
    _sep: 1,
    external,
    path: uriPath,
    scheme: 'file',
  };
}

// Load existing extensions.json (or start fresh if missing / corrupt)
let entries = [];
if (fs.existsSync(extsFile)) {
  try {
    const raw = fs.readFileSync(extsFile, 'utf8');
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) {
      entries = parsed;
    }
  } catch (err) {
    // Fall through with empty array — we'll overwrite the broken file
    process.stderr.write(
      `warning: could not parse ${extsFile}: ${err.message} — rewriting\n`
    );
  }
}

// Drop any existing entry for this extension (handles upgrade case where the
// previous version's folder was already removed).
const beforeCount = entries.length;
entries = entries.filter(
  (e) => !(e && e.identifier && e.identifier.id === EXTENSION_ID)
);
const removed = beforeCount - entries.length;

// Append the fresh entry
entries.push({
  identifier: { id: EXTENSION_ID },
  version,
  location: buildLocation(targetPath),
  relativeLocation: targetFolder,
});

try {
  fs.writeFileSync(extsFile, JSON.stringify(entries));
} catch (err) {
  die(2, `error: could not write ${extsFile}: ${err.message}`);
}

process.stderr.write(
  `extensions.json: ${removed > 0 ? 'updated' : 'added'} ${EXTENSION_ID} -> ${version} (${targetFolder})\n`
);
process.exit(0);
