const { test, expect } = require('@playwright/test');

test.describe('books', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  test('shows all 8 implementations', async ({ page }) => {
    await expect(page.locator('ul li')).toHaveCount(8);
  });

  test('search by name filters results', async ({ page }) => {
    // "Clozure" uniquely matches CCL only
    await page.fill('input[name="filter"]', 'Clozure');
    await page.click('button:has-text("Search")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('ul li')).toHaveCount(1);
    await expect(page.locator('ul li')).toContainText('CCL');
  });

  test('search with no match shows empty list', async ({ page }) => {
    await page.fill('input[name="filter"]', 'nonexistent-xyz');
    await page.click('button:has-text("Search")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('ul li')).toHaveCount(0);
  });

  test('search filter is shown in filtered result message', async ({ page }) => {
    await page.fill('input[name="filter"]', 'Clozure');
    await page.click('button:has-text("Search")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('p em')).toContainText('Filtered by: Clozure');
  });

  test('navigate to detail page', async ({ page }) => {
    await page.click('a:has-text("SBCL")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('main h1')).toContainText('SBCL');
  });

  test('detail page shows implementation info', async ({ page }) => {
    await page.click('a:has-text("SBCL")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('body')).toContainText('Steel Bank Common Lisp');
    await expect(page.locator('body')).toContainText('License:');
    await expect(page.locator('body')).toContainText('Repository:');
  });

  test('back link returns to list', async ({ page }) => {
    await page.click('a:has-text("SBCL")');
    await page.waitForSelector('[data-component]');
    await page.click('a:has-text("← Back to list")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('main h1')).toContainText('Common Lisp OSS Implementations');
    await expect(page.locator('ul li')).toHaveCount(8);
  });
});
