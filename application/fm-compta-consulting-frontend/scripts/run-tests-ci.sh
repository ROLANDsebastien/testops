#!/usr/bin/env bash

###############################################################################
# Playwright CI Test Runner
# ---------------------------------------------------------------------------
# This script performs a sequence of pre-flight checks before executing the
# Playwright test suite. It guarantees that report artifacts are produced
# even when the application is unreachable or the tests crash partway through.
###############################################################################

set -euo pipefail

#------------------------------------------------------------------------------
# Path Resolution
#------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

#------------------------------------------------------------------------------
# Globals
#------------------------------------------------------------------------------
REPORT_DIR="${PROJECT_ROOT}/playwright-report"
RESULTS_DIR="${PROJECT_ROOT}/test-results"
ALLURE_RESULTS_DIR="${PROJECT_ROOT}/allure-results"
SUMMARY_FILE="${RESULTS_DIR}/summary.txt"
SKIPPED_HTML="${REPORT_DIR}/SKIPPED.html"

PLAYWRIGHT_CMD=(npx playwright test --workers=1 --project=chromium --max-failures=20)

DEFAULT_BASE_URL="https://fm-compta-consulting.local"
APP_URL="${PLAYWRIGHT_BASE_URL:-$DEFAULT_BASE_URL}"
MAX_ACCESS_RETRIES="${PLAYWRIGHT_ACCESS_RETRIES:-3}"
RETRY_WAIT_SECONDS="${PLAYWRIGHT_ACCESS_WAIT_SECONDS:-5}"
CI_MODE=true

# Exit codes
EXIT_OK=0
EXIT_ENV=1
EXIT_ACCESS=2
EXIT_TESTS=3

#------------------------------------------------------------------------------
# Logging Helpers
#------------------------------------------------------------------------------
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
NC=$'\033[0m'

log_section()  { printf "\n${BLUE}[%s]${NC} %s\n"   "$(date -u '+%H:%M:%S')" "$1"; }
log_info()     { printf "  ${BLUE}ℹ${NC} %s\n"  "$1"; }
log_success()  { printf "  ${GREEN}✔${NC} %s\n" "$1"; }
log_warn()     { printf "  ${YELLOW}⚠${NC} %s\n" "$1"; }
log_error()    { printf "  ${RED}✖${NC} %s\n"   "$1"; }

#------------------------------------------------------------------------------
# Cleanup & Artifact Guarantees
#------------------------------------------------------------------------------
create_artifact_skeleton() {
  rm -rf "${REPORT_DIR}" "${RESULTS_DIR}" "${ALLURE_RESULTS_DIR}"
  mkdir -p "${REPORT_DIR}" "${RESULTS_DIR}" "${ALLURE_RESULTS_DIR}"
}

write_summary() {
  cat <<EOF > "${SUMMARY_FILE}"
Playwright CI Summary
---------------------
Timestamp (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')
Working Directory: ${PROJECT_ROOT}
Application URL: ${APP_URL}
Exit Code: ${1}
EOF
}

write_skipped_report() {
  cat <<EOF > "${SKIPPED_HTML}"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Playwright Tests Skipped</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #f6f7fb; margin: 40px; }
    .card { max-width: 640px; margin: 0 auto; background: #fff; padding: 32px;
            border-radius: 10px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); }
    h1 { color: #c0392b; }
    p { line-height: 1.5; }
    .meta { margin-top: 20px; padding: 16px; background: #fef9e7; border-left: 4px solid #f1c40f; }
    code { background: #f4f6f8; padding: 2px 4px; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>⚠️ Playwright Tests Skipped</h1>
    <p>The Playwright end-to-end suite did not run because the target application
       was unreachable from the CI runner.</p>
    <div class="meta">
      <p><strong>Requested URL:</strong> ${APP_URL}</p>
      <p><strong>Retries attempted:</strong> ${MAX_ACCESS_RETRIES}</p>
      <p><strong>Wait between retries:</strong> ${RETRY_WAIT_SECONDS}s</p>
      <p><strong>Timestamp (UTC):</strong> $(date -u '+%Y-%m-%d %H:%M:%S')</p>
    </div>
    <p>Please verify that the application has been deployed successfully and is accessible
       from within the CI cluster before re-running the tests.</p>
    <p>Command executed from <code>${PROJECT_ROOT}</code> by CI user.</p>
  </div>
</body>
</html>
EOF
}

write_allure_skip_result() {
  local reason="${1:-Application ${APP_URL} unreachable from CI runner.}"
  export APP_URL MAX_ACCESS_RETRIES CI_MODE ALLURE_RESULTS_DIR
  ALLURE_SKIP_REASON="${reason}" python3 - <<'PYCODE'
import json, os, time, pathlib

timestamp = int(time.time() * 1000)
payload = {
    "uuid": f"playwright-skip-{timestamp}",
    "name": "Playwright suite",
    "historyId": "playwright-suite",
    "fullName": "Playwright suite - CI gate",
    "status": "skipped",
    "statusDetails": {
        "message": os.environ.get("ALLURE_SKIP_REASON", "Playwright suite skipped."),
        "trace": f"HTTP checks exhausted after {os.environ['MAX_ACCESS_RETRIES']} attempts."
    },
    "stage": "finished",
    "labels": [
        {"name": "feature", "value": "playwright-smoke"},
        {"name": "suite", "value": "ci"}
    ],
    "parameters": [
        {"name": "baseURL", "value": os.environ["APP_URL"]},
        {"name": "ci-mode", "value": os.environ["CI_MODE"]}
    ],
    "start": timestamp,
    "stop": timestamp
}

output_dir = pathlib.Path(os.environ["ALLURE_RESULTS_DIR"])
output_dir.mkdir(parents=True, exist_ok=True)
dest = output_dir / f"playwright-skip-{timestamp}.json"
with dest.open("w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
print(f"[allure-skip] wrote {dest}")
PYCODE
}

ensure_html_placeholder() {
  if ! find "${REPORT_DIR}" -maxdepth 1 -type f -name "*.html" -print -quit >/dev/null; then
    cat <<'EOF' > "${REPORT_DIR}/PLAYWRIGHT_PLACEHOLDER.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Playwright Report Placeholder</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 40px; background: #f6f7fb; }
    .card { max-width: 640px; margin: 0 auto; background: #fff; padding: 32px;
            border-radius: 10px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
    h1 { color: #2c3e50; }
    pre { background: #f4f6f8; padding: 16px; border-radius: 6px; overflow-x: auto; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Playwright Report Placeholder</h1>
    <p>No official Playwright HTML report was generated. Refer to the CI job logs
       for details about the failure.</p>
  </div>
</body>
</html>
EOF
  fi
}

ensure_results_placeholder() {
  if ! find "${RESULTS_DIR}" -maxdepth 1 -type f -print -quit >/dev/null; then
    cat <<'EOF' > "${RESULTS_DIR}/PLAYWRIGHT_RESULTS_PLACEHOLDER.txt"
No Playwright result files were produced. Consult the CI logs to determine why
test execution did not reach the reporting stage.
EOF
  fi
}

ensure_allure_placeholder() {
  if ! find "${ALLURE_RESULTS_DIR}" -maxdepth 1 -type f -print -quit >/dev/null; then
    cat <<'EOF' > "${ALLURE_RESULTS_DIR}/ALLURE_RESULTS_PLACEHOLDER.txt"
No Allure result files or skip markers were produced. Ensure the Playwright Allure reporter
is enabled and that either tests run to completion or the skip helper executes.
EOF
  fi
}

finalise_artifacts() {
  local exit_code="$1"
  write_summary "${exit_code}"
  ensure_html_placeholder
  ensure_results_placeholder
  ensure_allure_placeholder
}

#------------------------------------------------------------------------------
# Environment Validation
#------------------------------------------------------------------------------
require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    log_error "Required command '${cmd}' is not installed or not on PATH."
    exit "${EXIT_ENV}"
  fi
}

check_node_environment() {
  require_command node
  require_command npm
  require_command npx
  log_success "Node.js $(node --version) detected."
  log_success "npm $(npm --version) detected."
}

check_project_layout() {
  if [[ ! -f package.json ]]; then
    log_error "package.json not found at ${PROJECT_ROOT}"
    exit "${EXIT_ENV}"
  fi
  if [[ ! -f playwright.config.ts ]]; then
    log_error "playwright.config.ts not found at ${PROJECT_ROOT}"
    exit "${EXIT_ENV}"
  fi
  if [[ ! -d tests ]]; then
    log_error "tests directory not found at ${PROJECT_ROOT}"
    exit "${EXIT_ENV}"
  fi
  log_success "Project layout verified."
}

check_dependencies() {
  if [[ ! -d node_modules ]]; then
    log_error "node_modules directory missing. Run 'npm ci' before invoking this script."
    exit "${EXIT_ENV}"
  fi
  if [[ ! -d node_modules/@playwright/test ]]; then
    log_error "@playwright/test package not found in node_modules."
    exit "${EXIT_ENV}"
  fi
  log_success "Dependencies present."
}

check_browsers() {
  local browsers_path="${PLAYWRIGHT_BROWSERS_PATH:-${HOME}/.cache/ms-playwright}"
  log_info "Checking Playwright browsers in: ${browsers_path}"
  if [[ ! -d "${browsers_path}" ]]; then
    log_error "Browser cache directory missing (${browsers_path}). Run 'npx playwright install chromium'."
    exit "${EXIT_ENV}"
  fi
  if ! compgen -G "${browsers_path}/chromium-*" >/dev/null; then
    log_error "Chromium browser not installed in cache. Run 'npx playwright install chromium'."
    exit "${EXIT_ENV}"
  fi
  log_success "Chromium browser installation verified."
}

#------------------------------------------------------------------------------
# Application Accessibility Check
#------------------------------------------------------------------------------
check_application_access() {
  log_info "Target application URL: ${APP_URL}"
  local attempt=1
  while (( attempt <= MAX_ACCESS_RETRIES )); do
    local http_code
    http_code="$(curl -k -s -o /dev/null -w "%{http_code}" "${APP_URL}" || echo "000")"
    if [[ "${http_code}" =~ ^(200|301|302)$ ]]; then
      log_success "Application is reachable (HTTP ${http_code})."
      return 0
    fi
    log_warn "Attempt ${attempt}/${MAX_ACCESS_RETRIES}: received HTTP ${http_code}."
    if (( attempt < MAX_ACCESS_RETRIES )); then
      sleep "${RETRY_WAIT_SECONDS}"
    fi
    ((attempt++))
  done
  log_error "Application is not accessible after ${MAX_ACCESS_RETRIES} attempts."
  return 1
}

#------------------------------------------------------------------------------
# Playwright Execution
#------------------------------------------------------------------------------
run_playwright_suite() {
  log_info "Executing: ${PLAYWRIGHT_CMD[*]}"
  local exit_code=0

  # Run Playwright allowing failure capture
  set +e
  CI="${CI_MODE}" "${PLAYWRIGHT_CMD[@]}"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    log_success "Playwright suite completed successfully."
  else
    log_warn "Playwright suite exited with status ${exit_code}."
  fi

  # Verify Allure results generation
  if [ -d "${ALLURE_RESULTS_DIR}" ]; then
    local count=$(find "${ALLURE_RESULTS_DIR}" -type f | wc -l)
    log_info "Generated ${count} files in ${ALLURE_RESULTS_DIR}"
    if (( count == 0 )); then
      log_warn "No Allure results found! Check playwright.config.ts reporter settings."
    fi
  else
    log_error "Allure results directory missing: ${ALLURE_RESULTS_DIR}"
  fi

  return "${exit_code}"
}

#------------------------------------------------------------------------------
# Main Flow
#------------------------------------------------------------------------------
main() {
  log_section "Initialising artifact directories"
  create_artifact_skeleton

  log_section "Validating environment"
  check_node_environment
  check_project_layout
  check_dependencies
  check_browsers

  log_section "Checking application accessibility"
  if ! check_application_access; then
    log_warn "Generating skipped-test artifact bundle."
    write_skipped_report
    write_allure_skip_result "Application ${APP_URL} unreachable from CI runner after ${MAX_ACCESS_RETRIES} attempts."
    log_info "Allure skip artifact stored in ${ALLURE_RESULTS_DIR}"
    finalise_artifacts "${EXIT_ACCESS}"
    exit "${EXIT_ACCESS}"
  fi

  log_section "Running Playwright end-to-end suite"
  local test_exit_code
  test_exit_code="${EXIT_TESTS}"
  if run_playwright_suite; then
    test_exit_code="${EXIT_OK}"
  else
    test_exit_code="${EXIT_TESTS}"
  fi

  log_section "Finalising artifacts"
  finalise_artifacts "${test_exit_code}"

  if (( test_exit_code == EXIT_OK )); then
    log_section "All tests passed"
    exit "${EXIT_OK}"
  fi

  log_section "Tests failed"
  exit "${test_exit_code}"
}

main "$@"
