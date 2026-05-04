const test = require('node:test');
const assert = require('node:assert/strict');
const { findGotcha, stripSqlComments, strcatExceedsLimit, CATALOG } = require('./gotcha-catalog');

test('subform-as-table-proc fires on SELECT FROM PROG', () => {
  const r = findGotcha('run_inline_sqli', { sql: 'SELECT POS FROM PROG WHERE EPROG=1 FORMAT;' });
  assert.equal(r?.id, 'subform-as-table-proc');
});

test('subform-as-table-proc does NOT fire on PROCSTEPS or PROCQUERYTEXT', () => {
  assert.equal(findGotcha('run_inline_sqli', { sql: 'SELECT * FROM PROCSTEPS FORMAT;' }), null);
  assert.equal(findGotcha('run_inline_sqli', { sql: 'SELECT TEXT FROM PROCQUERYTEXT FORMAT;' }), null);
});

test('subform-as-table-form fires on SELECT FROM FCLMN', () => {
  const r = findGotcha('run_inline_sqli', { sql: 'SELECT * FROM FCLMN FORMAT;' });
  assert.equal(r?.id, 'subform-as-table-form');
});

test('subform-as-table-form does NOT fire on FORMCLMNS (real table)', () => {
  assert.equal(findGotcha('run_inline_sqli', { sql: 'SELECT * FROM FORMCLMNS FORMAT;' }), null);
});

test('eform-alias-in-raw-sql fires on HIDEBOOL in WHERE', () => {
  const r = findGotcha('run_inline_sqli', { sql: "SELECT * FROM FORMCLMNS WHERE HIDEBOOL='Y' FORMAT;" });
  assert.equal(r?.id, 'eform-alias-in-raw-sql');
});

test('eform-alias-in-raw-sql does NOT fire when only HIDE is used', () => {
  assert.equal(findGotcha('run_inline_sqli', { sql: "SELECT * FROM FORMCLMNS WHERE HIDE='Y' FORMAT;" }), null);
});

test('select-no-format fires on SELECT without trailing FORMAT', () => {
  const r = findGotcha('run_inline_sqli', { sql: 'SELECT * FROM EXEC' });
  assert.equal(r?.id, 'select-no-format');
});

test('select-no-format does NOT fire when FORMAT; is present', () => {
  assert.equal(findGotcha('run_inline_sqli', { sql: 'SELECT * FROM EXEC FORMAT;' }), null);
});

test('select-no-format does NOT fire on UPDATE statements', () => {
  assert.equal(findGotcha('run_inline_sqli', { sql: 'UPDATE T SET X=1' }), null);
});

test('select-no-format does NOT fire when mode is dbi', () => {
  assert.equal(findGotcha('run_inline_sqli', { mode: 'dbi', sql: 'CREATE TABLE T (X INT);' }), null);
});

test('strcat-too-long flags STRCAT body > 127 chars', () => {
  const long = "'" + 'a'.repeat(150) + "'";
  const r = findGotcha('write_to_editor', { content: `:$.X = STRCAT(${long});` });
  assert.equal(r?.id, 'strcat-too-long');
});

test('strcat-too-long does NOT fire on short STRCAT', () => {
  assert.equal(findGotcha('write_to_editor', { content: ":$.X = STRCAT('a','b');" }), null);
});

test('idjoine-multi-digit fires when IDJOINE=12', () => {
  const r = findGotcha('websdk_form_action', {
    operations: [{ op: 'fieldUpdate', field: 'IDJOINE', value: '12' }],
  });
  assert.equal(r?.id, 'idjoine-multi-digit');
});

test('idjoine-multi-digit does NOT fire when IDJOINE=6', () => {
  assert.equal(findGotcha('websdk_form_action', {
    operations: [{ op: 'fieldUpdate', field: 'IDJOINE', value: '6' }],
  }), null);
});

test('parentpk-in-expr fires on EXPR :$$.PARENTPK', () => {
  const r = findGotcha('websdk_form_action', {
    operations: [{ op: 'fieldUpdate', field: 'EXPR', value: ':$$.PARENTPK' }],
  });
  assert.equal(r?.id, 'parentpk-in-expr');
});

test('parentpk-in-expr does NOT fire on a normal expression', () => {
  assert.equal(findGotcha('websdk_form_action', {
    operations: [{ op: 'fieldUpdate', field: 'EXPR', value: ':$.OTHER' }],
  }), null);
});

test('subform-newrow-no-chain fires on bare newRow without startSubForm', () => {
  const r = findGotcha('websdk_form_action', {
    operations: [{ op: 'newRow' }],
  });
  assert.equal(r?.id, 'subform-newrow-no-chain');
});

test('subform-newrow-no-chain does NOT fire when newRow follows startSubForm', () => {
  assert.equal(findGotcha('websdk_form_action', {
    operations: [
      { op: 'filter', field: 'ENAME', value: 'X' },
      { op: 'getRows' },
      { op: 'setActiveRow', row: 1 },
      { op: 'startSubForm', name: 'FCLMN' },
      { op: 'newRow' },
    ],
  }), null);
});

test('compile-status-can-lie fires on compound compile op', () => {
  const r = findGotcha('websdk_form_action', { operations: [{ op: 'compile', entity: 'X' }] });
  assert.equal(r?.id, 'compile-status-can-lie');
});

test('findGotcha returns null on unrelated tools', () => {
  assert.equal(findGotcha('Read', { file_path: '/x' }), null);
  assert.equal(findGotcha('Bash', { command: 'ls' }), null);
});

test('stripSqlComments removes block and line comments', () => {
  assert.equal(stripSqlComments('SELECT /* x */ a -- y\nFROM T').replace(/\s+/g, ' ').trim(), 'SELECT a FROM T');
});

test('strcatExceedsLimit handles nested parens', () => {
  assert.equal(strcatExceedsLimit("STRCAT('a', STRCAT('b','c'))", 127), false);
});

test('CATALOG entries each have id, applies, hint', () => {
  for (const e of CATALOG) {
    assert.ok(typeof e.id === 'string' && e.id.length > 0);
    assert.ok(typeof e.applies === 'function');
    assert.ok(typeof e.hint === 'string' && e.hint.length > 0 && e.hint.length <= 200);
  }
});
