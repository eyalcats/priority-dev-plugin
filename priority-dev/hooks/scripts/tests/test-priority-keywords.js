const test = require('node:test');
const assert = require('node:assert');
const { matchesPriorityPrompt } = require('../lib/priority-keywords');

test('matches "how do I add a CHECK-FIELD trigger?"', () => {
  assert.strictEqual(matchesPriorityPrompt('how do I add a CHECK-FIELD trigger?'), true);
});

test('matches "update the FORMCLMNS row"', () => {
  assert.strictEqual(matchesPriorityPrompt('update the FORMCLMNS row'), true);
});

test('matches case-insensitively: "work on SQLI procedure"', () => {
  assert.strictEqual(matchesPriorityPrompt('work on SQLI procedure'), true);
});

test('matches "compile the report"', () => {
  assert.strictEqual(matchesPriorityPrompt('compile the report'), true);
});

test('does NOT match plain "what is 2+2?"', () => {
  assert.strictEqual(matchesPriorityPrompt('what is 2+2?'), false);
});

test('does NOT match "list files in this directory"', () => {
  assert.strictEqual(matchesPriorityPrompt('list files in this directory'), false);
});

test('whole-word only: "transform" does not match "form"', () => {
  assert.strictEqual(matchesPriorityPrompt('transform the data'), false);
});

test('handles empty string', () => {
  assert.strictEqual(matchesPriorityPrompt(''), false);
});

test('handles null/undefined', () => {
  assert.strictEqual(matchesPriorityPrompt(null), false);
  assert.strictEqual(matchesPriorityPrompt(undefined), false);
});
