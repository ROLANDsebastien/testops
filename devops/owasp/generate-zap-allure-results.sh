#!/usr/bin/env bash

###############################################################################
# generate-zap-allure-results.sh
# ---------------------------------------------------------------------------
# Converts an OWASP ZAP HTML report into a minimal Allure results bundle so
# that ZAP findings appear alongside Playwright runs in https://allure.local.
###############################################################################

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
ZAP_REPORT_FILE="${ZAP_REPORT_FILE:-zap-report.html}"
ALLURE_RESULTS_DIR="${ALLURE_RESULTS_DIR:-./allure-results}"
ALLURE_PROJECT_ID="${ALLURE_PROJECT_ID:-owasp-zap}"
SCAN_TARGET="${SCAN_TARGET:-https://fm-compta-consulting.local}"
SCAN_NAME="${SCAN_NAME:-OWASP ZAP Baseline}"
SCANNER_VERSION="${SCANNER_VERSION:-unknown}"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  log "ERROR: $*"
  exit 1
}

require_file() {
  local file="$1"
  [[ -f "$file" ]] || fail "File not found: $file"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  log "Generating Allure results for OWASP ZAP"
  require_file "$ZAP_REPORT_FILE"

  mkdir -p "$ALLURE_RESULTS_DIR"

  local high medium low info_count summary
  high="$(grep -oi 'High' "$ZAP_REPORT_FILE" | wc -l | tr -d ' ')"
  medium="$(grep -oi 'Medium' "$ZAP_REPORT_FILE" | wc -l | tr -d ' ')"
  low="$(grep -oi 'Low' "$ZAP_REPORT_FILE" | wc -l | tr -d ' ')"
  info_count="$(grep -oi 'Informational' "$ZAP_REPORT_FILE" | wc -l | tr -d ' ')"
  summary=$'High: '"${high}"$' | Medium: '"${medium}"$' | Low: '"${low}"$' | Informational: '"${info_count}"

  local status="passed"
  local severity_label="informational"
  if [ "$high" -gt 0 ]; then
    status="failed"
    severity_label="high"
  elif [ "$medium" -gt 0 ]; then
    status="failed"
    severity_label="medium"
  elif [ "$low" -gt 0 ]; then
    status="failed"
    severity_label="low"
  else
    severity_label="informational"
  fi

  local timestamp uuid json_path container_uuid container_path
  timestamp="$(date +%s%3N)"
  uuid="zap-${timestamp}"
  container_uuid="${uuid}-container"
  json_path="${ALLURE_RESULTS_DIR}/${uuid}-result.json"
  container_path="${ALLURE_RESULTS_DIR}/${container_uuid}.json"

  cat > "$json_path" <<EOF
{
  "uuid": "${uuid}",
  "name": "${SCAN_NAME}",
  "fullName": "Security Scan - ${SCAN_TARGET}",
  "historyId": "${SCAN_TARGET}",
  "status": "${status}",
  "stage": "finished",
  "statusDetails": {
    "message": "Alert summary — ${summary}",
    "trace": "Report source: ${ZAP_REPORT_FILE}"
  },
  "description": "OWASP ZAP baseline scan summary. Full HTML report attached. ${summary}",
  "labels": [
    { "name": "feature", "value": "security" },
    { "name": "suite", "value": "owasp-zap" },
    { "name": "severity", "value": "${severity_label}" },
    { "name": "framework", "value": "owasp zap" },
    { "name": "zap-version", "value": "${SCANNER_VERSION}" }
  ],
  "parameters": [
    { "name": "target", "value": "${SCAN_TARGET}" },
    { "name": "project", "value": "${ALLURE_PROJECT_ID}" }
  ],
  "attachments": [
    {
      "name": "OWASP ZAP HTML report",
      "source": "${uuid}-report.html",
      "type": "text/html"
    }
  ],
  "start": ${timestamp},
  "stop": ${timestamp}
}
EOF

  cp "$ZAP_REPORT_FILE" "${ALLURE_RESULTS_DIR}/${uuid}-report.html"

  cat > "$container_path" <<EOF
{
  "uuid": "${container_uuid}",
  "name": "OWASP ZAP Security Scan",
  "children": ["${uuid}"],
  "befores": [],
  "afters": [],
  "links": [
    {
      "name": "Target",
      "type": "link",
      "url": "${SCAN_TARGET}"
    }
  ]
}
EOF

  log "Allure artifact created:"
  log " - Result JSON: ${json_path}"
  log " - HTML report: ${ALLURE_RESULTS_DIR}/${uuid}-report.html"
  log " - Container JSON: ${container_path}"
}

main "$@"
