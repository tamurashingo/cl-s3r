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
    await expect(page.locator('ul.index li')).toHaveCount(10);
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
