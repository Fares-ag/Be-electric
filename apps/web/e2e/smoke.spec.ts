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

test.describe('Public legal pages', () => {
  test('privacy page loads without login', async ({ page }) => {
    await page.goto('/privacy', { waitUntil: 'networkidle' });
    await expect(page).toHaveURL('/privacy');
    await expect(page.getByRole('heading', { name: /privacy policy/i })).toBeVisible();
    await expect(page.getByText(/support@be-maintain\.com/i)).toBeVisible();
  });

  test('terms page loads without login', async ({ page }) => {
    await page.goto('/terms', { waitUntil: 'networkidle' });
    await expect(page.getByRole('heading', { name: /terms of service/i })).toBeVisible();
  });

  test('support page loads without login', async ({ page }) => {
    await page.goto('/support', { waitUntil: 'networkidle' });
    await expect(page.getByRole('heading', { name: /help|support/i })).toBeVisible();
  });

  test('account deletion page loads without login', async ({ page }) => {
    await page.goto('/account-deletion', { waitUntil: 'networkidle' });
    await expect(page.getByRole('heading', { name: /account deletion/i })).toBeVisible();
  });
});

test.describe('Route guard', () => {
  test('requestor cannot access admin users page', async ({ page }) => {
    test.skip(!hasRequestorCreds, 'Set E2E_REQUESTOR_EMAIL and E2E_REQUESTOR_PASSWORD to run');
    await loginAs(page, process.env.E2E_REQUESTOR_EMAIL!, process.env.E2E_REQUESTOR_PASSWORD!);
    await page.goto('/users');
    await expect(page).toHaveURL(/\/my-requests/, { timeout: 15000 });
    await expect(page.getByRole('heading', { name: /^users$/i })).not.toBeVisible();
  });

  test('requestor can open work order detail but not admin list', async ({ page }) => {
    test.skip(!hasRequestorCreds, 'Set E2E_REQUESTOR_EMAIL and E2E_REQUESTOR_PASSWORD to run');
    await loginAs(page, process.env.E2E_REQUESTOR_EMAIL!, process.env.E2E_REQUESTOR_PASSWORD!);
    await page.goto('/work-orders');
    await expect(page).toHaveURL(/\/my-requests/, { timeout: 15000 });
    await page.goto('/my-requests');
    const viewLink = page.getByRole('link', { name: /view/i }).first();
    if (await viewLink.isVisible().catch(() => false)) {
      await viewLink.click();
      await expect(page).toHaveURL(/\/work-orders\/[^/]+/, { timeout: 15000 });
    }
  });

  test('requestor cannot access orphan assignments page', async ({ page }) => {
    test.skip(!hasRequestorCreds, 'Set E2E_REQUESTOR_EMAIL and E2E_REQUESTOR_PASSWORD to run');
    await loginAs(page, process.env.E2E_REQUESTOR_EMAIL!, process.env.E2E_REQUESTOR_PASSWORD!);
    await page.goto('/orphan-assignments');
    await expect(page).toHaveURL(/\/my-requests/, { timeout: 15000 });
    await expect(page.getByRole('heading', { name: /orphan assignments/i })).not.toBeVisible();
  });

  test('admin can open orphan assignments page', async ({ page }) => {
    test.skip(!hasAdminCreds, 'Set E2E_ADMIN_EMAIL and E2E_ADMIN_PASSWORD to run');
    await loginAs(page, process.env.E2E_ADMIN_EMAIL!, process.env.E2E_ADMIN_PASSWORD!);
    await page.goto('/orphan-assignments');
    await expect(page).toHaveURL('/orphan-assignments');
    await expect(page.getByRole('heading', { name: /orphan assignments/i })).toBeVisible();
  });
});
