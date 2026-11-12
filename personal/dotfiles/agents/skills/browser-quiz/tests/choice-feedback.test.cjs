const {test} = require('node:test');
const assert = require('node:assert/strict');
require('../web/choice-feedback.js');
const {forChoice, attach} = globalThis.QuizChoiceFeedback;
const question = {type: 'radiogroup'};
const response = {answer: 'wrong', correctAnswer: 'right', outcome: 'incorrect', explanation: 'General reason', choiceExplanations: {right: 'Specific right reason', wrong: 'Specific wrong reason', other: 'Other reason'}};

test('selected wrong answer gets only its own explanation', () => {
  assert.deepEqual(forChoice(question, response, 'wrong'), {kind: 'incorrect', label: 'Your answer - incorrect', paragraphs: ['Specific wrong reason']});
});
test('correct answer carries the general and correct-choice reasons', () => {
  assert.deepEqual(forChoice(question, response, 'right').paragraphs, ['General reason', 'Specific right reason']);
  assert.match(forChoice(question, response, 'right').label, /not selected/);
});
test('unselected incorrect choices do not acquire feedback', () => {
  assert.equal(forChoice(question, response, 'other'), null);
});
test('correct selected choice is clearly identified', () => {
  assert.equal(forChoice(question, {...response, answer: 'right', outcome: 'correct'}, 'right').label, 'Your answer - correct');
});
test('skipping reveals the correct choice without inventing a selection', () => {
  const skipped = {...response, answer: null, outcome: 'skipped'};
  assert.equal(forChoice(question, skipped, 'right').label, 'Correct answer');
  assert.equal(forChoice(question, skipped, 'wrong'), null);
});
test('checkboxes explain selected and missed correct choices separately', () => {
  const multi = {...response, answer: ['wrong','right'], correctAnswer: ['right','other']};
  assert.equal(forChoice({type:'checkbox'}, multi, 'other').label, 'Correct answer - not selected');
  assert.deepEqual(forChoice({type:'checkbox'}, multi, 'right').paragraphs, ['Specific right reason']);
});
test('legacy definitions use the existing correct reason, without inventing a wrong one', () => {
  const legacy = {...response, choiceExplanations: undefined};
  assert.deepEqual(forChoice(question, legacy, 'right').paragraphs, ['General reason']);
  assert.match(forChoice(question, legacy, 'wrong').paragraphs[0], /no explanation/);
});
test('outgoing questions with reused choice values are not decorated', () => {
  const input = {
    closest: () => ({getAttribute: () => 'outgoing-question'}),
    get value() { throw new Error('Must not inspect another question’s choices'); },
  };
  attach({querySelectorAll: () => [input]}, {...question, name: 'current-question'}, response);
});
test('controls outside a SurveyJS question are not decorated', () => {
  const input = {
    closest: () => null,
    get value() { throw new Error('Must not inspect unrelated controls'); },
  };
  attach({querySelectorAll: () => [input]}, {...question, name: 'current-question'}, response);
});
test('identical correct reasons are not duplicated', () => {
  assert.deepEqual(forChoice(question, {...response, explanation:'Specific right reason'}, 'right').paragraphs, ['Specific right reason']);
});
