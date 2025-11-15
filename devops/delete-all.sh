#!/bin/bash

# Go to the script's directory
cd "$(dirname "$0")"

# Remove /etc/hosts entries
echo "--> Removing /etc/hosts entries..."
sudo sed -i '' '/.local/d' /etc/hosts

# Delete the cluster itself
echo "--> Deleting Multipass k3s cluster..."
./cluster/delete-cluster.sh
