// Case-insensitive whole-word match for Priority-flavored prompts.
// Tuned conservatively — false positive is cheap, false negative reintroduces the bug.

const KEYWORDS = [
  'trigger', 'procedure', 'form', 'subform', 'column', 'DBI', 'SQLI',
  'EFORM', 'FORMCLMN', 'FORMCLMNS', 'FORMTRIG', 'FORMEXEC', 'CODEREF',
  'WINDBI', 'WebSDK', 'compile', 'prepare', 'report', 'interface',
  'UPGRADES', 'GENERALLOAD', 'DBLOAD', 'Priority',
  'WSCLIENT', 'MAILMSG', 'CHECK-FIELD', 'POST-FIELD', 'CHOOSE-FIELD',
  'HTMLDOC', 'ERRMSG', 'WRNMSG', 'LINK', 'UNLINK', 'shell',
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
