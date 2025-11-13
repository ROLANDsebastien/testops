# Playwright Tests - Quick Start Guide

## Prerequisites

1. **Node.js and npm installed**
2. **Application running** at the configured base URL
3. **Playwright browsers installed**

## Setup

### Install dependencies (if not already done):
```bash
npm install
```

### Install Playwright browsers:
```bash
npx playwright install chromium
```

Or install all browsers (for local development):
```bash
npx playwright install
```

## Running Tests

### Run all tests:
```bash
npm run test
```

### Run tests in UI mode (interactive):
```bash
npx playwright test --ui
```

### Run specific test file:
```bash
npx playwright test tests/home-page.spec.ts
```

### Run tests in headed mode (see browser):
```bash
npx playwright test --headed
```

### Run tests with specific browser:
```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
```

### Run in debug mode:
```bash
npx playwright test --debug
```

## Environment Configuration

### Set base URL (if different from default):
```bash
export PLAYWRIGHT_BASE_URL=https://fm-compta-consulting.local
npm run test
```

### For CI environment:
```bash
export CI=true
export PLAYWRIGHT_BASE_URL=https://fm-compta-consulting.local
npm run test
```

## Viewing Test Reports

### HTML Report (after test run):
```bash
npx playwright show-report
```

The HTML report is also generated in `playwright-report/` directory.

### JUnit XML Report:
Located at `test-results/junit.xml` (for CI integration).

## Test Structure

```
tests/
├── home-page.spec.ts      # Homepage and navigation tests
├── auth.spec.ts           # Authentication (login/register) tests
├── appointment.spec.ts    # Appointment feature tests
├── TEST_FIXES.md          # Detailed documentation of fixes
└── QUICK_START.md         # This file
```

## Common Issues & Solutions

### Issue: "Timeout waiting for element"
**Solution**: 
- Ensure application is running at the correct URL
- Check if element selectors match the actual DOM
- Increase timeout in playwright.config.ts if needed

### Issue: "Browser not found"
**Solution**:
```bash
npx playwright install chromium
```

### Issue: "Connection refused"
**Solution**:
- Verify application is running: `curl http://localhost:3000` or your base URL
- Check PLAYWRIGHT_BASE_URL environment variable
- Ensure no firewall blocking connections

### Issue: Tests fail on modal interactions
**Solution**:
- The application uses modals for Login/Register, not separate pages
- Use button selectors, not link selectors
- Add waits for modal elements: `await page.waitForSelector(...)`

## Test Credentials

Default test credentials used in specs:
- **Email**: `admin@example.com`
- **Password**: `password123`

Ensure these credentials exist in your test database/backend.

## CI/CD Integration

The tests are configured to run in GitHub Actions. See `.github/workflows/` for pipeline configuration.

### CI Environment Variables:
- `CI=true` - Enables CI-specific configuration
- `PLAYWRIGHT_BASE_URL` - Application URL to test against

### CI Optimizations:
- Runs only Chromium browser (faster)
- 2 automatic retries on failure
- Single worker (no parallelization)
- Ignores HTTPS errors (for self-signed certificates)

## Tips for Writing New Tests

1. **Use flexible selectors**: Prefer `getByRole`, `getByText` with regex for i18n
2. **Wait for elements**: Use `waitForSelector` or `waitForTimeout` when needed
3. **Support multiple languages**: Use regex patterns like `/Connexion|Login/i`
4. **Handle redirects gracefully**: Check for valid outcomes, not exact URLs
5. **Add debug logging**: Use `console.log` or `page.screenshot()` for troubleshooting

## Example Test Pattern

```typescript
test('my new test', async ({ page }) => {
  // Navigate
  await page.goto('/');
  
  // Wait for element
  await page.waitForSelector('button[name="submit"]');
  
  // Interact
  await page.getByRole('button', { name: /Submit/i }).click();
  
  // Assert
  await expect(page.locator('.success-message')).toBeVisible();
});
```

## Useful Commands Cheat Sheet

| Command | Description |
|---------|-------------|
| `npm run test` | Run all tests |
| `npx playwright test --ui` | Interactive mode |
| `npx playwright test --headed` | See browser while testing |
| `npx playwright test --debug` | Debug mode with step-through |
| `npx playwright show-report` | View HTML report |
| `npx playwright codegen` | Generate test code by recording |
| `npx playwright test --grep "login"` | Run tests matching pattern |
| `npx playwright test --project=chromium` | Run specific browser |

## Resources

- [Playwright Documentation](https://playwright.dev/)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [Selectors Guide](https://playwright.dev/docs/selectors)
- [Test Fixtures Documentation](TEST_FIXES.md)