const test = require('node:test');
const assert = require('node:assert');
const { requiredReferenceFor } = require('../lib/tool-reference-map');

test('websdk_form_action → websdk-cookbook.md', () => {
  assert.strictEqual(
    requiredReferenceFor('websdk_form_action', { operations: [] }),
    'websdk-cookbook.md'
  );
});

test('run_inline_sqli mode=dbi → tables-and-dbi.md', () => {
  assert.strictEqual(
    requiredReferenceFor('run_inline_sqli', { mode: 'dbi', sql: 'CREATE TABLE X' }),
    'tables-and-dbi.md'
  );
});

test('run_inline_sqli mode=sqli → websdk-cookbook.md', () => {
  assert.strictEqual(
    requiredReferenceFor('run_inline_sqli', { mode: 'sqli', sql: 'SELECT 1' }),
    'websdk-cookbook.md'
  );
});

test('run_inline_sqli default mode → websdk-cookbook.md', () => {
  assert.strictEqual(
    requiredReferenceFor('run_inline_sqli', { sql: 'SELECT 1' }),
    'websdk-cookbook.md'
  );
});

test('write_to_editor with trigger-shaped content → triggers.md', () => {
  assert.strictEqual(
    requiredReferenceFor('write_to_editor', {
      entityType: 'FORM',
      content: 'SELECT :RETVAL = 1 FROM DUMMY; IF :RETVAL <= 0 GOTO 99 END;'
    }),
    'triggers.md'
  );
});

test('write_to_editor with procedure content → triggers.md', () => {
  assert.strictEqual(
    requiredReferenceFor('write_to_editor', {
      entityType: 'PROC',
      content: 'SELECT SQL.TMPFILE INTO :TMP FROM DUMMY;'
    }),
    'triggers.md'
  );
});

test('write_to_editor with non-trigger form content → forms.md', () => {
  assert.strictEqual(
    requiredReferenceFor('write_to_editor', {
      entityType: 'FORM',
      content: '/* form dump header only */'
    }),
    'forms.md'
  );
});

test('unknown tool returns null', () => {
  assert.strictEqual(requiredReferenceFor('SomeOtherTool', {}), null);
});
