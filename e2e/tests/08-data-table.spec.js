const { test, expect } = require('@playwright/test');

test.describe('data-table', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-component]');
  });

  // --- demo-rows-pager (rows + pager, page-size=5, 30 rows) ---

  test('rows+pager: shows page-size rows on initial render', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-rows-pager"]');
    const rows = table.locator('tbody tr');
    await expect(rows).toHaveCount(5);
  });

  test('rows+pager: Previous button is disabled on the first page', async ({ page }) => {
    const pager = page.locator('[data-component-id="demo-rows-pager"] .data-table__pager');
    const prevBtn = pager.locator('button:has-text("Previous")');
    await expect(prevBtn).toBeDisabled();
  });

  test('rows+pager: Next button navigates to the next page', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-rows-pager"]');
    const pager = table.locator('.data-table__pager');
    const nextBtn = pager.locator('button:has-text("Next")');
    const info = pager.locator('.data-table__pager-info');

    await nextBtn.click();
    await expect(info).toContainText('2 /');
    await expect(table.locator('tbody tr')).toHaveCount(5);
  });

  test('rows+pager: Previous button navigates back to the previous page', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-rows-pager"]');
    const pager = table.locator('.data-table__pager');
    const nextBtn = pager.locator('button:has-text("Next")');
    const prevBtn = pager.locator('button:has-text("Previous")');
    const info = pager.locator('.data-table__pager-info');

    await nextBtn.click();
    await expect(info).toContainText('2 /');
    await prevBtn.click();
    await expect(info).toContainText('1 /');
  });

  test('rows+pager: Next button is disabled on the last page', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-rows-pager"]');
    const pager = table.locator('.data-table__pager');
    const nextBtn = pager.locator('button:has-text("Next")');
    const info = pager.locator('.data-table__pager-info');

    // 30 rows / page-size 5 = 6 pages; click next 5 times
    await nextBtn.click();
    await expect(info).toContainText('2 /');
    await nextBtn.click();
    await expect(info).toContainText('3 /');
    await nextBtn.click();
    await expect(info).toContainText('4 /');
    await nextBtn.click();
    await expect(info).toContainText('5 /');
    await nextBtn.click();
    await expect(info).toContainText('6 /');
    await expect(info).toContainText('6 /');
    await expect(nextBtn).toBeDisabled();
  });

  // --- demo-fetch (fetch-fn + pager, page-size=10, 30 rows) ---

  test('fetch-fn+pager: shows 10 rows on initial render', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-fetch"]');
    await expect(table.locator('tbody tr')).toHaveCount(10);
  });

  test('fetch-fn+pager: Next button navigates to the next page', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-fetch"]');
    const pager = table.locator('.data-table__pager');
    const nextBtn = pager.locator('button:has-text("Next")');
    const info = pager.locator('.data-table__pager-info');

    await nextBtn.click();
    await expect(info).toContainText('2 /');
  });

  test('fetch-fn+pager: Next button is disabled on the last page', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-fetch"]');
    const pager = table.locator('.data-table__pager');
    const nextBtn = pager.locator('button:has-text("Next")');
    const info = pager.locator('.data-table__pager-info');

    // 30 rows / page-size 10 = 3 pages; click next 2 times
    await nextBtn.click();
    await nextBtn.click();
    await expect(info).toContainText('3 /');
    await expect(nextBtn).toBeDisabled();
  });

  // --- demo-columns (with columns) ---

  test('columns: header row is visible', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-columns"]');
    await expect(table.locator('thead')).toBeVisible();
    await expect(table.locator('thead th').first()).toContainText('Fruit');
  });

  // --- demo-raw (no columns) ---

  test('raw: no header row without columns', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-raw"]');
    await expect(table.locator('thead')).toHaveCount(0);
  });

  // --- demo-empty (empty data) ---

  test('empty: shows empty message when there are no rows', async ({ page }) => {
    const table = page.locator('[data-component-id="demo-empty"]');
    await expect(table.locator('.data-table__empty')).toBeVisible();
    await expect(table.locator('.data-table__empty')).toContainText('No data');
  });
});
