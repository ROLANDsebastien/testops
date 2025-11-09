#!/bin/bash
set -e

echo "Starting k3s cluster creation with Multipass..."

# 1. Launch VMs with increased resources for TestOps workloads
echo "Creating VMs with increased resources for TestOps..."
multipass launch --name k3s-master --cpus 4 --memory 4G --disk 15G
multipass launch --name k3s-worker1 --cpus 8 --memory 12G --disk 30G
multipass launch --name k3s-worker2 --cpus 8 --memory 12G --disk 30G

# Wait for VMs to get an IP address
echo "Waiting 30 seconds for VMs to initialize..."
sleep 30

# 2. Install k3s on master with a taint
echo "Installing k3s on master node (k3s-master)..."
multipass exec k3s-master -- bash -c "curl -sfL https://get.k3s.io | sh -s - --node-taint CriticalAddonsOnly=true:NoExecute --disable=traefik --disable-network-policy > /dev/null 2>&1"

# 3. Get master IP and token
echo "Getting connection info..."

MASTER_IP=$(multipass info k3s-master --format json | jq -r ".info[\"k3s-master\"]".ipv4[0])
K3S_TOKEN=$(multipass exec k3s-master -- sudo cat /var/lib/rancher/k3s/server/node-token)
echo "Master IP is: $MASTER_IP"

# 4. Join workers to the master
echo "Joining worker 1 (k3s-worker1)..."
multipass exec k3s-worker1 -- bash -c "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh - > /dev/null 2>&1"
echo "Joining worker 2 (k3s-worker2)..."
multipass exec k3s-worker2 -- bash -c "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh - > /dev/null 2>&1"

# 5. Fetch kubeconfig and place it for kubectl to use
mkdir -p ~/.kube
multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
sed -i '' "s/127.0.0.1/$MASTER_IP/" ~/.kube/config

echo "Cluster ready and configured."
