import { test, expect } from "@playwright/test";

test.describe("FM Compta Consulting Application", () => {
  test("should display the homepage", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/FM Compta Consulting/);
    // The h1 contains French text "La croissance prévisible commence ici"
    await expect(page.locator("h1")).toContainText(
      "La croissance prévisible commence ici",
    );
  });

  test("should open login modal", async ({ page }) => {
    await page.goto("/");
    // Login is a button that opens a modal, not a link
    await page.getByRole("button", { name: /Connexion|Login/i }).click();
    // Check that the modal appears with login form
    await expect(page.locator('input[name="email"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  test("should open registration modal", async ({ page }) => {
    await page.goto("/");
    // First open login modal, then switch to register
    await page.getByRole("button", { name: /Connexion|Login/i }).click();
    // Wait for modal to appear
    await page.waitForSelector('input[name="email"]');
    // Click the switch to register button/link inside the modal
    await page.getByText(/Inscription|Register/i).click();
    // Check that the register form appears
    await expect(page.locator('input[name="name"]')).toBeVisible();
  });

  test("should redirect to home when accessing appointment page without auth", async ({
    page,
  }) => {
    await page.goto("/appointment");
    // Check if redirected to home page (not authenticated)
    await expect(page).toHaveURL(/.*\/$/);
  });

  test("should redirect to home when accessing admin page without auth", async ({
    page,
  }) => {
    await page.goto("/admin");
    // Check if redirected to home page (not authenticated)
    await expect(page).toHaveURL(/.*\/$/);
  });

  test("should display CTA button for appointment", async ({ page }) => {
    await page.goto("/");
    // Check that the main CTA is visible
    await expect(
      page.getByRole("button", {
        name: /Prendre rendez-vous|Book appointment/i,
      }),
    ).toBeVisible();
  });
});
