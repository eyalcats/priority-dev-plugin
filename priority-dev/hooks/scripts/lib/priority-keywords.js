// Case-insensitive whole-word match for Priority-flavored prompts.
//
// Tightened in v1.8.10: dropped over-broad single English words that fired in
// every non-Priority frontend / general-coding conversation (trigger, procedure,
// form, column, compile, prepare, report, interface, LINK, UNLINK, shell).
// Kept all Priority-specific identifiers (system table names, SQLI dialect,
// WINDBI tool, hyphenated trigger types, etc.) plus the literal word "Priority"
// so users can opt in explicitly when their prompt is about Priority work but
// doesn't happen to mention any of the specific identifiers.
//
// Trade-off: false negatives are now possible on prompts like "fix this trigger"
// without other Priority context. Mitigation: the user can include "Priority"
// or the specific identifier (SQLI, WINDBI, FORMTRIG, etc.) — and the
// priority-sdk skill + MCP server still ground the agent independently when
// invoked.

const KEYWORDS = [
  'subform', 'DBI', 'SQLI',
  'EFORM', 'FORMCLMN', 'FORMCLMNS', 'FORMTRIG', 'FORMEXEC', 'CODEREF',
  'WINDBI', 'WebSDK', 'WSCLIENT', 'MAILMSG', 'HTMLDOC',
  'UPGRADES', 'GENERALLOAD', 'DBLOAD',
  'CHECK-FIELD', 'POST-FIELD', 'CHOOSE-FIELD',
  'ERRMSG', 'WRNMSG',
  'Priority',
];

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// \b doesn't treat hyphens as word boundaries the way we want for
// "CHECK-FIELD", so build explicit lookaround boundaries that allow
// letters, digits, underscores, and hyphens as "word" chars.
const WORD_CHAR = '[A-Za-z0-9_-]';
const pattern = new RegExp(
  `(?:^|(?<!${WORD_CHAR}))(?:${KEYWORDS.map(escapeRegex).join('|')})(?!${WORD_CHAR})`,
  'i'
);

function matchesPriorityPrompt(prompt) {
  if (typeof prompt !== 'string' || prompt.length === 0) return false;
  return pattern.test(prompt);
}

module.exports = { matchesPriorityPrompt, KEYWORDS };
