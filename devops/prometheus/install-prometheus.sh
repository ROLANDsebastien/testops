#!/bin/bash
set -e

# Go to the script's directory
cd "$(dirname "$0")"

# Add Prometheus Helm repo if not exists
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null 2>&1 || true
helm repo update > /dev/null 2>&1

# Delete existing PVC if any to avoid volume issues
kubectl delete pvc prometheus-server --ignore-not-found=true -n prometheus

# Install Prometheus
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace prometheus --create-namespace \
  --values prometheus-values.yaml > /dev/null 2>&1

echo "Waiting for Prometheus to be ready..."
kubectl -n prometheus wait --for=condition=ready pod --all --timeout=10m

echo "Prometheus installation complete."
