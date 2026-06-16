const { test, expect } = require('@playwright/test');

test.describe('counter', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  test('initial count is 0', async ({ page }) => {
    await expect(page.locator('p')).toContainText('Count: 0');
  });

  test('increment increases count', async ({ page }) => {
    await page.click('button:has-text("+")');
    await expect(page.locator('p')).toContainText('Count: 1');
  });

  test('decrement decreases count', async ({ page }) => {
    await page.click('button:has-text("-")');
    await expect(page.locator('p')).toContainText('Count: -1');
  });

  test('multiple increments accumulate', async ({ page }) => {
    await page.click('button:has-text("+")');
    await expect(page.locator('p')).toContainText('Count: 1');
    await page.click('button:has-text("+")');
    await expect(page.locator('p')).toContainText('Count: 2');
    await page.click('button:has-text("+")');
    await expect(page.locator('p')).toContainText('Count: 3');
  });

  test('increment then decrement returns to initial', async ({ page }) => {
    await page.click('button:has-text("+")');
    await expect(page.locator('p')).toContainText('Count: 1');
    await page.click('button:has-text("-")');
    await expect(page.locator('p')).toContainText('Count: 0');
  });
});
