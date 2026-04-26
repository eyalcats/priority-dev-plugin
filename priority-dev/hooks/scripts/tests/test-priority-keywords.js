const test = require('node:test');
const assert = require('node:assert');
const { matchesPriorityPrompt } = require('../lib/priority-keywords');

// Priority-specific identifiers — should match.

test('matches "how do I add a CHECK-FIELD trigger?"', () => {
  assert.strictEqual(matchesPriorityPrompt('how do I add a CHECK-FIELD trigger?'), true);
});

test('matches "update the FORMCLMNS row"', () => {
  assert.strictEqual(matchesPriorityPrompt('update the FORMCLMNS row'), true);
});

test('matches case-insensitively: "work on SQLI procedure"', () => {
  assert.strictEqual(matchesPriorityPrompt('work on SQLI procedure'), true);
});

test('matches "subform layout for ORDERS"', () => {
  assert.strictEqual(matchesPriorityPrompt('subform layout for ORDERS'), true);
});

test('matches the literal word "Priority" (explicit opt-in)', () => {
  assert.strictEqual(matchesPriorityPrompt('Priority work needs grounding'), true);
});

test('matches "POST-FIELD trigger on FORMTRIG"', () => {
  assert.strictEqual(matchesPriorityPrompt('POST-FIELD trigger on FORMTRIG'), true);
});

// v1.8.10 — these used to match (false positives in non-Priority work) and
// should NOT match anymore. They use English words that were over-broad.

test('does NOT match "fix this trigger in my Rails app"', () => {
  assert.strictEqual(matchesPriorityPrompt('fix this trigger in my Rails app'), false);
});

test('does NOT match "render the form component"', () => {
  assert.strictEqual(matchesPriorityPrompt('render the form component'), false);
});

test('does NOT match "compile the report"', () => {
  assert.strictEqual(matchesPriorityPrompt('compile the report'), false);
});

test('does NOT match "interface for the API"', () => {
  assert.strictEqual(matchesPriorityPrompt('interface for the API'), false);
});

test('does NOT match "shell script to deploy"', () => {
  assert.strictEqual(matchesPriorityPrompt('shell script to deploy'), false);
});

test('does NOT match "just CSS columns please"', () => {
  assert.strictEqual(matchesPriorityPrompt('just CSS columns please'), false);
});

// Generic non-matches.

test('does NOT match plain "what is 2+2?"', () => {
  assert.strictEqual(matchesPriorityPrompt('what is 2+2?'), false);
});

test('does NOT match "list files in this directory"', () => {
  assert.strictEqual(matchesPriorityPrompt('list files in this directory'), false);
});

test('whole-word only: "transform" does not match (substring of "form" is gone anyway)', () => {
  assert.strictEqual(matchesPriorityPrompt('transform the data'), false);
});

test('handles empty string', () => {
  assert.strictEqual(matchesPriorityPrompt(''), false);
});

test('handles null/undefined', () => {
  assert.strictEqual(matchesPriorityPrompt(null), false);
  assert.strictEqual(matchesPriorityPrompt(undefined), false);
});
