#!/bin/bash

# Simple script to upload test results to Allure Dashboard
# This is a basic implementation - in practice, you'd use a real API or file upload method

ALLURE_SERVER_URL="${ALLURE_SERVER_URL:-http://allure.local}"
RESULTS_DIR="${RESULTS_DIR:-./test-results}"
REPORTS_DIR="${REPORTS_DIR:-./allure-reports}"

echo "Uploading test results to Allure Dashboard..."

# Create an archive of test results
if [ -d "$RESULTS_DIR" ]; then
  echo "Creating archive of test results from $RESULTS_DIR"
  tar -czf allure-results.tar.gz -C "$RESULTS_DIR" .
  
  # In a real environment, you'd upload using curl to the Allure server
  # For now, we'll just copy to a local directory as an example
  if [ -d "$REPORTS_DIR" ]; then
    cp allure-results.tar.gz "$REPORTS_DIR"/
    echo "Results copied to $REPORTS_DIR"
  else
    echo "Reports directory does not exist, creating it..."
    mkdir -p "$REPORTS_DIR"
    cp allure-results.tar.gz "$REPORTS_DIR"/
    echo "Results copied to $REPORTS_DIR"
  fi
  
  # Cleanup
  rm -f allure-results.tar.gz
else
  echo "Test results directory $RESULTS_DIR not found"
fi

echo "Allure upload process completed"