#!/bin/bash

###############################################################################
# Allure Project Initialization Script
# ---------------------------------------------------------------------------
# This script ensures that the fm-compta-consulting project exists in Allure
# Docker Service at startup.
###############################################################################

set -euo pipefail

# Configuration
PROJECT_ID="${PROJECT_ID:-fm-compta-consulting}"
ALLURE_API_URL="${ALLURE_API_URL:-http://localhost:5050}"
PROJECT_DIR="/app/allure-docker-api/static/projects/${PROJECT_ID}"
RESULTS_DIR="${PROJECT_DIR}/results"
MAX_RETRIES=30
RETRY_DELAY=2

# Colors for logging
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

# Wait for Allure service to be ready
wait_for_allure() {
    log_info "Waiting for Allure service to be ready..."
    local retry=0

    while [ $retry -lt $MAX_RETRIES ]; do
        if curl -s "${ALLURE_API_URL}/allure-docker-service/version" > /dev/null 2>&1; then
            log_success "Allure service is ready!"
            return 0
        fi

        log_info "Attempt $((retry + 1))/${MAX_RETRIES} - Allure service not ready yet..."
        sleep $RETRY_DELAY
        retry=$((retry + 1))
    done

    log_error "Allure service did not become ready after ${MAX_RETRIES} attempts"
    return 1
}

# Check if project exists
check_project_exists() {
    log_info "Checking if project '${PROJECT_ID}' exists..."

    if [ -d "${PROJECT_DIR}" ]; then
        log_success "Project directory exists: ${PROJECT_DIR}"
        return 0
    else
        log_warn "Project directory does not exist: ${PROJECT_DIR}"
        return 1
    fi
}

# Create project directory structure
create_project() {
    log_info "Creating project '${PROJECT_ID}'..."

    # Create directories
    mkdir -p "${RESULTS_DIR}"
    mkdir -p "${PROJECT_DIR}/reports"

    # Set permissions (run as root to ensure access)
    chmod -R 755 "${PROJECT_DIR}"

    # Create a placeholder file to ensure directory is not empty
    cat > "${RESULTS_DIR}/.gitkeep" << 'EOF'
# This file ensures the results directory is tracked
EOF

    log_success "Project '${PROJECT_ID}' created successfully"
}

# Verify project via API
verify_project_api() {
    log_info "Verifying project '${PROJECT_ID}' via API..."

    local response
    response=$(curl -s "${ALLURE_API_URL}/allure-docker-service/projects" 2>/dev/null || echo "")

    if echo "$response" | grep -q "\"${PROJECT_ID}\""; then
        log_success "Project '${PROJECT_ID}' is accessible via API"
        return 0
    else
        log_warn "Project '${PROJECT_ID}' not yet visible in API"
        return 1
    fi
}

# Create initial empty report
create_initial_report() {
    log_info "Generating initial report for '${PROJECT_ID}'..."

    # Create a minimal test result to generate initial report
    cat > "${RESULTS_DIR}/init-test.json" << EOF
{
  "uuid": "init-$(date +%s)",
  "name": "Initialization Test",
  "fullName": "System Initialization",
  "status": "passed",
  "stage": "finished",
  "description": "This is an initialization test to create the first report for the project.",
  "start": $(date +%s)000,
  "stop": $(date +%s)000,
  "labels": [
    {
      "name": "suite",
      "value": "System"
    },
    {
      "name": "feature",
      "value": "Initialization"
    }
  ]
}
EOF

    # Wait a moment for the file to be written
    sleep 2

    # Try to generate report via API
    local retry=0
    while [ $retry -lt 5 ]; do
        log_info "Attempting to generate report (attempt $((retry + 1))/5)..."

        local response
        response=$(curl -s -X GET "${ALLURE_API_URL}/allure-docker-service/generate-report?project_id=${PROJECT_ID}" 2>/dev/null || echo "")

        if echo "$response" | grep -q "successfully generated"; then
            log_success "Initial report generated successfully"
            return 0
        fi

        sleep 3
        retry=$((retry + 1))
    done

    log_warn "Could not generate initial report via API, will be created on first test upload"
    return 0
}

# Main execution
main() {
    log_info "=========================================="
    log_info "Allure Project Initialization"
    log_info "Project ID: ${PROJECT_ID}"
    log_info "=========================================="

    # Wait for Allure service
    if ! wait_for_allure; then
        log_error "Failed to connect to Allure service"
        exit 1
    fi

    # Check if project exists
    if check_project_exists; then
        log_info "Project already exists, skipping creation"
    else
        # Create project
        create_project

        # Wait a moment for filesystem sync
        sleep 2
    fi

    # Verify via API
    local retry=0
    while [ $retry -lt 10 ]; do
        if verify_project_api; then
            break
        fi
        log_info "Waiting for project to be visible in API..."
        sleep 3
        retry=$((retry + 1))
    done

    # Create initial report
    create_initial_report

    log_success "=========================================="
    log_success "Initialization complete!"
    log_success "Project: ${PROJECT_ID}"
    log_success "Access: ${ALLURE_API_URL}/allure-docker-service/projects/${PROJECT_ID}/reports/latest/index.html"
    log_success "=========================================="
}

# Run main function
main "$@"
