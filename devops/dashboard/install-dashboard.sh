#!/bin/bash

set -e

echo "Installing Kubernetes Dashboard..."

# Apply the recommended YAML and redirect output to null
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create service account for dashboard access and redirect output to null
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Wait for dashboard to be ready
kubectl wait --for=condition=available --timeout=600s deployment -n kubernetes-dashboard kubernetes-dashboard

echo "Kubernetes Dashboard and admin-user account installed successfully."
