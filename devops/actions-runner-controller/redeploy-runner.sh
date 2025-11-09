#!/bin/bash

# Script to redeploy the corrected GitHub Actions runner
# This script removes the old runner configuration and deploys the corrected one

set -e

NAMESPACE="actions-runner-system"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Main script
main() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  GitHub Actions Runner Redeploy${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    log_success "kubectl found"

    # Check if the namespace exists
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_error "Namespace $NAMESPACE does not exist"
        log_info "Please run ./setup-all.sh first"
        exit 1
    fi
    log_success "Namespace $NAMESPACE found"
    echo ""

    # Step 1: Delete existing runner resources
    log_info "Step 1: Removing old runner resources..."
    kubectl delete runnerdeployment fm-compta-runner -n "$NAMESPACE" --ignore-not-found=true
    kubectl delete horizontalrunnerautoscaler fm-compta-runner-autoscaler -n "$NAMESPACE" --ignore-not-found=true
    log_success "Old resources removed"
    sleep 5
    echo ""

    # Step 2: Get the Ingress IP
    log_info "Step 2: Retrieving Ingress IP..."
    INGRESS_IP=""

    # Try multipass first
    if command -v multipass &> /dev/null; then
        INGRESS_IP=$(multipass info k3s-worker1 --format json 2>/dev/null | jq -r ".info[\"k3s-worker1\"].ipv4[0]" 2>/dev/null || echo "")
    fi

    # Fallback to kubectl
    if [ -z "$INGRESS_IP" ] || [ "$INGRESS_IP" = "null" ]; then
        INGRESS_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
    fi

    # Ask user if we couldn't find it
    if [ -z "$INGRESS_IP" ]; then
        log_warning "Could not automatically detect Ingress IP"
        read -p "Please enter the Ingress IP address: " INGRESS_IP
    fi

    if [ -z "$INGRESS_IP" ]; then
        log_error "No IP provided"
        exit 1
    fi

    log_success "Using Ingress IP: $INGRESS_IP"
    echo ""

    # Step 3: Create and apply the manifest
    log_info "Step 3: Creating runner deployment manifest..."
    TEMP_FILE=$(mktemp)
    sed "s|__INGRESS_IP__|${INGRESS_IP}|g" "$SCRIPT_DIR/runner-deployment.yaml" > "$TEMP_FILE"
    log_success "Manifest created"

    log_info "Step 4: Applying runner deployment..."
    if kubectl apply -f "$TEMP_FILE"; then
        log_success "Runner deployment applied"
    else
        log_error "Failed to apply runner deployment"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    rm -f "$TEMP_FILE"
    echo ""

    # Step 5: Wait for pods
    log_info "Step 5: Waiting for runner pods to be ready..."
    if kubectl wait --for=condition=ready pod \
        -l actions.summerwind.dev/deployment=fm-compta-runner \
        -n "$NAMESPACE" \
        --timeout=300s 2>/dev/null; then
        log_success "Runner pods are ready!"
    else
        log_warning "Timeout waiting for pods, they may still be initializing..."
    fi
    echo ""

    # Step 6: Display status
    log_info "Step 6: Current status"
    echo ""
    echo "RunnerDeployments:"
    kubectl get runnerdeployment -n "$NAMESPACE" -o wide || true
    echo ""
    echo "Runner Pods:"
    kubectl get pods -n "$NAMESPACE" -l actions.summerwind.dev/deployment=fm-compta-runner -o wide || true
    echo ""

    # Display completion message
    echo -e "${BLUE}==========================================${NC}"
    log_success "Redeploy complete!"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Verify in GitHub: Settings > Actions > Runners"
    echo "  2. Check runner status: kubectl get runners -n $NAMESPACE"
    echo "  3. View logs: kubectl logs -n $NAMESPACE -l actions.summerwind.dev/deployment=fm-compta-runner -c runner -f"
    echo "  4. Test workflow: Push to main or trigger Actions > CI - Build and Deploy"
    echo ""
}

main "$@"
