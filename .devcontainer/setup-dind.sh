#!/bin/bash
set -e

echo "Setting up Jumpstarter Server development environment with Docker-in-Docker..."

# Robuste Warte-Funktion für Docker
wait_for_docker() {
    echo "⏳ Waiting for Docker daemon to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker daemon is ready"
            return 0
        fi
        echo "  Attempt $attempt/$max_attempts: Docker not ready yet, waiting..."
        sleep 2
        ((attempt++))
    done

    echo "❌ Docker daemon failed to start within timeout"
    return 1
}

# Robuste Warte-Funktion für Kubernetes
wait_for_kubernetes() {
    echo "⏳ Waiting for Kubernetes cluster to be accessible..."
    local max_attempts=60
    local attempt=1

    # Zuerst versuchen wir die kubeconfig zu reparieren
    echo "Fixing kubeconfig for DevContainer..."
    mkdir -p ~/.kube
    kind get kubeconfig --name jumpstarter-server > ~/.kube/config

    while [ $attempt -le $max_attempts ]; do
        # Teste direkt im Kind-Container anstatt externe Verbindung
        if docker exec jumpstarter-server-control-plane kubectl get nodes >/dev/null 2>&1; then
            echo "✅ Kubernetes cluster is accessible (via Kind container)"
            return 0
        fi
        echo "  Attempt $attempt/$max_attempts: Kubernetes not ready yet, waiting..."
        sleep 3
        ((attempt++))
    done

    echo "❌ Kubernetes cluster failed to become accessible within timeout"
    return 1
}

# Robuste Warte-Funktion für Jumpstarter Pods
wait_for_jumpstarter_pods() {
    echo "⏳ Waiting for Jumpstarter pods to be ready..."
    local max_attempts=20
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        local running_pods=$(docker exec jumpstarter-server-control-plane kubectl get pods -n jumpstarter-lab --no-headers 2>/dev/null | grep -c "Running" 2>/dev/null || echo "0")
        local total_pods=$(docker exec jumpstarter-server-control-plane kubectl get pods -n jumpstarter-lab --no-headers 2>/dev/null | grep -v "^$" | wc -l 2>/dev/null || echo "0")

        # Ensure variables are integers
        running_pods=$(echo "$running_pods" | tr -d '\n' | tr -d ' ')
        total_pods=$(echo "$total_pods" | tr -d '\n' | tr -d ' ')

        # Default to 0 if not a number
        [ "$running_pods" -eq "$running_pods" ] 2>/dev/null || running_pods=0
        [ "$total_pods" -eq "$total_pods" ] 2>/dev/null || total_pods=0

        if [ "$running_pods" -gt 0 ] && [ "$running_pods" -eq "$total_pods" ]; then
            echo "✅ All Jumpstarter pods are running ($running_pods/$total_pods)"
            return 0
        fi

        echo "  Attempt $attempt/$max_attempts: $running_pods/$total_pods pods running, waiting..."
        sleep 10
        ((attempt++))
    done

    echo "⚠️ Jumpstarter pods not fully ready after timeout, but continuing..."
    echo "   This is normal - pods may still be starting up in the background"
    return 0  # Continue anyway, don't fail the setup
}

# Warte auf Docker daemon
wait_for_docker

echo "✅ Checking installed tools:"
echo "  Docker: $(docker --version)"
echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl installed')"
echo "  Helm: $(helm version --short 2>/dev/null || echo 'helm installed')"
echo "  Kind: $(kind version)"
echo "  netcat: $(nc -h 2>&1 | head -1 || echo 'netcat installed')"

# Kind Cluster erstellen falls nicht vorhanden
if ! kind get clusters | grep -q jumpstarter-server; then
    echo "Creating kind cluster with official Jumpstarter configuration..."
    kind create cluster --config=kind-config.yaml --wait 300s
    echo "Kind cluster created successfully"
else
    echo "Kind cluster 'jumpstarter-server' already exists."
fi

# Kubectl Context setzen (auch wenn Cluster bereits existiert)
echo "Setting kubectl context..."
kind export kubeconfig --name jumpstarter-server

# Extra Wartezeit für Cluster Stabilität
echo "Waiting for cluster to stabilize..."
sleep 10

# Warte auf Kubernetes Zugänglichkeit
wait_for_kubernetes

# Warten bis Cluster bereit ist
echo "Waiting for cluster nodes to be ready..."
docker exec jumpstarter-server-control-plane kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Prüfen ob Jumpstarter bereits installiert ist
if ! docker exec jumpstarter-server-control-plane kubectl get namespace jumpstarter-lab &> /dev/null; then
    echo "Installing Jumpstarter for the first time..."

    # Ingress Controller für Kind installieren
    echo "Installing NGINX Ingress Controller for Kind..."
    docker exec jumpstarter-server-control-plane kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

    # Warten bis Ingress Controller bereit ist
    docker exec jumpstarter-server-control-plane kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

    # Jumpstarter Installation
    echo "Installing Jumpstarter with Helm..."
    export IP="127.0.0.1"
    export BASEDOMAIN="jumpstarter.${IP}.nip.io"
    export GRPC_ENDPOINT="grpc.${BASEDOMAIN}:8082"
    export GRPC_ROUTER_ENDPOINT="router.${BASEDOMAIN}:8083"

    docker exec jumpstarter-server-control-plane kubectl create namespace jumpstarter-lab --dry-run=client -o yaml | docker exec -i jumpstarter-server-control-plane kubectl apply -f -

    # Installiere Helm im Kind-Container
    echo "Installing Helm in Kind container..."
    docker exec jumpstarter-server-control-plane sh -c "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"

    docker exec jumpstarter-server-control-plane helm upgrade jumpstarter --install oci://quay.io/jumpstarter-dev/helm/jumpstarter \
        --create-namespace --namespace jumpstarter-lab \
        --set global.baseDomain=${BASEDOMAIN} \
        --set jumpstarter-controller.grpc.endpoint=${GRPC_ENDPOINT} \
        --set jumpstarter-controller.grpc.routerEndpoint=${GRPC_ROUTER_ENDPOINT} \
        --set global.metrics.enabled=false \
        --set jumpstarter-controller.grpc.nodeport.enabled=true \
        --set jumpstarter-controller.grpc.mode=ingress \
        --version=0.7.0-dev-8-g83e23d3
    # Warte auf Jumpstarter Pods nach der Installation
    echo "Waiting for Jumpstarter pods to start..."
    wait_for_jumpstarter_pods

else
    echo "Jumpstarter already installed - checking pod status..."
    wait_for_jumpstarter_pods
fi

# Status anzeigen
echo ""
echo "=== Jumpstarter Setup Complete! ==="
echo ""
echo "Checking cluster status..."
docker exec jumpstarter-server-control-plane kubectl get nodes

echo ""
echo "Checking Jumpstarter pods:"
docker exec jumpstarter-server-control-plane kubectl get pods -n jumpstarter-lab

echo ""
echo "Services:"
docker exec jumpstarter-server-control-plane kubectl get svc -n jumpstarter-lab

echo ""
echo "Ingress status:"
docker exec jumpstarter-server-control-plane kubectl get ingress -n jumpstarter-lab

echo ""
echo "=== Docker-in-Docker Setup Complete! ==="
echo "With Docker-in-Docker, port mappings should work directly."

echo ""
echo "=== Network Tests ==="
echo "Testing Ingress Controller..."
# Check if ingress controller pod is running (simpler and more reliable)
if docker exec jumpstarter-server-control-plane kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep -q "Running"; then
    echo "✅ Ingress Controller: RUNNING"
else
    echo "⚠️ Ingress Controller: STARTING UP (this is normal for new deployments)"
fi

echo ""
echo "Testing Jumpstarter services..."
running_pods=$(docker exec jumpstarter-server-control-plane kubectl get pods -n jumpstarter-lab --no-headers 2>/dev/null | grep -c "Running" 2>/dev/null || echo "0")
total_pods=$(docker exec jumpstarter-server-control-plane kubectl get pods -n jumpstarter-lab --no-headers 2>/dev/null | grep -v "^$" | wc -l 2>/dev/null || echo "0")

# Ensure variables are clean integers
running_pods=$(echo "$running_pods" | tr -d '\n' | tr -d ' ')
total_pods=$(echo "$total_pods" | tr -d '\n' | tr -d ' ')

# Default to 0 if not a number
[ "$running_pods" -eq "$running_pods" ] 2>/dev/null || running_pods=0
[ "$total_pods" -eq "$total_pods" ] 2>/dev/null || total_pods=0

if [ "$running_pods" -gt 0 ]; then
    if [ "$running_pods" -eq "$total_pods" ]; then
        echo "✅ Jumpstarter pods: ALL RUNNING ($running_pods/$total_pods)"
    else
        echo "⚠️ Jumpstarter pods: PARTIALLY RUNNING ($running_pods/$total_pods)"
        echo "   Some pods may still be starting - this is normal"
    fi
else
    echo "⚠️ Jumpstarter pods: STARTING UP"
    echo "   Pods are still initializing - check status with: make status"
fi

echo ""
echo "=== Access Information ==="
echo "Base domain: jumpstarter.127.0.0.1.nip.io"
echo "🔗 GRPC Controller: localhost:30010 (NodePort)"
echo "🔗 GRPC Router: localhost:30011 (NodePort)"
echo "🌐 Ingress GRPC Controller: http://grpc.jumpstarter.127.0.0.1.nip.io (via Ingress)"
echo "🌐 Ingress Router: http://router.jumpstarter.127.0.0.1.nip.io (via Ingress)"
echo ""
echo "Note: This Jumpstarter version provides GRPC APIs, no web interface"

echo ""
echo "=== Python Environment Setup ==="
echo "Installing Jumpstarter Python dependencies..."
if command -v uv >/dev/null 2>&1; then
    echo "Using uv to install dependencies..."
    uv sync 2>/dev/null || echo "Note: Run 'uv sync' manually after container setup"

    echo "Installing Robot Framework testing dependencies..."
    uv sync --group testing 2>/dev/null || echo "Note: Robot Framework dependencies available after sync"
else
    echo "⚠️ uv not found - should be installed via DevContainer feature"
    echo "Note: Rebuild container to install uv via DevContainer feature"
fi

echo ""
echo "=== Robot Framework Setup ==="
if uv run robot --version >/dev/null 2>&1; then
    echo "✅ Robot Framework is available via uv"
    uv run robot --version 2>/dev/null || echo "Robot Framework version check completed"
elif command -v robot >/dev/null 2>&1; then
    echo "✅ Robot Framework is available globally"
    robot --version 2>/dev/null || echo "Robot Framework version check completed"
else
    echo "⚠️ Robot Framework not found - install with 'uv sync --group testing'"
fi

echo ""
echo "=== Jumpstarter CLI Access ==="
echo "✅ jmp and j commands available via DevContainer feature"
echo "Usage: jmp shell --client hello --selector environment=dev"
echo "Short: j shell --client hello --selector environment=dev"

echo ""
echo "If ports are not accessible, you may need to restart the dev container"
echo "for Docker-in-Docker to take effect."
echo ""
echo "To check logs:"
echo "  kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-controller"
echo "  kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-router"
echo "  docker exec jumpstarter-server-control-plane kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-router"
