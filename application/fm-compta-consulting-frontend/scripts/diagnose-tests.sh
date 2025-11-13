#!/bin/bash

# Playwright Test Diagnostics Script
# This script helps diagnose issues with Playwright test setup

set -e

echo "========================================="
echo "Playwright Test Diagnostics"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info
print_info() {
    echo -e "ℹ $1"
}

echo "1. Checking Node.js and npm..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_status 0 "Node.js installed: $NODE_VERSION"
else
    print_status 1 "Node.js not found"
    exit 1
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_status 0 "npm installed: $NPM_VERSION"
else
    print_status 1 "npm not found"
    exit 1
fi
echo ""

echo "2. Checking if we're in the frontend directory..."
if [ -f "package.json" ] && grep -q "playwright" package.json; then
    print_status 0 "Found package.json with Playwright"
else
    print_status 1 "Not in frontend directory or Playwright not in package.json"
    print_warning "Run this script from application/fm-compta-consulting-frontend/"
    exit 1
fi
echo ""

echo "3. Checking dependencies..."
if [ -d "node_modules" ]; then
    print_status 0 "node_modules directory exists"
else
    print_status 1 "node_modules not found"
    print_warning "Run: npm ci"
fi

if [ -d "node_modules/@playwright" ]; then
    print_status 0 "Playwright package installed"
else
    print_status 1 "Playwright not installed"
    print_warning "Run: npm ci"
fi
echo ""

echo "4. Checking Playwright browsers..."
if command -v npx &> /dev/null; then
    print_status 0 "npx available"

    # Check browser installation
    BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
    print_info "Checking browsers in: $BROWSERS_PATH"

    if [ -d "$BROWSERS_PATH" ]; then
        print_status 0 "Browser cache directory exists"

        if [ -d "$BROWSERS_PATH/chromium-"* ] 2>/dev/null; then
            print_status 0 "Chromium browser found"
        else
            print_status 1 "Chromium browser not found"
            print_warning "Run: npx playwright install chromium"
        fi
    else
        print_status 1 "Browser cache directory not found"
        print_warning "Run: npx playwright install chromium"
    fi
else
    print_status 1 "npx not available"
fi
echo ""

echo "5. Checking Playwright configuration..."
if [ -f "playwright.config.ts" ]; then
    print_status 0 "playwright.config.ts exists"

    # Check base URL
    BASE_URL=$(grep -oP "baseURL.*['\"].*?['\"]" playwright.config.ts | head -1 || echo "")
    if [ -n "$BASE_URL" ]; then
        print_info "Base URL in config: $BASE_URL"
    fi
else
    print_status 1 "playwright.config.ts not found"
fi
echo ""

echo "6. Checking test files..."
if [ -d "tests" ]; then
    print_status 0 "tests directory exists"

    TEST_COUNT=$(find tests -name "*.spec.ts" | wc -l)
    print_info "Found $TEST_COUNT test file(s)"

    find tests -name "*.spec.ts" -exec echo "  - {}" \;
else
    print_status 1 "tests directory not found"
fi
echo ""

echo "7. Checking application accessibility..."
APP_URL="${PLAYWRIGHT_BASE_URL:-https://fm-compta-consulting.local}"
print_info "Testing: $APP_URL"

if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "$APP_URL" 2>&1 || echo "000")

    if echo "$HTTP_CODE" | grep -qE "^[23][0-9][0-9]$"; then
        print_status 0 "Application accessible (HTTP $HTTP_CODE)"
    else
        print_status 1 "Application not accessible (HTTP $HTTP_CODE)"
        print_warning "Make sure the application is running at $APP_URL"
    fi
else
    print_warning "curl not available, cannot check application"
fi
echo ""

echo "8. Environment variables..."
print_info "PLAYWRIGHT_BASE_URL: ${PLAYWRIGHT_BASE_URL:-not set (will use config default)}"
print_info "PLAYWRIGHT_BROWSERS_PATH: ${PLAYWRIGHT_BROWSERS_PATH:-not set (will use default)}"
print_info "CI: ${CI:-not set}"
echo ""

echo "9. Checking previous test runs..."
if [ -d "playwright-report" ]; then
    print_status 0 "playwright-report directory exists"
    REPORT_SIZE=$(du -sh playwright-report 2>/dev/null | cut -f1 || echo "unknown")
    print_info "Report size: $REPORT_SIZE"
else
    print_info "No previous playwright-report found"
fi

if [ -d "test-results" ]; then
    print_status 0 "test-results directory exists"
    RESULTS_COUNT=$(find test-results -name "*.xml" 2>/dev/null | wc -l)
    print_info "Found $RESULTS_COUNT result file(s)"
else
    print_info "No previous test-results found"
fi
echo ""

echo "========================================="
echo "Diagnostics Complete"
echo "========================================="
echo ""

echo "To run tests:"
echo "  export PLAYWRIGHT_BASE_URL=https://fm-compta-consulting.local"
echo "  npm run test"
echo ""
echo "To run tests in UI mode:"
echo "  npx playwright test --ui"
echo ""
echo "To view last report:"
echo "  npx playwright show-report"
echo ""
