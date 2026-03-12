import { test, expect } from '@playwright/test';

const hasAdminCreds = !!(process.env.E2E_ADMIN_EMAIL && process.env.E2E_ADMIN_PASSWORD);
const hasRequestorCreds = !!(process.env.E2E_REQUESTOR_EMAIL && process.env.E2E_REQUESTOR_PASSWORD);

async function loginAs(page: import('@playwright/test').Page, email: string, password: string) {
  await page.goto('/login', { waitUntil: 'networkidle' });
  await expect(page.getByRole('heading', { name: /be electric/i })).toBeVisible({ timeout: 15000 });
  await page.getByPlaceholder(/you@company\.com|email/i).fill(email);
  await page.locator('input[type="password"]').fill(password);
  await page.getByRole('button', { name: /sign in/i }).click();
}

test.describe('Smoke', () => {
  test('login page loads and shows sign-in form', async ({ page }) => {
    await page.goto('/login', { waitUntil: 'networkidle' });
    await expect(page.getByRole('heading', { name: /be electric/i })).toBeVisible();
    await expect(page.getByPlaceholder(/you@company\.com|email/i)).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
    await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible();
  });

  test('login as admin redirects to dashboard', async ({ page }) => {
    test.skip(!hasAdminCreds, 'Set E2E_ADMIN_EMAIL and E2E_ADMIN_PASSWORD to run');
    await loginAs(page, process.env.E2E_ADMIN_EMAIL!, process.env.E2E_ADMIN_PASSWORD!);
    await expect(page).toHaveURL(/\/(dashboard|work-orders|pm-tasks)/, { timeout: 15000 });
    await expect(page.getByText(/be electric/i).first()).toBeVisible();
  });

  test('login as requestor redirects to my-requests', async ({ page }) => {
    test.skip(!hasRequestorCreds, 'Set E2E_REQUESTOR_EMAIL and E2E_REQUESTOR_PASSWORD to run');
    await loginAs(page, process.env.E2E_REQUESTOR_EMAIL!, process.env.E2E_REQUESTOR_PASSWORD!);
    await expect(page).toHaveURL(/\/(my-requests|request)/, { timeout: 15000 });
    await expect(page.getByText(/be electric/i).first()).toBeVisible();
  });

  test('admin can open parts requests page', async ({ page }) => {
    test.skip(!hasAdminCreds, 'Set E2E_ADMIN_EMAIL and E2E_ADMIN_PASSWORD to run');
    await loginAs(page, process.env.E2E_ADMIN_EMAIL!, process.env.E2E_ADMIN_PASSWORD!);
    await expect(page).toHaveURL(/\/(dashboard|work-orders|pm-tasks)/, { timeout: 15000 });
    await page.goto('/parts-requests');
    await expect(page).toHaveURL('/parts-requests');
    await expect(page.getByRole('heading', { name: /parts requests/i })).toBeVisible();
  });

  test('requestor can open request page', async ({ page }) => {
    test.skip(!hasRequestorCreds, 'Set E2E_REQUESTOR_EMAIL and E2E_REQUESTOR_PASSWORD to run');
    await loginAs(page, process.env.E2E_REQUESTOR_EMAIL!, process.env.E2E_REQUESTOR_PASSWORD!);
    await expect(page).toHaveURL(/\/(my-requests|request)/, { timeout: 15000 });
    await page.goto('/request');
    await expect(page).toHaveURL('/request');
    await expect(page.getByRole('heading', { name: /request|maintenance/i })).toBeVisible();
  });

  test('admin can open Users page and user list loads (no permission error)', async ({ page }) => {
    test.skip(!hasAdminCreds, 'Set E2E_ADMIN_EMAIL and E2E_ADMIN_PASSWORD to run');
    await loginAs(page, process.env.E2E_ADMIN_EMAIL!, process.env.E2E_ADMIN_PASSWORD!);
    await expect(page).toHaveURL(/\/(dashboard|work-orders|pm-tasks|users)/, { timeout: 15000 });
    await page.goto('/users');
    await expect(page).toHaveURL('/users');
    await expect(page.getByRole('heading', { name: /^users$/i })).toBeVisible();
    await expect(page.getByText(/failed to load users/i)).not.toBeVisible({ timeout: 5000 });
  });
});
