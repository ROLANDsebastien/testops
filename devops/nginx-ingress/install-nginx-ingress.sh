#!/bin/bash
set -e
echo "Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx > /dev/null 2>&1
helm repo update > /dev/null 2>&1
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace > /dev/null

echo "Waiting for NGINX Ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "NGINX Ingress Controller is ready."
