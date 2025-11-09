#!/bin/bash
set -e

echo "Deleting k3s cluster..."

# 1. Delete kubectl config entries
# These commands might fail if the config is already gone, which is fine.
echo "Cleaning up ~/.kube/config..."
kubectl config delete-cluster default
kubectl config delete-context default
kubectl config delete-user default

# 2. Delete all Multipass VMs
echo "Deleting all Multipass VMs..."
multipass delete --all --purge

echo "Cluster deleted."