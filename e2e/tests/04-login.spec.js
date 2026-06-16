const { test, expect } = require('@playwright/test');

test.describe('login', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  test('shows login form initially', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('Login');
    await expect(page.locator('form')).toBeVisible();
    await expect(page.locator('input[name="username"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  test('invalid credentials show error message', async ({ page }) => {
    await page.fill('input[name="username"]', 'taro');
    await page.fill('input[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');
    await expect(page.locator('p[style*="color:red"]')).toContainText('Invalid username or password');
  });

  test('valid login shows welcome message', async ({ page }) => {
    await page.fill('input[name="username"]', 'taro');
    await page.fill('input[name="password"]', 'password1');
    await page.click('button[type="submit"]');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('h2')).toContainText('Welcome, taro!');
  });

  test('nav shows Detail link after login', async ({ page }) => {
    await page.fill('input[name="username"]', 'taro');
    await page.fill('input[name="password"]', 'password1');
    await page.click('button[type="submit"]');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('nav a:has-text("Detail")')).toBeVisible();
  });

  test('logout returns to login form', async ({ page }) => {
    await page.fill('input[name="username"]', 'taro');
    await page.fill('input[name="password"]', 'password1');
    await page.click('button[type="submit"]');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');

    await page.click('button:has-text("Logout")');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('h2')).toContainText('Login');
  });

  test('Detail link disappears after logout', async ({ page }) => {
    await page.fill('input[name="username"]', 'taro');
    await page.fill('input[name="password"]', 'password1');
    await page.click('button[type="submit"]');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');

    await page.click('button:has-text("Logout")');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('nav a:has-text("Detail")')).toHaveCount(0);
  });

  test('unauthenticated access to /detail redirects to /', async ({ page }) => {
    await page.goto('/detail');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('h2')).toContainText('Login');
  });

  test('detail page shows username and last login', async ({ page }) => {
    await page.fill('input[name="username"]', 'jiro');
    await page.fill('input[name="password"]', 'password2');
    await page.click('button[type="submit"]');
    await page.waitForURL('/');
    await page.waitForSelector('[data-component]');

    await page.click('a:has-text("Detail")');
    await page.waitForSelector('[data-component]');
    await expect(page.locator('h2')).toContainText('Detail');
    await expect(page.locator('body')).toContainText('jiro');
    await expect(page.locator('body')).toContainText('Last Login:');
  });
});
