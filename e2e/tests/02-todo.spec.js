const { test, expect } = require('@playwright/test');

test.describe('todo', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  test('initial list is empty', async ({ page }) => {
    await expect(page.locator('li')).toHaveCount(0);
  });

  test('add a todo item', async ({ page }) => {
    await page.fill('input[name="todo-text"]', 'Buy groceries');
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(1);
    await expect(page.locator('li span')).toContainText('Buy groceries');
  });

  test('add multiple todo items', async ({ page }) => {
    await page.fill('input[name="todo-text"]', 'First task');
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(1);

    await page.fill('input[name="todo-text"]', 'Second task');
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(2);
  });

  test('empty input is ignored', async ({ page }) => {
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(0);
  });

  test('toggle todo to done', async ({ page }) => {
    await page.fill('input[name="todo-text"]', 'Test item');
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(1);

    await page.click('li input[type="checkbox"]');
    await expect(page.locator('li input[type="checkbox"]')).toBeChecked();
  });

  test('toggle todo back to undone', async ({ page }) => {
    await page.fill('input[name="todo-text"]', 'Test item');
    await page.click('button:has-text("Add")');
    await page.click('li input[type="checkbox"]');
    await expect(page.locator('li input[type="checkbox"]')).toBeChecked();

    await page.click('li input[type="checkbox"]');
    await expect(page.locator('li input[type="checkbox"]')).not.toBeChecked();
  });

  test('delete a todo item', async ({ page }) => {
    await page.fill('input[name="todo-text"]', 'Delete me');
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(1);

    await page.click('li button:has-text("Delete")');
    await expect(page.locator('li')).toHaveCount(0);
  });

  test('delete one of multiple items', async ({ page }) => {
    await page.fill('input[name="todo-text"]', 'Keep this');
    await page.click('button:has-text("Add")');
    await page.fill('input[name="todo-text"]', 'Delete this');
    await page.click('button:has-text("Add")');
    await expect(page.locator('li')).toHaveCount(2);

    await page.locator('li:has-text("Delete this") button:has-text("Delete")').click();
    await expect(page.locator('li')).toHaveCount(1);
    await expect(page.locator('li span')).toContainText('Keep this');
  });
});
