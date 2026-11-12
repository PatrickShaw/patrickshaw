async (page) => {
  // Run only against examples/sample.json with an isolated results directory.
  const assert = (condition, message) => {
    if (!condition) throw new Error(message);
  };
  const readChoices = () => page.locator('#survey .sd-item').evaluateAll((items) => items.map((item) => {
    const input = item.querySelector('input');
    const note = item.querySelector('.choice-explanation');
    const label = item.querySelector('label');
    return {
      value: input.value,
      selected: input.checked,
      notes: item.querySelectorAll('.choice-explanation').length,
      text: note?.textContent ?? '',
      kind: note?.className ?? '',
      described: note !== null && (input.getAttribute('aria-describedby') ?? '').split(' ').includes(note.id),
      belowLabel: note === null || note.getBoundingClientRect().top >= label.getBoundingClientRect().bottom,
    };
  }));
  const assertPlacement = (choices, expected) => {
    choices.forEach((choice) => {
      const kind = expected[choice.value];
      assert(choice.notes === (kind === undefined ? 0 : 1), `Unexpected explanation count for ${choice.value}`);
      if (kind !== undefined) {
        assert(choice.kind.includes(`choice-explanation--${kind}`), `Wrong feedback kind for ${choice.value}`);
        assert(choice.belowLabel, `Explanation isn't underneath ${choice.value}`);
        assert(choice.described, `Missing accessible explanation association for ${choice.value}`);
      }
    });
  };
  const definition = await page.evaluate(() => fetch('quiz').then((response) => response.json()));
  assert(definition.title === 'A quick space quiz', 'Use the bundled sample, never a learner quiz');
  const progress = await page.evaluate(() => fetch('progress').then((response) => response.json()));
  assert(progress.responses.length === 0, 'Start a fresh isolated attempt');
  await page.getByRole('button', {name: 'Check answer', exact: true}).waitFor();
  assert(await page.locator('.choice-explanation').count() === 0, 'Answers leaked before checking');
  await page.locator('#survey').getByText('Venus', {exact: true}).click();
  await page.getByRole('button', {name: 'Check answer', exact: true}).click();
  await page.locator('#survey .choice-explanation--incorrect').waitFor();
  assertPlacement(await readChoices(), {venus: 'incorrect', mars: 'correct'});
  assert((await page.locator('#answer-feedback').innerText()) === 'Not quite', 'Explanations returned to a shared box');

  await page.reload();
  await page.locator('#survey .choice-explanation--incorrect').waitFor();
  assertPlacement(await readChoices(), {venus: 'incorrect', mars: 'correct'});
  await page.getByRole('button', {name: 'Next question', exact: true}).click();
  await page.getByRole('button', {name: 'Check answer', exact: true}).waitFor();
  assert(await page.locator('#survey .choice-explanation').count() === 0, 'Feedback leaked into the next question');
  await page.locator('#survey').getByText('Earth', {exact: true}).click();
  await page.locator('#survey').getByText('Jupiter', {exact: true}).click();
  const failSave = (route) => route.fulfill({status: 500, contentType: 'application/json', body: JSON.stringify({error: 'Simulated save failure'})});
  await page.route('**/submit', failSave);
  try {
    await page.getByRole('button', {name: 'Check answer', exact: true}).click();
    await page.getByRole('button', {name: 'Retry saving answers', exact: true}).waitFor();
    assertPlacement(await readChoices(), {earth: 'correct', mars: 'correct', jupiter: 'incorrect'});
    await page.setViewportSize({width: 390, height: 844});
    assertPlacement(await readChoices(), {earth: 'correct', mars: 'correct', jupiter: 'incorrect'});
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'Mobile layout overflows');
  } finally {
    await page.unroute('**/submit', failSave);
  }
  await page.getByRole('button', {name: 'Retry saving answers', exact: true}).click();
  await page.getByRole('button', {name: 'See summary', exact: true}).click();
  await page.getByRole('heading', {name: '0 / 2', exact: true}).waitFor();
  const summary = await page.locator('#results .review-choice').evaluateAll((items) => items.map((item) => {
    const note = item.querySelector('.choice-explanation');
    return {notes: item.querySelectorAll('.choice-explanation').length, below: note === null || note.getBoundingClientRect().top >= item.querySelector('label').getBoundingClientRect().bottom};
  }));
  assert(summary.every((choice) => choice.below), "Summary feedback isn't underneath its choice");
  assert(summary.reduce((count, choice) => count + choice.notes, 0) === 5, 'Summary duplicated or lost an explanation');
  await page.reload();
  await page.getByRole('heading', {name: '0 / 2', exact: true}).waitFor();
  assert(await page.locator('#results .choice-explanation').count() === 5, 'Saved review lost its inline feedback');
  return {radioFeedback: 'passed', checkboxFeedback: 'passed', transitionIsolation: 'passed', refresh: 'passed', mobile: 'passed', saveRetry: 'passed', summary: 'passed'};
}
