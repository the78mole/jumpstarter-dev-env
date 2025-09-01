#!/bin/bash
set -e

echo "Setting up Jumpstarter Server development environment with Docker-in-Docker..."

echo "✅ Checking installed tools:"
echo "  Docker: $(docker --version)"
echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl installed')"
echo "  Helm: $(helm version --short 2>/dev/null || echo 'helm installed')"
echo "  Kind: $(kind version)"
echo "  netcat: $(nc -h 2>&1 | head -1 || echo 'netcat installed')"

# Kind Cluster erstellen falls nicht vorhanden
if ! kind get clusters | grep -q jumpstarter-server; then
    echo "Creating kind cluster with official Jumpstarter configuration..."
    kind create cluster --config=kind-config.yaml
else
    echo "Kind cluster 'jumpstarter-server' already exists."
fi

# Kubectl Context setzen (auch wenn Cluster bereits existiert)
echo "Setting kubectl context..."
kind export kubeconfig --name jumpstarter-server

# Warten bis Cluster bereit ist
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Prüfen ob Jumpstarter bereits installiert ist
if ! kubectl get namespace jumpstarter-lab &> /dev/null; then
    echo "Installing Jumpstarter for the first time..."
    
    # Ingress Controller für Kind installieren
    echo "Installing NGINX Ingress Controller for Kind..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Warten bis Ingress Controller bereit ist
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
    
    # Jumpstarter Installation
    echo "Installing Jumpstarter with Helm..."
    export IP="127.0.0.1"
    export BASEDOMAIN="jumpstarter.${IP}.nip.io"
    export GRPC_ENDPOINT="grpc.${BASEDOMAIN}:8082"
    export GRPC_ROUTER_ENDPOINT="router.${BASEDOMAIN}:8083"
    
    kubectl create namespace jumpstarter-lab --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade jumpstarter --install oci://quay.io/jumpstarter-dev/helm/jumpstarter \
        --create-namespace --namespace jumpstarter-lab \
        --set global.baseDomain=${BASEDOMAIN} \
        --set jumpstarter-controller.grpc.endpoint=${GRPC_ENDPOINT} \
        --set jumpstarter-controller.grpc.routerEndpoint=${GRPC_ROUTER_ENDPOINT} \
        --set global.metrics.enabled=false \
        --set jumpstarter-controller.grpc.nodeport.enabled=true \
        --set jumpstarter-controller.grpc.mode=ingress \
        --version=0.7.0-dev-8-g83e23d3
else
    echo "Jumpstarter namespace already exists - skipping installation."
fi

# Status anzeigen
echo ""
echo "=== Jumpstarter Setup Complete! ==="
echo ""
echo "Checking cluster status..."
kubectl get nodes

echo ""
echo "Checking Jumpstarter pods:"
kubectl get pods -n jumpstarter-lab

echo ""
echo "Services:"
kubectl get svc -n jumpstarter-lab

echo ""
echo "Ingress status:"
kubectl get ingress -n jumpstarter-lab

echo ""
echo "=== Docker-in-Docker Setup Complete! ==="
echo "With Docker-in-Docker, port mappings should work directly."

echo ""
echo "=== Network Tests ==="
echo "Testing localhost ports..."
for port in 5080 8082 8083; do
    if timeout 2 nc -z localhost $port 2>/dev/null; then
        echo "✅ Port $port: OPEN"
    else
        echo "❌ Port $port: CLOSED"
    fi
done

echo ""
echo "=== Access Information ==="
echo "Base domain: jumpstarter.127.0.0.1.nip.io"
echo "🌐 Web Interface: http://localhost:5080"
echo "🔗 GRPC Controller: localhost:8082"
echo "🔗 GRPC Router: localhost:8083"
echo ""
echo "If ports are not accessible, you may need to restart the dev container"
echo "for Docker-in-Docker to take effect."
echo ""
echo "To check logs:"
echo "  kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-controller"
echo "  kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-router"
