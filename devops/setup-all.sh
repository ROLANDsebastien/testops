#!/bin/bash
set -e

# Go to the script's directory
cd "$(dirname "$0")"

# --- FULL CLEANUP ---
echo ""
echo "--> Performing full cleanup before setup..."

echo ""
echo "Purging all Multipass VMs..."
multipass delete --all --purge
echo ""
echo "Cleaning /etc/hosts file..."
sudo sed -i '' '/.local/d' /etc/hosts

# --- CLUSTER CREATION ---
echo ""
echo "--> Creating Multipass k3s cluster with optimized TestOps resources..."
./cluster/create-cluster.sh

# --- INSTALL COMPONENTS ---
echo ""
echo "--> Installing Kubernetes Dashboard..."
./dashboard/install-dashboard.sh

echo ""
echo "--> Installing Traefik with Gateway API..."
TRAEFIK_OUTPUT=$(./traefik/install-traefik.sh)
echo "$TRAEFIK_OUTPUT"
TRAEFIK_PASSWORD=$(echo "$TRAEFIK_OUTPUT" | grep "^Password:" | awk '{print $2}')

echo ""
echo "--> Installing Cert-Manager..."
./cert-manager/install-cert-manager.sh

echo ""
echo "--> Installing Longhorn..."
./longhorn/install-longhorn.sh

echo ""
echo "--> Installing Grafana..."
./grafana/install-grafana.sh

echo ""
echo "--> Installing Prometheus..."
./prometheus/install-prometheus.sh

echo ""
echo "--> Installing ArgoCD..."
./argocd/install-argocd.sh

# --- INSTALL TESTOPS COMPONENTS ---
echo ""
echo "--> Installing SonarQube for code quality analysis..."
kubectl apply -f ./sonarqube/namespace.yaml
kubectl apply -f ./sonarqube/pvc.yaml
kubectl apply -f ./sonarqube/deployment.yaml
kubectl apply -f ./sonarqube/service.yaml

echo ""
echo "--> Installing Allure Dashboard for test reporting..."
kubectl apply -f ./allure/namespace.yaml
kubectl apply -f ./allure/pvc.yaml
kubectl apply -f ./allure/deployment.yaml
kubectl apply -f ./allure/service.yaml

echo ""
echo "--> Installing OWASP ZAP for security testing..."
kubectl apply -f ./owasp/namespace.yaml
kubectl apply -f ./owasp/pvc.yaml
kubectl apply -f ./owasp/zap-deployment.yaml
kubectl apply -f ./owasp/zap-service.yaml

echo ""
echo "--> Configuring GitHub Actions Runner Controller..."

# Create the namespace for the runner controller first
kubectl create namespace actions-runner-system

echo "The runner controller needs a Personal Access Token (PAT) to authenticate with the GitHub API."
echo "Please paste your PAT below and press Enter."
read -sp "GitHub PAT: " GH_PAT
echo ""

if [ -z "$GH_PAT" ]; then
  echo "Error: PAT cannot be empty."
  exit 1
fi

echo "Creating the secret for the runner controller..."
kubectl create secret generic controller-manager -n actions-runner-system \
  --from-literal=github_token="$GH_PAT" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "--> Installing GitHub Actions Runner Controller..."

# Add the Helm repo for the runner controller
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller > /dev/null 2>&1
helm repo update > /dev/null 2>&1

# Install the runner controller with Helm
helm upgrade --install actions-runner-controller actions-runner-controller/actions-runner-controller \
  --namespace "actions-runner-system" \
  --create-namespace \
  --set githubRepository="rolandsebastien/testops" > /dev/null

echo "Waiting for GitHub Actions Runner Controller to be ready..."

# Wait for the controller deployment to be available
kubectl wait --for=condition=available --timeout=180s deployment/actions-runner-controller -n "actions-runner-system" 2>/dev/null || true

echo "GitHub Actions Runner Controller installation complete."

echo ""
echo "--> Applying Runner Deployment configuration..."

# Get the Ingress IP to inject into the runner's host aliases
INGRESS_IP=$(multipass info k3s-worker1 --format json | jq -r ".info[\"k3s-worker1\"].ipv4[0]")

# Replace the placeholder in the runner deployment manifest
sed -i '' "s|__INGRESS_IP__|${INGRESS_IP}|" ./actions-runner-controller/runner-deployment.yaml

kubectl apply -f ./actions-runner-controller/runner-deployment.yaml

# --- APPLY CONFIGS ---
echo ""
echo "--> Applying Cert-Manager configurations..."
kubectl apply -f ./cert-manager/cluster-issuer.yaml

echo ""
echo "Waiting for cert-manager webhook to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

echo ""
echo "--> Applying Traefik Gateway..."
kubectl apply -f ./traefik/gateway.yaml

echo ""
echo "--> Applying Traefik Dashboard Certificate & IngressRoute..."
kubectl apply -f ./traefik/wildcard-certificate.yaml
kubectl wait --for=condition=ready certificate/wildcard-local-tls -n kube-system --timeout=300s
kubectl apply -f ./traefik/traefik-dashboard-ingressroute.yaml

echo ""
echo "--> Applying Dashboard Certificate, ServersTransport & IngressRoute..."
kubectl apply -f ./dashboard/certificate.yaml
kubectl wait --for=condition=ready certificate/dashboard-tls -n kubernetes-dashboard --timeout=300s
kubectl apply -f ./dashboard/serverstransport.yaml
kubectl apply -f ./dashboard/ingressroute.yaml

echo ""
echo "--> Applying Longhorn Certificate & IngressRoute..."
kubectl apply -f ./longhorn/certificate.yaml
kubectl wait --for=condition=ready certificate/longhorn-tls -n longhorn-system --timeout=300s
kubectl apply -f ./longhorn/ingressroute.yaml

echo ""
echo "--> Applying Grafana Certificate & IngressRoute..."
kubectl apply -f ./grafana/certificate.yaml
kubectl wait --for=condition=ready certificate/grafana-tls -n grafana --timeout=300s
kubectl apply -f ./grafana/ingressroute.yaml

echo ""
echo "--> Applying Prometheus Certificate & IngressRoute..."
kubectl apply -f ./prometheus/certificate.yaml
kubectl wait --for=condition=ready certificate/prometheus-tls -n prometheus --timeout=300s
kubectl apply -f ./prometheus/ingressroute.yaml

echo ""
echo "--> Applying ArgoCD Certificate, ServersTransport & IngressRoute..."
kubectl apply -f ./argocd/certificate.yaml
kubectl wait --for=condition=ready certificate/argocd-tls -n argocd --timeout=300s
kubectl apply -f ./argocd/serverstransport.yaml
kubectl apply -f ./argocd/ingressroute.yaml

echo ""
echo "--> Applying ArgoCD Application..."
kubectl apply -f ./argocd/argocd-application.yaml

echo ""
echo "--> Applying FM Compta Consulting Certificate & IngressRoute..."
kubectl apply -f ../application/manifests/certificate.yaml
kubectl wait --for=condition=ready certificate/fm-compta-consulting-tls -n default --timeout=300s
kubectl apply -f ../application/manifests/ingressroute.yaml

# --- APPLY TESTOPS CONFIGS ---
echo ""
echo "--> Applying SonarQube Certificate & IngressRoute..."
kubectl apply -f ./sonarqube/certificate.yaml
kubectl wait --for=condition=ready certificate/sonarqube-tls -n sonarqube --timeout=300s
kubectl apply -f ./sonarqube/ingressroute.yaml

echo ""
echo "--> Applying Allure Certificate & IngressRoute..."
kubectl apply -f ./allure/certificate.yaml
kubectl wait --for=condition=ready certificate/allure-tls -n allure --timeout=300s
kubectl apply -f ./allure/ingressroute.yaml

echo ""
echo "--> Applying OWASP ZAP Certificate & IngressRoute..."
kubectl apply -f ./owasp/certificate.yaml
kubectl wait --for=condition=ready certificate/zap-tls -n owasp --timeout=300s
kubectl apply -f ./owasp/ingressroute.yaml

# --- HOSTS FILE UPDATE ---
echo ""
echo "--> Updating /etc/hosts file..."

# Get the IP of a worker node directly
INGRESS_IP=$(multipass info k3s-worker1 --format json | jq -r ".info[\"k3s-worker1\"].ipv4[0]")

echo ""
echo "Using worker IP for Ingress: $INGRESS_IP"

# Remove any old entry for dashboard.local and add the new one
# This requires sudo permissions.
echo ""
echo "Removing old '.local' entries from /etc/hosts."
sudo sed -i '' '/.local/d' /etc/hosts

echo ""
echo "Adding new entries to /etc/hosts."
echo "$INGRESS_IP dashboard.local longhorn.local grafana.local prometheus.local argocd.local fm-compta-consulting.local sonarqube.local allure.local zap.local traefik.local" | sudo tee -a /etc/hosts

echo ""
echo "=== SETUP COMPLETE! ==="
echo ""
echo "Dashboard URL: https://dashboard.local"
echo ""
echo "kubernetes dashboard token:"
kubectl -n kubernetes-dashboard create token admin-user
echo ""
echo "Longhorn UI URL: https://longhorn.local"
echo ""
echo "Grafana URL: https://grafana.local"
echo "Grafana admin credentials: admin / admin123"
echo ""
echo "Prometheus URL: https://prometheus.local"
echo ""
echo "ArgoCD URL: https://argocd.local"
echo "ArgoCD admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo "App URL: https://fm-compta-consulting.local"
echo ""
echo "SonarQube URL: https://sonarqube.local"
echo "SonarQube admin credentials: admin / admin"
echo ""
echo "Allure Dashboard URL: https://allure.local"
echo ""
echo "Traefik Dashboard URL: https://traefik.local"
echo "Traefik dashboard credentials: admin / $TRAEFIK_PASSWORD"
echo ""
