# Jumpstarter Server Setup Instructions

Diese Anweisungen beschreiben, wie Sie einen Jumpstarter Server mit kind (Kubernetes in Docker) aufsetzen, inklusive Controller und Router Deployment. Das Setup ist auch für DevContainer-basierte Tests optimiert.

## Überblick

Der jumpstarter-server ist eine minimalistische Kubernetes-Umgebung mit Jumpstarter Service-Komponenten, die folgende Hauptkomponenten umfasst:

- **Controller**: Verwaltet die Jumpstarter-Ressourcen und -Richtlinien
- **Router**: Behandelt Netzwerk-Routing und Load Balancing
- **kind Cluster**: Lokale Kubernetes-Umgebung für Entwicklung und Tests

## Voraussetzungen

### Lokale Entwicklung

- Docker Desktop oder Docker Engine
- kind (Kubernetes in Docker)
- kubectl
- k9s (optional, für Kubernetes Dashboard)
- helm (optional, für Helm Charts)

### DevContainer Setup

- Visual Studio Code
- Docker Desktop
- Dev Containers Extension

## 1. Kind Cluster Setup

### Cluster-Konfiguration erstellen

Erstellen Sie eine `kind-config.yaml` für den Jumpstarter Server:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: jumpstarter-server
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
- role: worker
- role: worker
```

### Cluster erstellen

```bash
# Kind Cluster erstellen
kind create cluster --config=kind-config.yaml

# Kontext setzen
kubectl cluster-info --context kind-jumpstarter-server
```

## 2. Jumpstarter Controller Deployment

### Controller Namespace erstellen

```bash
kubectl create namespace jumpstarter-system
```

### Controller Deployment Manifest

Erstellen Sie `controller-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jumpstarter-controller
  namespace: jumpstarter-system
  labels:
    app: jumpstarter-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jumpstarter-controller
  template:
    metadata:
      labels:
        app: jumpstarter-controller
    spec:
      containers:
      - name: controller
        image: jumpstarter/controller:latest
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: CLUSTER_NAME
          value: "jumpstarter-server"
        - name: LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: jumpstarter-controller
  namespace: jumpstarter-system
spec:
  selector:
    app: jumpstarter-controller
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: metrics
    port: 9090
    targetPort: 9090
  type: ClusterIP
```

### Controller deployen

```bash
kubectl apply -f controller-deployment.yaml
```

## 3. Jumpstarter Router Deployment

### Router Deployment Manifest

Erstellen Sie `router-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jumpstarter-router
  namespace: jumpstarter-system
  labels:
    app: jumpstarter-router
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jumpstarter-router
  template:
    metadata:
      labels:
        app: jumpstarter-router
    spec:
      containers:
      - name: router
        image: jumpstarter/router:latest
        ports:
        - containerPort: 8081
          name: http
        - containerPort: 9091
          name: metrics
        env:
        - name: CONTROLLER_ENDPOINT
          value: "http://jumpstarter-controller:8080"
        - name: ROUTER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: jumpstarter-router
  namespace: jumpstarter-system
spec:
  selector:
    app: jumpstarter-router
  ports:
  - name: http
    port: 8081
    targetPort: 8081
  - name: metrics
    port: 9091
    targetPort: 9091
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jumpstarter-router-ingress
  namespace: jumpstarter-system
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: jumpstarter.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: jumpstarter-router
            port:
              number: 8081
```

### Router deployen

```bash
kubectl apply -f router-deployment.yaml
```

## 4. Ingress Controller Setup

### NGINX Ingress Controller installieren

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Warten bis Ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## 5. DevContainer Konfiguration

### .devcontainer/devcontainer.json

```json
{
  "name": "Jumpstarter Server Dev",
  "dockerFile": "Dockerfile",
  "forwardPorts": [8080, 8081, 80, 443],
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {
      "version": "latest",
      "helm": "latest",
      "minikube": "none"
    }
  },
  "postCreateCommand": "bash .devcontainer/setup.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "redhat.vscode-yaml",
        "ms-vscode.vscode-json"
      ]
    }
  }
}
```

### .devcontainer/Dockerfile

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Kind installieren
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && sudo mv ./kind /usr/local/bin/kind

# k9s installieren
RUN curl -Lo ./k9s.tar.gz https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz \
    && tar -xzf k9s.tar.gz \
    && sudo mv k9s /usr/local/bin/k9s \
    && rm k9s.tar.gz

# Zusätzliche Tools
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*
```

### .devcontainer/setup.sh

```bash
#!/bin/bash
set -e

echo "Setting up Jumpstarter Server development environment..."

# Kind Cluster erstellen falls nicht vorhanden
if ! kind get clusters | grep -q jumpstarter-server; then
    echo "Creating kind cluster..."
    kind create cluster --config=kind-config.yaml
fi

# Kubectl Context setzen
kubectl config use-context kind-jumpstarter-server

# Warten bis Cluster bereit ist
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Ingress Controller installieren
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Warten bis Ingress Controller bereit ist
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Jumpstarter Komponenten deployen
echo "Deploying Jumpstarter components..."
kubectl create namespace jumpstarter-system --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f controller-deployment.yaml
kubectl apply -f router-deployment.yaml

echo "Setup complete! Jumpstarter Server is ready."
echo "Access the router at: http://jumpstarter.local"
echo "Controller metrics: http://localhost:8080/metrics"
echo "Router metrics: http://localhost:8081/metrics"
```

## 6. Monitoring und Logging

### Prometheus und Grafana (optional)

```bash
# Helm Repository hinzufügen
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Prometheus installieren
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123
```

## 7. Testing und Validierung

### Kubernetes Dashboard mit k9s

k9s bietet eine interaktive Terminal-UI für Kubernetes-Cluster:

```bash
# k9s starten (funktioniert nur im DevContainer oder mit lokaler Installation)
k9s

# Direkt zu einem bestimmten Namespace navigieren
k9s -n jumpstarter-system

# k9s mit spezifischem Kontext
k9s --context kind-jumpstarter-server
```

**k9s Shortcuts:**

- `:pods` - Pods anzeigen
- `:svc` - Services anzeigen
- `:deploy` - Deployments anzeigen
- `:ns` - Namespaces anzeigen
- `l` - Logs anzeigen (bei ausgewähltem Pod)
- `d` - Describe (bei ausgewählter Ressource)
- `q` - Beenden

### Health Checks

```bash
# Controller Status prüfen
kubectl get pods -n jumpstarter-system
kubectl logs -f deployment/jumpstarter-controller -n jumpstarter-system

# Router Status prüfen
kubectl logs -f deployment/jumpstarter-router -n jumpstarter-system

# Services testen
kubectl port-forward svc/jumpstarter-controller 8080:8080 -n jumpstarter-system &
curl http://localhost:8080/health

kubectl port-forward svc/jumpstarter-router 8081:8081 -n jumpstarter-system &
curl http://localhost:8081/health
```

### Integration Tests

```bash
# End-to-End Test Script
cat > test-jumpstarter.sh << 'EOF'
#!/bin/bash
set -e

echo "Running Jumpstarter Server integration tests..."

# Test Controller Health
echo "Testing Controller health..."
kubectl port-forward svc/jumpstarter-controller 8080:8080 -n jumpstarter-system > /dev/null 2>&1 &
CONTROLLER_PID=$!
sleep 5

if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✓ Controller health check passed"
else
    echo "✗ Controller health check failed"
    exit 1
fi

kill $CONTROLLER_PID

# Test Router Health
echo "Testing Router health..."
kubectl port-forward svc/jumpstarter-router 8081:8081 -n jumpstarter-system > /dev/null 2>&1 &
ROUTER_PID=$!
sleep 5

if curl -f http://localhost:8081/health > /dev/null 2>&1; then
    echo "✓ Router health check passed"
else
    echo "✗ Router health check failed"
    exit 1
fi

kill $ROUTER_PID

echo "All tests passed! Jumpstarter Server is working correctly."
EOF

chmod +x test-jumpstarter.sh
./test-jumpstarter.sh
```

## 8. Troubleshooting

### Häufige Probleme und Lösungen

#### Cluster startet nicht

```bash
# Kind Cluster neu erstellen
kind delete cluster --name jumpstarter-server
kind create cluster --config=kind-config.yaml
```

#### Pods starten nicht

```bash
# Pod Logs überprüfen
kubectl describe pods -n jumpstarter-system
kubectl logs <pod-name> -n jumpstarter-system

# Events überprüfen
kubectl get events -n jumpstarter-system --sort-by='.lastTimestamp'
```

#### Ingress funktioniert nicht

```bash
# Ingress Controller Status
kubectl get pods -n ingress-nginx
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx

# /etc/hosts für lokale Tests
echo "127.0.0.1 jumpstarter.local" | sudo tee -a /etc/hosts
```

## 9. Cleanup

### Umgebung aufräumen

```bash
# Deployments löschen
kubectl delete -f router-deployment.yaml
kubectl delete -f controller-deployment.yaml
kubectl delete namespace jumpstarter-system

# Kind Cluster löschen
kind delete cluster --name jumpstarter-server

# /etc/hosts Eintrag entfernen (falls hinzugefügt)
sudo sed -i '/jumpstarter.local/d' /etc/hosts
```

## Weitere Ressourcen

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [DevContainers Documentation](https://containers.dev/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

---

Diese Anweisungen bieten eine vollständige Anleitung zum Aufsetzen eines Jumpstarter Servers mit kind und DevContainer-Integration für lokale Entwicklung und Tests.
