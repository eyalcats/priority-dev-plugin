// Catalog of known dead-end patterns in Priority tool inputs. Each entry's
// `applies(toolName, toolInput)` returns true when the input matches a
// known dead-end; the hook injects the matching `hint` as PreToolUse
// additionalContext (1-2 lines, ≤ ~140 chars).
//
// Intra-call detection only — entries see the current tool_input,
// not prior session calls.

function sqlOf(toolInput) {
  return String(toolInput?.sql ?? '');
}

function contentOf(toolInput) {
  return String(toolInput?.content ?? '');
}

function operationsOf(toolInput) {
  return Array.isArray(toolInput?.operations) ? toolInput.operations : [];
}

function stripSqlComments(sql) {
  // Strip /* ... */ block comments and -- ... line comments.
  return sql
    .replace(/\/\*[\s\S]*?\*\//g, ' ')
    .replace(/--[^\n]*/g, ' ');
}

const SUBFORM_PROC = /\bFROM\s+(PROG|PROGTEXT)\b/i;
const SUBFORM_FORM = /\bFROM\s+(FCLMN|FLINK|FORMEXEC|FTRIG|FCLMNA|FORMPREPERRS)\b/i;
const EFORM_ALIAS = /\b(HIDEBOOL|IDCOLUMNE|IDJOINE)\b/;
const SELECT_START = /^\s*SELECT\b/i;
const FORMAT_END = /\bFORMAT\s*;?\s*$/i;
const PARENTPK = /:\$\$\.PARENTPK\b/;

const SUBFORM_NAMES = new Set([
  'FCLMN', 'FCLMNA', 'FLINK', 'FORMEXEC', 'FTRIG',
  'FORMTRIG', 'FORMCLTRIG', 'FORMCLTRIGTEXT',
  'PROG', 'PROGTEXT', 'PROGPARAM', 'PROGFORMATS',
  'REPCLMNS', 'REPCLMNSA',
]);

function strcatExceedsLimit(content, limit = 127) {
  // Naively scan for STRCAT(...) calls; for each, compute total argument
  // length (paren-balanced body length). If any single STRCAT body exceeds
  // `limit` chars, flag it.
  const re = /STRCAT\s*\(/gi;
  let m;
  while ((m = re.exec(content)) !== null) {
    let depth = 1;
    let i = m.index + m[0].length;
    const start = i;
    while (i < content.length && depth > 0) {
      const c = content[i];
      if (c === '(') depth++;
      else if (c === ')') depth--;
      i++;
    }
    if (depth === 0) {
      const body = content.slice(start, i - 1);
      if (body.length > limit) return true;
    }
  }
  return false;
}

const CATALOG = [
  {
    id: 'subform-as-table-proc',
    applies: (toolName, toolInput) => {
      if (toolName !== 'run_inline_sqli') return false;
      return SUBFORM_PROC.test(stripSqlComments(sqlOf(toolInput)));
    },
    hint: 'PROG/PROGTEXT are EPROG subforms, not tables. Use PROCQUERYTEXT or WebSDK startSubForm.',
  },
  {
    id: 'subform-as-table-form',
    applies: (toolName, toolInput) => {
      if (toolName !== 'run_inline_sqli') return false;
      return SUBFORM_FORM.test(stripSqlComments(sqlOf(toolInput)));
    },
    hint: 'These are EFORM subforms, not tables. Real tables: FORMCLMNS / FORMLINKS / FORMEXEC / FORMTRIG / FORMCLMNSA.',
  },
  {
    id: 'eform-alias-in-raw-sql',
    applies: (toolName, toolInput) => {
      if (toolName !== 'run_inline_sqli') return false;
      return EFORM_ALIAS.test(stripSqlComments(sqlOf(toolInput)));
    },
    hint: 'EFORM-view aliases. Real columns in FORMCLMNS: HIDE / IDCOLUMN / IDJOIN.',
  },
  {
    id: 'select-no-format',
    applies: (toolName, toolInput) => {
      if (toolName !== 'run_inline_sqli') return false;
      const mode = String(toolInput?.mode || 'sqli').toLowerCase();
      if (mode !== 'sqli') return false;
      const sql = stripSqlComments(sqlOf(toolInput));
      return SELECT_START.test(sql) && !FORMAT_END.test(sql);
    },
    hint: 'SQLI SELECT prints nothing without FORMAT; at the end.',
  },
  {
    id: 'strcat-too-long',
    applies: (toolName, toolInput) => {
      if (toolName !== 'write_to_editor') return false;
      return strcatExceedsLimit(contentOf(toolInput), 127);
    },
    hint: 'STRCAT truncates at 127 chars — use ASCII ADDTO for longer content.',
  },
  {
    id: 'idjoine-multi-digit',
    applies: (toolName, toolInput) => {
      if (toolName !== 'websdk_form_action') return false;
      for (const op of operationsOf(toolInput)) {
        if (op?.op !== 'fieldUpdate') continue;
        if (op.field !== 'IDJOINE' && op.field !== 'IDCOLUMNE') continue;
        const n = parseInt(String(op.value), 10);
        if (Number.isFinite(n) && n >= 10) return true;
      }
      return false;
    },
    hint: 'IDJOINE/IDCOLUMNE accept single digits 0-9 only. Project rule: > 5 for custom forms.',
  },
  {
    id: 'parentpk-in-expr',
    applies: (toolName, toolInput) => {
      if (toolName !== 'websdk_form_action') return false;
      for (const op of operationsOf(toolInput)) {
        if (op?.op !== 'fieldUpdate') continue;
        if (op.field !== 'EXPR') continue;
        if (PARENTPK.test(String(op.value || ''))) return true;
      }
      return false;
    },
    hint: ":$$.PARENTPK breaks parent's compile. Use a plain hidden INT for the link column.",
  },
  {
    id: 'subform-newrow-no-chain',
    applies: (toolName, toolInput) => {
      if (toolName !== 'websdk_form_action') return false;
      const ops = operationsOf(toolInput);
      // Track whether we are currently inside a known subform context.
      // newRow before any startSubForm in the same compound call lands on
      // the EFORM root (meta-form 9061) — flag it.
      let inSubform = false;
      for (const op of ops) {
        if (op?.op === 'startSubForm') {
          if (op.name && SUBFORM_NAMES.has(String(op.name).toUpperCase())) {
            inSubform = true;
          }
        } else if (op?.op === 'endSubForm') {
          inSubform = false;
        } else if (op?.op === 'newRow') {
          if (!inSubform) return true;
        }
      }
      return false;
    },
    hint: 'newRow on a subform must be preceded by filter→getRows→setActiveRow→startSubForm in the same compound call.',
  },
  {
    id: 'compile-status-can-lie',
    applies: (toolName, toolInput) => {
      if (toolName !== 'websdk_form_action') return false;
      for (const op of operationsOf(toolInput)) {
        if (op?.op === 'compile') return true;
      }
      return false;
    },
    hint: 'compile op status:ok can lie. After this, read FORMPREPERRS for authoritative signal.',
  },
];

function findGotcha(toolName, toolInput) {
  for (const entry of CATALOG) {
    try {
      if (entry.applies(toolName, toolInput)) {
        return { id: entry.id, hint: entry.hint };
      }
    } catch {
      // A misbehaving matcher must never break the hook — skip it.
    }
  }
  return null;
}

module.exports = {
  CATALOG,
  findGotcha,
  // Exported for tests:
  stripSqlComments,
  strcatExceedsLimit,
};
