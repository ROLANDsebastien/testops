#!/bin/bash

# Namespace for the GitHub Actions runner controller
NAMESPACE="actions-runner-system"

# Add the Helm repo for the runner controller
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller > /dev/null 2>&1
helm repo update > /dev/null 2>&1

# Install the runner controller with Helm, suppressing the verbose output
helm upgrade --install actions-runner-controller actions-runner-controller/actions-runner-controller \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set githubRepository="rolandsebastien/devops-cluster-gitops" > /dev/null

echo "Waiting for GitHub Actions Runner Controller to be ready..."

# Wait for the controller deployment to be available
kubectl wait --for=condition=available --timeout=180s deployment/actions-runner-controller -n "$NAMESPACE"

echo "GitHub Actions Runner Controller installation complete."
