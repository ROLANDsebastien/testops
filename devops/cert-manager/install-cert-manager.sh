#!/bin/bash

set -e

echo "Installing cert-manager..."

# Add Jetstack Helm repository quietly
helm repo add jetstack https://charts.jetstack.io --force-update > /dev/null 2>&1

# Update Helm repositories quietly
helm repo update > /dev/null 2>&1

# Install cert-manager and redirect output to null
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3 \
  --set installCRDs=true > /dev/null

# Wait for cert-manager to be ready
kubectl wait --for=condition=available --timeout=300s deployment -n cert-manager --all

echo "cert-manager installed successfully."
