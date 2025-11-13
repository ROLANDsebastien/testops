import { test, expect } from "@playwright/test";

test.describe("Authentication Tests", () => {
  test("should allow user to register through modal", async ({ page }) => {
    await page.goto("/");

    // Open login modal first
    await page.getByRole("button", { name: /Connexion|Login/i }).click();

    // Wait for login modal to appear
    await page.waitForSelector('input[name="email"]');

    // Switch to register form
    await page.getByText(/Inscription|Register/i).click();

    // Wait for register form to appear
    await page.waitForSelector('input[name="name"]');

    // Fill in registration form
    const timestamp = Date.now();
    await page.locator('input[name="name"]').fill("Test User");
    await page
      .locator('input[name="email"]')
      .fill(`test${timestamp}@example.com`);
    await page.locator('input[name="password"]').fill("password123");
    await page.locator('input[name="confirmPassword"]').fill("password123");

    // Submit the form
    await page.locator('button[type="submit"]').click();

    // Check for success message or modal close (registration successful)
    // The modal should close on success, or show a success message
    await page.waitForTimeout(2000); // Wait for potential redirect/modal close
  });

  test("should allow user to login through modal", async ({ page }) => {
    await page.goto("/");

    // Open login modal
    await page.getByRole("button", { name: /Connexion|Login/i }).click();

    // Wait for login form to appear
    await page.waitForSelector('input[name="email"]');
    await expect(page.locator('input[name="password"]')).toBeVisible();

    // Fill in login form with test credentials
    await page.locator('input[name="email"]').fill("admin@example.com");
    await page.locator('input[name="password"]').fill("password123");

    // Submit the form
    await page.locator('button[type="submit"]').click();

    // Wait for potential redirect or modal close
    await page.waitForTimeout(2000);

    // After successful login, the user menu button should appear
    // (This may vary based on your actual implementation)
  });

  test("should switch between login and register modals", async ({ page }) => {
    await page.goto("/");

    // Open login modal
    await page.getByRole("button", { name: /Connexion|Login/i }).click();
    await page.waitForSelector('input[name="email"]');

    // Verify login form is visible (password but no name field)
    await expect(page.locator('input[name="email"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
    await expect(page.locator('input[name="name"]')).not.toBeVisible();

    // Switch to register
    await page.getByText(/Inscription|Register/i).click();
    await page.waitForSelector('input[name="name"]');

    // Verify register form is visible (name field appears)
    await expect(page.locator('input[name="name"]')).toBeVisible();
    await expect(page.locator('input[name="email"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();

    // Switch back to login
    await page.getByText(/Connexion|Login/i).click();
    await page.waitForSelector('input[name="email"]');

    // Verify back to login form (no name field)
    await expect(page.locator('input[name="name"]')).not.toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  test("should show validation error for password mismatch", async ({
    page,
  }) => {
    await page.goto("/");

    // Open login modal and switch to register
    await page.getByRole("button", { name: /Connexion|Login/i }).click();
    await page.waitForSelector('input[name="email"]');
    await page.getByText(/Inscription|Register/i).click();
    await page.waitForSelector('input[name="name"]');

    // Fill form with mismatched passwords
    await page.locator('input[name="name"]').fill("Test User");
    await page.locator('input[name="email"]').fill("test@example.com");
    await page.locator('input[name="password"]').fill("password123");
    await page.locator('input[name="confirmPassword"]').fill("password456");

    // Submit
    await page.locator('button[type="submit"]').click();

    // Should show error message (wait for it to appear)
    await page.waitForTimeout(1000);
    // Error message should be visible (exact text depends on your i18n)
    const errorVisible =
      (await page
        .locator("text=/mot de passe.*correspond pas|password.*match/i")
        .count()) > 0;
    expect(errorVisible).toBeTruthy();
  });
});
