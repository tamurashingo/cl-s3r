const { test, expect } = require('@playwright/test');

// One route per nesting pattern; see sample/11-nested/README.md for the write-up.
//
// Every click is followed by an assertion before the next one: an action is a
// round trip to the server, and clicking again before the response lands would
// send the same state twice.
test.describe('nested', () => {

  // Click BUTTON and wait for COUNTER to read EXPECTED.
  const bump = async (button, counter, expected) => {
    await button.click();
    await expect(counter).toHaveText(expected);
  };

  test('index lists every case', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('ul.index');
    await expect(page.locator('ul.index li')).toHaveCount(13);
  });

  // --- 1. stateless child invokes a parent action ---

  test('case1: a stateless child reaches the parent action', async ({ page }) => {
    await page.goto('/case1');
    await page.waitForSelector('.parent');
    await page.locator('.parent-action').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await page.locator('.parent-action').click();
    await expect(page.locator('.parent-count')).toHaveText('2');
  });

  // --- 2. stateful child drives its own action ---

  test('case2: a stateful child updates only its own state', async ({ page }) => {
    await page.goto('/case2');
    await page.waitForSelector('.parent');
    const count = page.locator('.child-count');
    await bump(page.locator('.child-inc'), count, '1');
    await bump(page.locator('.child-inc'), count, '2');
    await bump(page.locator('.child-inc'), count, '3');
    await expect(page.locator('.parent-count')).toHaveText('0');
  });

  // --- 3. a parent re-render keeps the child's state ---

  test('case3: the child keeps its state when the parent re-renders', async ({ page }) => {
    await page.goto('/case3');
    await page.waitForSelector('.parent');
    const count = page.locator('.child-count');
    await bump(page.locator('.child-inc'), count, '1');
    await bump(page.locator('.child-inc'), count, '2');

    const child = page.locator('[data-component="counter-child"]');
    const idBefore = await child.getAttribute('data-component-id');

    await page.locator('.parent-inc').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await expect(page.locator('.child-count')).toHaveText('2');
    await expect(child).toHaveAttribute('data-component-id', idBefore);
  });

  // --- 4. a parent action rendered inside a stateful child ---

  test('case4: a parent action inside a stateful child still runs', async ({ page }) => {
    await page.goto('/case4');
    await page.waitForSelector('.parent');
    await page.locator('.parent-action').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await expect(page.locator('.wrapper-hits')).toHaveText('0');

    await page.locator('.wrapper-inc').click();
    await expect(page.locator('.wrapper-hits')).toHaveText('1');
    await expect(page.locator('.parent-count')).toHaveText('1');
  });

  // --- 5. two instances of the same stateful child ---

  test('case5: sibling instances keep separate state', async ({ page }) => {
    await page.goto('/case5');
    await page.waitForSelector('.parent');
    const counts = page.locator('.child-count');

    await bump(page.locator('.child-inc').nth(1), counts.nth(1), '101');
    await bump(page.locator('.child-inc').nth(1), counts.nth(1), '102');
    await bump(page.locator('.child-inc').nth(0), counts.nth(0), '1');

    await page.locator('.parent-inc').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await expect(counts.nth(0)).toHaveText('1');
    await expect(counts.nth(1)).toHaveText('102');
  });

  test('case5: component ids are unique and positional', async ({ page }) => {
    await page.goto('/case5');
    await page.waitForSelector('.parent');
    const ids = await page.$$eval('[data-component-id]',
      els => els.map(e => e.getAttribute('data-component-id')));
    expect(ids).toEqual(['case5-app-0', 'counter-child-0.0', 'counter-child-0.1']);
    await page.locator('.parent-inc').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    const after = await page.$$eval('[data-component-id]',
      els => els.map(e => e.getAttribute('data-component-id')));
    expect(after).toEqual(ids);
  });

  // --- 6. depth-3 nesting ---

  test('case6: depth does not change where an action is handled', async ({ page }) => {
    await page.goto('/case6');
    await page.waitForSelector('.parent');
    await page.locator('.parent-action').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await page.locator('.child-inc').click();
    await expect(page.locator('.child-count')).toHaveText('1');
    await expect(page.locator('.parent-count')).toHaveText('1');
  });

  // --- 7. state lifted to the root ---

  test('case7: lifted state survives every update', async ({ page }) => {
    await page.goto('/case7');
    await page.waitForSelector('.parent');
    const counts = page.locator('.child-count');
    await bump(page.locator('.child-inc').nth(0), counts.nth(0), '1');
    await bump(page.locator('.child-inc').nth(0), counts.nth(0), '2');
    await bump(page.locator('.child-inc').nth(1), counts.nth(1), '1');
    await page.locator('.parent-inc').click();
    await expect(counts.nth(0)).toHaveText('12');
    await expect(counts.nth(1)).toHaveText('11');
  });

  // --- 8. stateful child inside a stateful child ---

  test('case8: a partial re-render keeps ids unique and props intact', async ({ page }) => {
    await page.goto('/case8');
    await page.waitForSelector('.parent');
    const children = page.locator('[data-component="counter-child"]');
    await expect(children.nth(0)).toHaveAttribute('data-component-id', 'counter-child-0.0');
    await expect(children.nth(1)).toHaveAttribute('data-component-id', 'counter-child-0.1.0');

    await bump(page.locator('.child-inc').nth(0),           // outer A
               children.nth(0).locator('.child-count'), '1');
    await bump(page.locator('.parent-inc'), page.locator('.parent-count'), '1');
    await bump(page.locator('.wrapper-inc'), page.locator('.wrapper-hits'), '1');

    await bump(page.locator('.child-inc').nth(0),           // outer A again
               children.nth(0).locator('.child-count'), '2');
    await expect(children.nth(0).locator('.label')).toHaveText('outer A');
    await expect(children.nth(1).locator('.label')).toHaveText('inner B');
    await expect(children.nth(1).locator('.child-count')).toHaveText('50');
  });

  // --- 9. key for list children ---

  test('case9: a keyed child keeps its state through a re-order', async ({ page }) => {
    await page.goto('/case9');
    await page.waitForSelector('.parent');
    const keyed = page.locator('.mid').nth(0);
    const unkeyed = page.locator('.mid').nth(1);

    await bump(keyed.locator('.child-inc').nth(0), keyed.locator('.child-count').nth(0), '1');
    await bump(keyed.locator('.child-inc').nth(0), keyed.locator('.child-count').nth(0), '2');
    await bump(keyed.locator('.child-inc').nth(0), keyed.locator('.child-count').nth(0), '3');
    await bump(unkeyed.locator('.child-inc').nth(0), unkeyed.locator('.child-count').nth(0), '1');

    await page.locator('.rotate').click();

    // alpha moved to the end of the list and took its count with it
    await expect(keyed.locator('.label').nth(2)).toHaveText('alpha');
    await expect(keyed.locator('.child-count').nth(2)).toHaveText('3');
    await expect(keyed.locator('.child-count').nth(0)).toHaveText('0');

    // without a key the count stays with the position
    await expect(unkeyed.locator('.label').nth(0)).toHaveText('bravo');
    await expect(unkeyed.locator('.child-count').nth(0)).toHaveText('1');
  });

  // --- 11. DOM preservation when a list changes ---

  test('case11: a keyed element keeps its DOM node when the list grows', async ({ page }) => {
    await page.goto('/case11');
    await page.waitForSelector('.parent');
    const keyed = page.locator('.mid').nth(0);

    // Type into bravo and mark the live node, so we can tell reuse from a rewrite.
    await keyed.locator('.note-text').nth(1).fill('bravo-text');
    await keyed.locator('.note').nth(1).evaluate((el) => { el.__mark = true; });

    await page.locator('.prepend').click();
    await expect(keyed.locator('.note')).toHaveCount(4);

    // bravo moved down one place and took its node -- and so its text -- along.
    await expect(keyed.locator('.label').nth(2)).toHaveText('bravo');
    await expect(keyed.locator('.note-text').nth(2)).toHaveValue('bravo-text');
    expect(await keyed.locator('.note').nth(2).evaluate((el) => el.__mark === true)).toBe(true);

    // the element that is now first is a fresh one
    await expect(keyed.locator('.note-text').nth(0)).toHaveValue('');
    expect(await keyed.locator('.note').nth(0).evaluate((el) => el.__mark === true)).toBe(false);
  });

  test('case11: without a key the text stays with the position', async ({ page }) => {
    await page.goto('/case11');
    await page.waitForSelector('.parent');
    const unkeyed = page.locator('.mid').nth(1);

    await unkeyed.locator('.note-text').nth(1).fill('bravo-text');
    await page.locator('.prepend').click();
    await expect(unkeyed.locator('.note')).toHaveCount(4);

    // position 1 is alpha now, and it is holding what was typed into bravo
    await expect(unkeyed.locator('.label').nth(1)).toHaveText('alpha');
    await expect(unkeyed.locator('.note-text').nth(1)).toHaveValue('bravo-text');
    await expect(unkeyed.locator('.note-text').nth(2)).toHaveValue('');
  });

  test('case11: a keyed element survives a removal too', async ({ page }) => {
    await page.goto('/case11');
    await page.waitForSelector('.parent');
    const keyed = page.locator('.mid').nth(0);

    await keyed.locator('.note-text').nth(2).fill('charlie-text');
    await page.locator('.drop-first').click();
    await expect(keyed.locator('.note')).toHaveCount(2);

    await expect(keyed.locator('.label').nth(1)).toHaveText('charlie');
    await expect(keyed.locator('.note-text').nth(1)).toHaveValue('charlie-text');
  });

  // --- 12. change events ---

  test('case12: select, radio, checkbox and text report through change', async ({ page }) => {
    await page.goto('/case12');
    await page.waitForSelector('.parent');
    const state = page.locator('.server-state');
    await expect(state).toHaveText('apple / m / no / ""');

    await page.selectOption('.fruit-select', 'cherry');
    await expect(state).toHaveText('cherry / m / no / ""');

    await page.locator('.size-radio').nth(2).check();
    await expect(state).toHaveText('cherry / l / no / ""');

    await page.locator('.agree-box').check();
    await expect(state).toHaveText('cherry / l / yes / ""');

    await page.locator('.agree-box').uncheck();
    await expect(state).toHaveText('cherry / l / no / ""');

    // a text field commits when it loses focus
    await page.fill('.note-field', 'hello');
    await page.locator('.fruit-select').focus();
    await expect(state).toHaveText('cherry / l / no / "hello"');
  });

  test('case12: a change action carries the control value', async ({ page }) => {
    const actions = [];
    await page.goto('/case12');
    await page.waitForSelector('.parent');
    page.on('request', (r) => {
      if (r.url().includes('/action')) actions.push(JSON.parse(r.postData()).action);
    });

    await page.selectOption('.fruit-select', 'banana');
    await expect(page.locator('.server-state')).toHaveText('banana / m / no / ""');
    await page.locator('.agree-box').check();
    await expect(page.locator('.server-state')).toHaveText('banana / m / yes / ""');

    expect(actions[0]).toEqual(['PICK-FRUIT', 'banana']);
    expect(actions[1]).toEqual(['SET-AGREED', true]);
  });

  test('case12: the server wins over a control the user already touched', async ({ page }) => {
    await page.goto('/case12');
    await page.waitForSelector('.parent');

    await page.selectOption('.fruit-select', 'cherry');
    await expect(page.locator('.server-state')).toHaveText('cherry / m / no / ""');
    await page.locator('.size-radio').nth(2).check();
    await expect(page.locator('.server-state')).toHaveText('cherry / l / no / ""');
    await page.fill('.note-field', 'typed');

    await page.locator('.reset-all').click();
    await expect(page.locator('.server-state')).toHaveText('apple / m / no / ""');

    // select and radio are controlled: selectedness follows the server even though
    // the user has already picked something
    await expect(page.locator('.fruit-select')).toHaveValue('apple');
    await expect(page.locator('.size-radio').nth(1)).toBeChecked();
    await expect(page.locator('.size-radio').nth(2)).not.toBeChecked();

    // the text field is uncontrolled: a re-render never overwrites what was typed
    await expect(page.locator('.note-field')).toHaveValue('typed');
  });

  // --- 13. an action named the same as its parent's ---

  test('case13: a child and its parent can both define bump', async ({ page }) => {
    await page.goto('/case13');
    await page.waitForSelector('.parent');

    // both advertise the bare name, so the name alone cannot say where a click goes
    await expect(page.locator('[data-component-id="case13-app-0"]'))
      .toHaveAttribute('data-actions', 'bump');
    await expect(page.locator('[data-component-id="same-name-wrapper-0.0"]'))
      .toHaveAttribute('data-actions', 'bump');

    // the child's own button carries the bare name, the passed one names the root
    await expect(page.locator('.own-bump'))
      .toHaveAttribute('data-on-click', '["BUMP"]');
    await expect(page.locator('.passed-bump'))
      .toHaveAttribute('data-on-click', '["bump@case13-app-0"]');
  });

  test('case13: each bump increments its own counter', async ({ page }) => {
    const actions = [];
    await page.goto('/case13');
    await page.waitForSelector('.parent');
    page.on('request', (r) => {
      if (r.url().includes('/action')) {
        const d = JSON.parse(r.postData());
        actions.push([d.action, d['component-id']]);
      }
    });

    await page.locator('.own-bump').click();
    await expect(page.locator('.wrapper-hits')).toHaveText('1');
    await expect(page.locator('.parent-count')).toHaveText('0');

    // the callback the root handed down reaches the root, not the child that
    // happens to declare the same name
    await page.locator('.passed-bump').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await expect(page.locator('.wrapper-hits')).toHaveText('1');

    expect(actions[0]).toEqual([['BUMP'], 'same-name-wrapper-0.0']);
    expect(actions[1]).toEqual([['bump'], 'case13-app-0']);
  });

  test('case13: the binding survives a re-render of the parent', async ({ page }) => {
    await page.goto('/case13');
    await page.waitForSelector('.parent');

    // the first click re-renders the root, so the markup the child gets back has
    // to carry the qualified name again
    await page.locator('.passed-bump').click();
    await expect(page.locator('.parent-count')).toHaveText('1');
    await expect(page.locator('.passed-bump'))
      .toHaveAttribute('data-on-click', '["bump@case13-app-0"]');

    await page.locator('.passed-bump').click();
    await expect(page.locator('.parent-count')).toHaveText('2');
    await expect(page.locator('.wrapper-hits')).toHaveText('0');
  });

  // --- 10. an action no component defines ---

  test('case10: an undefined action is reported instead of ignored', async ({ page }) => {
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.goto('/case10');
    await page.waitForSelector('.parent');

    await page.locator('.defined-action').click();
    await expect(page.locator('.parent-count')).toHaveText('1');

    const response = page.waitForResponse(r => r.url().includes('/action'));
    await page.locator('.undefined-action').click();
    expect((await response).status()).toBe(422);
    await expect.poll(() => errors.length).toBeGreaterThan(0);
    expect(errors.join('\n')).toContain('NO-SUCH-ACTION');
    expect(errors.join('\n')).toContain('case10-app');
  });
});
