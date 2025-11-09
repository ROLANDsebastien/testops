#!/bin/bash
set -e

# Go to the script's directory
cd "$(dirname "$0")"

# Add ArgoCD Helm repo if not exists
helm repo add argo https://argoproj.github.io/argo-helm > /dev/null 2>&1 || true
helm repo update > /dev/null 2>&1

# Install ArgoCD
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --values argocd-values.yaml > /dev/null 2>&1

echo "Waiting for ArgoCD to be ready..."
kubectl -n argocd wait --for=condition=available deployment --all --timeout=10m
# kubectl -n argocd wait --for=condition=ready statefulset --all --timeout=10m

echo "ArgoCD installation complete."
