#!/bin/bash

# Go to the script's directory
cd "$(dirname "$0")"

# Remove /etc/hosts entries
echo "--> Removing /etc/hosts entries..."
sudo sed -i '' '/.local/d' /etc/hosts

# Delete TestOps components first
echo "--> Deleting TestOps components..."
kubectl delete namespace sonarqube allure owasp || true

# Delete the cluster itself
echo "--> Deleting Multipass k3s cluster..."
./cluster/delete-cluster.sh
