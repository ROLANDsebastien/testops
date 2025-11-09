#!/bin/bash
set -e

# Go to the script's directory
cd "$(dirname "$0")"

# Add the Longhorn Helm repository
helm repo add longhorn https://charts.longhorn.io > /dev/null 2>&1 || true
helm repo update > /dev/null 2>&1

# Create the namespace for Longhorn
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

# Install Longhorn using Helm
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --values longhorn-values.yaml > /dev/null 2>&1

echo "Waiting for Longhorn to be ready..."
# This can take a few minutes as it needs to pull images and start all components.
kubectl -n longhorn-system wait --for=condition=ready pod --all --timeout=5m

echo "Longhorn installation complete."
