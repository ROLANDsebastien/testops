#!/bin/bash
set -e

# Go to the script's directory
cd "$(dirname "$0")"

# Add Grafana Helm repo if not exists
helm repo add grafana https://grafana.github.io/helm-charts > /dev/null 2>&1 || true
helm repo update > /dev/null 2>&1

# Install Grafana
helm upgrade --install grafana grafana/grafana \
  --namespace grafana --create-namespace \
  --values grafana-values.yaml > /dev/null 2>&1

echo "Waiting for Grafana to be ready..."
kubectl -n grafana wait --for=condition=ready pod --all --timeout=5m

echo "Grafana installation complete."
