const fs = require("node:fs");
const crypto = require("node:crypto");

// Minimal YAML serializer/deserializer for our specific schema.
// Using a hand-rolled implementation so the module has zero npm dependencies
// (matches the bridge's constraint of running without install steps).
// The schema is flat enough that this is safe; if the queue grows
// structurally, swap to js-yaml and declare it in the bridge's package.json.

function parseYaml(text) {
  // Expect: "candidates:\n  - id: ...\n    field: value\n    ..."
  // or "candidates: []"
  const lines = text.split(/\r?\n/);
  const candidates = [];
  let current = null;
  let inCandidates = false;
  let multilineKey = null;
  let multilineLines = [];
  let multilineIndent = 0;

  const flushMultiline = () => {
    if (multilineKey && current) {
      const block = multilineLines.map(l => l.slice(multilineIndent)).join("\n").replace(/\n+$/, "");
      setNested(current, multilineKey, block);
      multilineKey = null;
      multilineLines = [];
    }
  };

  const setNested = (obj, dottedKey, value) => {
    const parts = dottedKey.split(".");
    let o = obj;
    for (let i = 0; i < parts.length - 1; i++) {
      o[parts[i]] = o[parts[i]] || {};
      o = o[parts[i]];
    }
    o[parts[parts.length - 1]] = value;
  };

  for (const raw of lines) {
    if (raw.match(/^\s*#/) || raw.trim() === "") continue;

    if (raw.match(/^candidates:\s*\[\s*\]\s*$/)) {
      return [];
    }
    if (raw.match(/^candidates:\s*$/)) {
      inCandidates = true;
      continue;
    }
    if (!inCandidates) continue;

    // If we're in a multiline block, consume lines at >= multilineIndent as content
    // before checking field-regex matches (fix: multiline priority over field dispatch)
    if (multilineKey) {
      const leadSpaces = raw.match(/^ */)[0].length;
      if (leadSpaces >= multilineIndent) {
        multilineLines.push(raw);
        continue;
      }
      // Indent dropped — end multiline and fall through to field matching
      flushMultiline();
    }

    const listItemMatch = raw.match(/^\s{2}-\s+(\w+):\s*(.*)$/);
    if (listItemMatch) {
      if (current) candidates.push(current);
      current = {};
      const [, k, v] = listItemMatch;
      if (v === "|" || v === ">") { multilineKey = k; multilineLines = []; multilineIndent = 6; }
      else current[k] = parseScalar(v);
      continue;
    }

    const fieldMatch = raw.match(/^\s{4}(\w+):\s*(.*)$/);
    if (fieldMatch && current) {
      const [, k, v] = fieldMatch;
      if (v === "|" || v === ">") { multilineKey = k; multilineLines = []; multilineIndent = 6; }
      else if (v === "") { current[k] = {}; multilineKey = null; }
      else current[k] = parseScalar(v);
      continue;
    }

    const nestedFieldMatch = raw.match(/^\s{6}(\w+):\s*(.*)$/);
    if (nestedFieldMatch && current) {
      const [, k, v] = nestedFieldMatch;
      // Find the most recent object-valued key at indent 4
      const parentKey = Object.keys(current).reverse().find(key => typeof current[key] === "object" && current[key] !== null);
      if (parentKey) {
        if (v === "|" || v === ">") { multilineKey = `${parentKey}.${k}`; multilineLines = []; multilineIndent = 8; }
        else current[parentKey][k] = parseScalar(v);
      }
      continue;
    }
  }
  flushMultiline();
  if (current) candidates.push(current);
  return candidates;
}

function parseScalar(v) {
  const trimmed = v.trim();
  // Fix: JSON-decode double-quoted strings to correctly handle escape sequences
  if (trimmed.startsWith('"')) {
    try { return JSON.parse(trimmed); } catch { return trimmed.slice(1, -1); }
  }
  // Single-quoted strings: strip quotes (uncommon in our writer output)
  if (trimmed.startsWith("'")) return trimmed.slice(1, -1);
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  if (trimmed === "null") return null;
  if (trimmed.match(/^-?\d+$/)) return Number(trimmed);
  return trimmed;
}

function stringifyYaml(candidates) {
  if (candidates.length === 0) return "candidates: []\n";
  const lines = ["candidates:"];
  for (const c of candidates) {
    const keys = Object.keys(c);
    keys.forEach((k, i) => {
      const prefix = i === 0 ? "  - " : "    ";
      const v = c[k];
      if (v && typeof v === "object") {
        lines.push(`${prefix}${k}:`);
        for (const [sk, sv] of Object.entries(v)) {
          const isMultiline = typeof sv === "string" && sv.includes("\n");
          if (isMultiline) {
            lines.push(`      ${sk}: |`);
            for (const ln of sv.split("\n")) lines.push(`        ${ln}`);
          } else {
            lines.push(`      ${sk}: ${formatScalar(sv)}`);
          }
        }
      } else {
        const isMultiline = typeof v === "string" && v.includes("\n");
        if (isMultiline) {
          lines.push(`${prefix}${k}: |`);
          for (const ln of v.split("\n")) lines.push(`      ${ln}`);
        } else {
          lines.push(`${prefix}${k}: ${formatScalar(v)}`);
        }
      }
    });
  }
  return lines.join("\n") + "\n";
}

function formatScalar(v) {
  if (v === null || v === undefined) return '""';
  if (typeof v !== "string") return String(v);
  // Fix: force-quote reserved tokens and digit-only strings so they round-trip as strings
  const reserved = /^(true|false|null|yes|no)$/i;
  const digits = /^-?\d+$/;
  const needsQuote = v.includes(":") || v.includes("#") || v.startsWith(" ") || v.startsWith("-") || reserved.test(v) || digits.test(v) || v === "";
  return needsQuote ? JSON.stringify(v) : v;
}

function readQueue(filePath) {
  // Fix: guard against missing file (first-run / user-local scenarios)
  if (!fs.existsSync(filePath)) return [];
  const text = fs.readFileSync(filePath, "utf8");
  return parseYaml(text);
}

function writeQueue(filePath, candidates) {
  const header = "# Staged candidate skill improvements awaiting consolidation + approval.\n# Appended by Scouts (Mode 1: /gap-scan) and the learning-extractor (Mode 2: SessionEnd loop).\n# Drained by the curator (gap-curator mode) on approval or rejection.\n# Schema defined in docs/superpowers/specs/2026-04-23-gap-scan-design.md.\n";
  fs.writeFileSync(filePath, header + stringifyYaml(candidates), "utf8");
}

// Fix: file-lock helper for concurrent-write safety (Scouts run in parallel)
function withLock(filePath, fn) {
  const lockPath = filePath + ".lock";
  const deadline = Date.now() + 2000;
  let fd = null;
  while (Date.now() < deadline) {
    try {
      fd = fs.openSync(lockPath, "wx");
      break;
    } catch (e) {
      if (e.code !== "EEXIST") throw e;
      const spinEnd = Date.now() + 10;
      while (Date.now() < spinEnd) {} // sync busy-wait
    }
  }
  if (fd === null) throw new Error(`Could not acquire lock on ${filePath} within 2s`);
  try {
    return fn();
  } finally {
    fs.closeSync(fd);
    try { fs.unlinkSync(lockPath); } catch {}
  }
}

function appendCandidate(filePath, entry) {
  return withLock(filePath, () => {
    const candidates = readQueue(filePath);
    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    candidates.push({ id, added_at: now, ...entry });
    writeQueue(filePath, candidates);
    return id;
  });
}

function removeCandidate(filePath, id) {
  return withLock(filePath, () => {
    const candidates = readQueue(filePath);
    const filtered = candidates.filter(c => c.id !== id);
    writeQueue(filePath, filtered);
    return candidates.length - filtered.length;
  });
}

function countByClassification(filePath) {
  const candidates = readQueue(filePath);
  const counts = { missing: 0, partial: 0, "new-category": 0 };
  for (const c of candidates) {
    if (counts[c.classification] !== undefined) counts[c.classification]++;
  }
  return counts;
}

function mergeUserLocal(projectPath, userLocalPath) {
  return withLock(projectPath, () => {
    return withLock(userLocalPath, () => {
      if (!fs.existsSync(userLocalPath)) return 0;
      const userEntries = readQueue(userLocalPath);
      if (userEntries.length === 0) return 0;
      const projectEntries = readQueue(projectPath);
      const merged = projectEntries.concat(userEntries);
      writeQueue(projectPath, merged);
      writeQueue(userLocalPath, []);
      return userEntries.length;
    });
  });
}

module.exports = { readQueue, writeQueue, appendCandidate, removeCandidate, countByClassification, mergeUserLocal };
