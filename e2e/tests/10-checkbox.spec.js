const { test, expect } = require('@playwright/test');

test.describe('checkbox', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  // --- 1. uncontrolled checkbox ---

  test('uncontrolled: first checkbox starts unchecked', async ({ page }) => {
    const section = page.locator('section').nth(0);
    const box = section.locator('.cl-s3r-checkbox').nth(0);
    await expect(box).toHaveAttribute('aria-checked', 'false');
  });

  test('uncontrolled: second checkbox starts checked', async ({ page }) => {
    const section = page.locator('section').nth(0);
    const box = section.locator('.cl-s3r-checkbox').nth(1);
    await expect(box).toHaveAttribute('aria-checked', 'true');
  });

  test('uncontrolled: clicking the box toggles its own state', async ({ page }) => {
    const section = page.locator('section').nth(0);
    const box = section.locator('.cl-s3r-checkbox').nth(0);
    await box.click();
    await expect(box).toHaveAttribute('aria-checked', 'true');
    await expect(box.locator('.cl-s3r-checkbox-box--checked')).toHaveCount(1);
    await box.click();
    await expect(box).toHaveAttribute('aria-checked', 'false');
  });

  test('uncontrolled: clicking the label text toggles it too', async ({ page }) => {
    const section = page.locator('section').nth(0);
    const box = section.locator('.cl-s3r-checkbox').nth(0);
    await box.getByText('Subscribe to newsletter').click();
    await expect(box).toHaveAttribute('aria-checked', 'true');
  });

  // --- 2. disabled checkbox ---

  test('disabled: starts unchecked and stays unchecked when clicked', async ({ page }) => {
    const section = page.locator('section').nth(1);
    const box = section.locator('.cl-s3r-checkbox').first();
    await expect(box).toHaveAttribute('aria-checked', 'false');
    await expect(box).toHaveAttribute('aria-disabled', 'true');
    await box.click({ force: true });
    await expect(box).toHaveAttribute('aria-checked', 'false');
  });

  // --- 3. uncontrolled + disabled ---

  test('uncontrolled + disabled: starts checked and cannot be unchecked', async ({ page }) => {
    const section = page.locator('section').nth(2);
    const box = section.locator('.cl-s3r-checkbox').first();
    await expect(box).toHaveAttribute('aria-checked', 'true');
    await box.click({ force: true });
    await expect(box).toHaveAttribute('aria-checked', 'true');
  });

  // --- 4. controlled checkbox: parent owns and reads the on/off state ---

  test('controlled: starts unsubscribed and reports NIL', async ({ page }) => {
    const section = page.locator('section').nth(3);
    const box = section.locator('.cl-s3r-checkbox').first();
    await expect(box).toHaveAttribute('aria-checked', 'false');
    await expect(section.locator('p:has-text("current state:")')).toContainText('NIL');
  });

  test('controlled: clicking flips the box and the reported state', async ({ page }) => {
    const section = page.locator('section').nth(3);
    const box = section.locator('.cl-s3r-checkbox').first();
    await box.click();
    await expect(box).toHaveAttribute('aria-checked', 'true');
    await expect(section.locator('p:has-text("current state:")')).toContainText('T');
    await box.click();
    await expect(box).toHaveAttribute('aria-checked', 'false');
    await expect(section.locator('p:has-text("current state:")')).toContainText('NIL');
  });

  // --- 5. native form submission ---

  test('form: submitting unchecked reports agree not sent', async ({ page }) => {
    const section = page.locator('section').nth(4);
    await section.locator('button:has-text("Submit")').click();
    await expect(section.locator('p:has-text("last submit payload:")')).toContainText('agree not sent');
  });

  test('form: checking then submitting reports agree=on', async ({ page }) => {
    const section = page.locator('section').nth(4);
    await section.locator('.cl-s3r-checkbox').first().click();
    await section.locator('button:has-text("Submit")').click();
    await expect(section.locator('p:has-text("last submit payload:")')).toContainText('agree=on');
  });
});
