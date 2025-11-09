import { test, expect } from '@playwright/test';

test.describe('Appointment Tests', () => {
  test('should allow creating a new appointment', async ({ page }) => {
    // First login to access appointment features
    await page.goto('/auth');
    await page.getByRole('link', { name: 'Login' }).click();
    await page.locator('input[name="email"]').fill('admin@example.com');
    await page.locator('input[name="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    
    // Navigate to appointment creation
    await page.goto('/appointment/new');
    
    // Fill in appointment details (adjust selectors based on actual form elements)
    await page.locator('input[name="title"]').fill('Test Appointment');
    await page.locator('input[name="description"]').fill('This is a test appointment');
    await page.locator('input[name="date"]').fill('2025-01-01');
    await page.locator('input[name="time"]').fill('10:00');
    await page.locator('input[name="client"]').fill('Test Client');
    
    await page.locator('button[type="submit"]').click();
    
    // Verify appointment was created
    await expect(page.locator('text="Appointment created successfully"')).toBeVisible();
  });

  test('should display appointments list', async ({ page }) => {
    // First login 
    await page.goto('/auth');
    await page.getByRole('link', { name: 'Login' }).click();
    await page.locator('input[name="email"]').fill('admin@example.com');
    await page.locator('input[name="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    
    // Navigate to appointments list
    await page.goto('/appointment');
    
    // Verify appointments are displayed
    await expect(page.locator('.appointment-item')).toBeVisible();
  });
  
  test('should allow editing an appointment', async ({ page }) => {
    // First login 
    await page.goto('/auth');
    await page.getByRole('link', { name: 'Login' }).click();
    await page.locator('input[name="email"]').fill('admin@example.com');
    await page.locator('input[name="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    
    // Navigate to edit an appointment (assuming first appointment)
    await page.goto('/appointment/edit/1');
    
    // Modify appointment details
    await page.locator('input[name="title"]').fill('Updated Appointment');
    await page.locator('button[type="submit"]').click();
    
    // Verify update was successful
    await expect(page.locator('text="Appointment updated successfully"')).toBeVisible();
  });
});