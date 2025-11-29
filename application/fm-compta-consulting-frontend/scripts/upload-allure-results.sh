#!/bin/bash

###############################################################################
# Allure Results Upload Script
# ---------------------------------------------------------------------------
# Uploads Playwright test results to Allure Dashboard via API
###############################################################################

set -euo pipefail

# Configuration
ALLURE_SERVER="${ALLURE_SERVER_URL:-https://allure.local}"
ALLURE_RESULTS_DIR="${ALLURE_RESULTS_DIR:-./allure-results}"
PROJECT_ID="${ALLURE_PROJECT_ID:-fm-compta-consulting}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if allure-results directory exists
if [ ! -d "$ALLURE_RESULTS_DIR" ]; then
    log_error "Allure results directory not found: $ALLURE_RESULTS_DIR"
    exit 1
fi

# Check if directory contains files
if [ -z "$(ls -A $ALLURE_RESULTS_DIR)" ]; then
    log_warn "Allure results directory is empty. No results to upload."
    exit 0
fi

log_info "Uploading Allure results to $ALLURE_SERVER"
log_info "Project ID: $PROJECT_ID"
log_info "Results directory: $ALLURE_RESULTS_DIR"

# Count result files
RESULT_COUNT=$(find "$ALLURE_RESULTS_DIR" -type f -name "*.json" | wc -l)
log_info "Found $RESULT_COUNT JSON result files"

# Create a temporary archive
TEMP_ARCHIVE="/tmp/allure-results-$(date +%s).tar.gz"
log_info "Creating temporary archive: $TEMP_ARCHIVE"

tar -czf "$TEMP_ARCHIVE" -C "$ALLURE_RESULTS_DIR" .

if [ ! -f "$TEMP_ARCHIVE" ]; then
    log_error "Failed to create archive"
    exit 1
fi

ARCHIVE_SIZE=$(du -h "$TEMP_ARCHIVE" | cut -f1)
log_info "Archive size: $ARCHIVE_SIZE"

# Upload to Allure server
# The frankescobar/allure-docker-service uses this API endpoint
log_info "Uploading to Allure Dashboard..."

# Upload results using multipart/form-data
UPLOAD_RESPONSE=$(curl -k -s -w "\n%{http_code}" \
    -X POST "${ALLURE_SERVER}/allure-docker-service/send-results?project_id=${PROJECT_ID}" \
    -H "Content-Type: multipart/form-data" \
    -F "files[]=@${TEMP_ARCHIVE}" 2>&1) || {
    log_error "Upload failed"
    rm -f "$TEMP_ARCHIVE"
    exit 1
}

# Extract HTTP code (last line)
HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$UPLOAD_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    log_success "Upload successful (HTTP $HTTP_CODE)"

    # Trigger report generation
    log_info "Generating report..."
    GENERATE_RESPONSE=$(curl -k -s -w "\n%{http_code}" \
        -X GET "${ALLURE_SERVER}/allure-docker-service/generate-report?project_id=${PROJECT_ID}" 2>&1)

    GEN_HTTP_CODE=$(echo "$GENERATE_RESPONSE" | tail -n 1)

    if [ "$GEN_HTTP_CODE" -eq 200 ]; then
        log_success "Report generated successfully"
        REPORT_URL="${ALLURE_SERVER}/allure-docker-service/projects/${PROJECT_ID}/reports/latest/index.html"
        log_info "View report at: ${REPORT_URL}"
        
        # Print for CI visibility
        echo "::notice title=Allure Report::View the test report at ${REPORT_URL}"
    else
        log_warn "Report generation returned HTTP $GEN_HTTP_CODE"
    fi
else
    log_error "Upload failed with HTTP $HTTP_CODE"
    log_error "Response: $RESPONSE_BODY"
    rm -f "$TEMP_ARCHIVE"
    exit 1
fi

# Cleanup
rm -f "$TEMP_ARCHIVE"
log_success "Cleanup completed"

log_success "✅ Allure results uploaded successfully!"
log_info "Dashboard URL: ${ALLURE_SERVER}"
log_info "Project: ${PROJECT_ID}"

exit 0
