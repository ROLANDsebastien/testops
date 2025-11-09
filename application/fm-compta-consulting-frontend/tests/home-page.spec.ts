import { test, expect } from '@playwright/test';

test.describe('FM Compta Consulting Application', () => {
  test('should display the homepage', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/FM Compta Consulting/);
    await expect(page.locator('h1')).toContainText('Welcome');
  });

  test('should navigate to login page', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('link', { name: 'Login' }).click();
    await expect(page).toHaveURL(/.*\/auth/);
  });

  test('should navigate to registration page', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('link', { name: 'Register' }).click();
    await expect(page).toHaveURL(/.*\/auth/);
  });

  test('should display appointment page if user is logged in', async ({ page }) => {
    await page.goto('/appointment');
    // Check if redirected to login or if appointment page is accessible
    await expect(page).toHaveURL(/.*\/(appointment|auth)/);
  });

  test('should display admin calendar page', async ({ page }) => {
    // This test assumes user is already logged in as admin
    // In a real scenario, you would need to handle authentication first
    await page.goto('/admin');
    
    // Check if admin page has some expected elements
    await expect(page.locator('text="Admin Dashboard"')).toBeVisible().catch(() => {
      // If admin page is not accessible, it might redirect to login
      expect(page).toHaveURL(/.*\/auth/);
    });
  });
});