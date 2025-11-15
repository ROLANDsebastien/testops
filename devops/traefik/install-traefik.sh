#!/bin/bash
set -e

echo "Configuring K3s native Traefik with Gateway API support..."

# Install Gateway API CRDs
echo "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml > /dev/null 2>&1

echo "Waiting for Gateway API CRDs to be established..."
kubectl wait --for condition=established --timeout=60s crd/gateways.gateway.networking.k8s.io
kubectl wait --for condition=established --timeout=60s crd/httproutes.gateway.networking.k8s.io

# K3s installs Traefik in kube-system namespace by default
echo "Waiting for K3s native Traefik to be ready..."
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=traefik \
  --timeout=120s

# Enable Gateway API provider in Traefik via HelmChartConfig
echo "Configuring Traefik to use Gateway API..."
cat <<EOF | kubectl apply -f -
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    providers:
      kubernetesGateway:
        enabled: true
      kubernetesCRD:
        enabled: true
        allowCrossNamespace: true
    ports:
      web:
        port: 80
      websecure:
        port: 443
        tls:
          enabled: true
      traefik:
        port: 9000
        expose:
          default: true
    ingressRoute:
      dashboard:
        enabled: false
    api:
      dashboard: true
      insecure: true
EOF

# Wait a bit for Traefik to reload configuration
echo "Waiting for Traefik to reload configuration..."
sleep 10

# Restart Traefik pod to apply new configuration
echo "Restarting Traefik to apply Gateway API configuration..."
if kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik 2>/dev/null | grep -q traefik; then
  kubectl delete pods -n kube-system -l app.kubernetes.io/name=traefik
  echo "Waiting for Traefik to restart..."
  kubectl wait --namespace kube-system \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=traefik \
    --timeout=120s
else
  echo "Traefik pods not found yet, waiting for initial startup..."
  kubectl wait --namespace kube-system \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=traefik \
    --timeout=120s
fi

echo "K3s native Traefik with Gateway API is ready."

# Generate password for dashboard
DASHBOARD_PASSWORD=$(openssl rand -base64 12)
HASHED_PASSWORD=$(openssl passwd -apr1 "$DASHBOARD_PASSWORD")

# Create basic auth secret
echo "Creating dashboard authentication..."
kubectl create secret generic traefik-dashboard-auth \
  --from-literal=users="admin:$HASHED_PASSWORD" \
  -n kube-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Create BasicAuth middleware
cat <<EOF | kubectl apply -f -
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: traefik-dashboard-auth
  namespace: kube-system
spec:
  basicAuth:
    secret: traefik-dashboard-auth
EOF

# Create Service for Traefik dashboard
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  type: ClusterIP
  ports:
    - name: traefik
      port: 9000
      targetPort: traefik
  selector:
    app.kubernetes.io/name: traefik
EOF



echo ""
echo "Traefik Dashboard is ready!"
echo ""
echo "URL: https://traefik.local"
echo "Username: admin"
echo "Password: $DASHBOARD_PASSWORD"
echo ""
