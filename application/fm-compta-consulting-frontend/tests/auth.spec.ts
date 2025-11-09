import { test, expect } from '@playwright/test';

test.describe('Authentication Tests', () => {
  test('should allow user to register', async ({ page }) => {
    await page.goto('/auth');
    await page.getByRole('link', { name: 'Register' }).click();
    
    // Fill in registration form
    await page.locator('input[name="name"]').fill('Test User');
    await page.locator('input[name="email"]').fill('test@example.com');
    await page.locator('input[name="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    
    // Check for success or redirect to home page
    await expect(page).toHaveURL(/.*\/$/);
  });

  test('should allow user to login', async ({ page }) => {
    await page.goto('/auth');
    await page.getByRole('link', { name: 'Login' }).click();
    
    // Fill in login form
    await page.locator('input[name="email"]').fill('test@example.com');
    await page.locator('input[name="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    
    // Check for successful login redirect
    await expect(page).toHaveURL(/.*\/$/);
  });

  test('should allow user to logout', async ({ page }) => {
    // First login 
    await page.goto('/auth');
    await page.getByRole('link', { name: 'Login' }).click();
    await page.locator('input[name="email"]').fill('test@example.com');
    await page.locator('input[name="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    
    // Then logout
    await page.getByRole('button', { name: 'Logout' }).click();
    
    // Check for redirect after logout
    await expect(page).toHaveURL(/.*\//);
  });
});