const { test, expect } = require('@playwright/test');

test.describe('dialog', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  // --- alert dialog ---

  test('alert: dialog is hidden on initial render', async ({ page }) => {
    await expect(page.locator('.cl-s3r-dialog-overlay')).toHaveCount(0);
  });

  test('alert: clicking Open button shows the dialog', async ({ page }) => {
    const section = page.locator('section').first();
    await section.locator('button:has-text("Open alert dialog")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toBeVisible();
  });

  test('alert: dialog title is rendered inside header', async ({ page }) => {
    const section = page.locator('section').first();
    await section.locator('button:has-text("Open alert dialog")').click();
    await expect(page.locator('.cl-s3r-dialog-header')).toContainText('dialog');
  });

  test('alert: ok button closes the dialog', async ({ page }) => {
    const section = page.locator('section').first();
    await section.locator('button:has-text("Open alert dialog")').click();
    await page.locator('.cl-s3r-dialog-action:has-text("ok")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toHaveCount(0);
  });

  // --- confirm dialog ---

  test('confirm: yes button closes dialog and records answer', async ({ page }) => {
    const section = page.locator('section').nth(1);
    await section.locator('button:has-text("Open confirm dialog")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toBeVisible();
    await page.locator('.cl-s3r-dialog-action:has-text("yes")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toHaveCount(0);
    await expect(section.locator('p').last()).toContainText('yes');
  });

  test('confirm: no button closes dialog and records answer', async ({ page }) => {
    const section = page.locator('section').nth(1);
    await section.locator('button:has-text("Open confirm dialog")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toBeVisible();
    await page.locator('.cl-s3r-dialog-action:has-text("no")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toHaveCount(0);
    await expect(section.locator('p').last()).toContainText('no');
  });

  // --- input dialog ---

  test('input: dialog shows text input', async ({ page }) => {
    const section = page.locator('section').nth(2);
    await section.locator('button:has-text("Open input dialog")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toBeVisible();
    await expect(page.locator('.cl-s3r-dialog-main input[type="text"]')).toBeVisible();
  });

  test('input: ok button submits the form and displays entered name', async ({ page }) => {
    const section = page.locator('section').nth(2);
    await section.locator('button:has-text("Open input dialog")').click();
    await page.locator('.cl-s3r-dialog-main input[type="text"]').fill('Taro');
    await page.locator('.cl-s3r-dialog-action:has-text("ok")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toHaveCount(0);
    await expect(section.locator('p').last()).toContainText('Taro');
  });

  test('input: cancel button closes the dialog without saving', async ({ page }) => {
    const section = page.locator('section').nth(2);
    await section.locator('button:has-text("Open input dialog")').click();
    await page.locator('.cl-s3r-dialog-main input[type="text"]').fill('ignored');
    await page.locator('.cl-s3r-dialog-action:has-text("cancel")').click();
    await expect(page.locator('.cl-s3r-dialog-overlay')).toHaveCount(0);
    await expect(section.locator('p:has-text("Entered name")')).toHaveCount(0);
  });

  // --- structural tests ---

  test('dialog box has header, main, footer', async ({ page }) => {
    const section = page.locator('section').first();
    await section.locator('button:has-text("Open alert dialog")').click();
    await expect(page.locator('.cl-s3r-dialog-box .cl-s3r-dialog-header')).toBeVisible();
    await expect(page.locator('.cl-s3r-dialog-box .cl-s3r-dialog-main')).toBeVisible();
    await expect(page.locator('.cl-s3r-dialog-box .cl-s3r-dialog-footer')).toBeVisible();
  });
});
