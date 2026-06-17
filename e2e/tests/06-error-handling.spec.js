const { test, expect } = require('@playwright/test');

test.describe('error-handling', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  test('home page shows item list', async ({ page }) => {
    await expect(page.locator('ul li')).toHaveCount(3);
    await expect(page.locator('main h1')).toContainText('Items');
  });

  test('valid item page shows item detail', async ({ page }) => {
    await page.click('a:has-text("Apple")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('main h1')).toContainText('Apple');
    await expect(page.locator('body')).toContainText('A red fruit');
  });

  test('back link returns to list', async ({ page }) => {
    await page.click('a:has-text("Apple")');
    await page.waitForSelector('[data-component]');
    await page.click('a:has-text("← Back to list")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('main h1')).toContainText('Items');
  });

  test('navigating to missing item shows 404 error page', async ({ page }) => {
    await page.click('a:has-text("Missing Item (404)")');
    // Error page replaces mount target body — wait for the error box to appear
    await page.waitForSelector('.error-box');
    await expect(page.locator('.error-box h1')).toContainText('404');
    await expect(page.locator('body')).toContainText('not found');
  });

  test('404 error page contains back link', async ({ page }) => {
    await page.goto('/item/999');
    await page.waitForSelector('.error-box');
    await expect(page.locator('a:has-text("← Back to top")')).toBeVisible();
  });

  test('navigating to crash page shows 500 error page', async ({ page }) => {
    await page.click('a:has-text("Server Error (500)")');
    await page.waitForSelector('.error-box');
    await expect(page.locator('.error-box h1')).toContainText('500');
  });

  test('500 error page contains back link', async ({ page }) => {
    await page.goto('/crash');
    await page.waitForSelector('.error-box');
    await expect(page.locator('a:has-text("← Back to top")')).toBeVisible();
  });

  test('404 error page uses the app layout', async ({ page }) => {
    await page.goto('/item/999');
    await page.waitForSelector('.error-box');
    // App layout includes header with "Error Handling Demo"
    await expect(page.locator('header')).toContainText('Error Handling Demo');
  });

  test('can navigate back to home from error page', async ({ page }) => {
    await page.goto('/item/999');
    await page.waitForSelector('.error-box');
    await page.click('a:has-text("← Back to top")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('main h1')).toContainText('Items');
  });
});
