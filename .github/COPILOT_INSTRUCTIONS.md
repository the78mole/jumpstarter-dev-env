# Jumpstarter DevContainer Setup

Diese Anweisungen beschreiben das automatisierte DevContainer-Setup für Jumpstarter mit Kind (Kubernetes in Docker), basierend auf Helm Charts und modernen DevContainer-Features.

## Überblick

Der jumpstarter-server ist eine vollständig automatisierte Kubernetes-Entwicklungsumgebung mit:

- **Kind Cluster**: 3-Node Kubernetes Cluster mit Ingress Controller
- **Jumpstarter Services**: Controller und Router via Helm Chart deployment
- **DevContainer**: Docker-in-Docker mit automatisiertem Setup
- **UV Package Manager**: Python 3.11 Umgebung mit modernem Dependency Management
- **Robot Framework**: Umfassende Integrationstests

## Schnellstart

### 1. DevContainer öffnen

```bash
# VS Code DevContainer öffnen
# Automatisches Setup startet automatisch via setup-dind.sh
```

### 2. Services überprüfen

```bash
# Alle Services testen
make network-test

# Services manuell überprüfen
kubectl get pods -n jumpstarter-system
kubectl get svc -n jumpstarter-system
```

### 3. Jumpstarter verwenden

```bash
# Beispiel-Exporter erstellen
make create-exporter

# Tests ausführen
make test-robot
```

## DevContainer Architektur

### Automatisierte Features

- **Docker-in-Docker**: Über official Microsoft feature
- **Kubernetes Tools**: kubectl, helm, kind via devcontainers feature  
- **Python Environment**: Python 3.11 mit UV package manager
- **VS Code Extensions**: Kubernetes Tools, Python, Robot Framework

### Service Zugriff

```bash
# Controller (NodePort 30010)
curl http://localhost:30010/v1/health

# Router (NodePort 30011) 
curl http://localhost:30011/v1/health

# Kubernetes Dashboard
kubectl port-forward svc/kubernetes-dashboard 8080:80 -n kubernetes-dashboard
```

## Automatisiertes Setup

### .devcontainer/setup-dind.sh

Das Setup-Script führt folgende Schritte automatisch aus:

1. **Docker-in-Docker Konfiguration**
2. **Kind Cluster Erstellung** (3 Nodes + Ingress)
3. **Jumpstarter Helm Installation**
4. **Python Environment Setup** mit UV
5. **Service Validierung**

### Konfigurationsdateien

```text
.devcontainer/
├── devcontainer.json          # DevContainer Konfiguration
├── setup-dind.sh             # Automatisiertes Setup
└── features/
    └── uv/                    # UV Package Manager Feature

kind-config.yaml               # Kind Cluster Konfiguration
pyproject.toml                 # Python Dependencies (UV)
uv.lock                        # Dependency Lock File
```

## Entwicklung

### Make Targets

```bash
# Entwicklungsumgebung
make dev                       # Setup/Start Jumpstarter
make network-test             # Service Connectivity Tests
make logs                     # Service Logs anzeigen

# Python/UV
make install                  # Dependencies installieren
make shell                    # UV-managed Shell

# Testing
make test-robot              # Robot Framework Tests
make test-robot-tags TAGS=health  # Spezifische Tests

# Examples
make create-exporter         # Mock Exporter erstellen
make run-exporter           # Exporter starten
make client-shell           # Client Shell
```

### Robot Framework Tests

Umfassende Testsuite mit 8 Tests:

```bash
# Alle Tests ausführen
make test-robot

# Test-Kategorien
robot --include health tests/robot/    # Health Checks
robot --include network tests/robot/   # Network Tests  
robot --include cli tests/robot/       # CLI Tests
```

**Test Coverage:**
- Controller/Router Health Checks
- GRPC Port Connectivity  
- DNS Resolution
- Kubernetes Pod Status
- CLI Functionality

## CI/CD Integration

### GitHub Actions Workflows

**Vollständige Integration** (`.github/workflows/test-jumpstarter-setup.yml`):
- DevContainer Setup mit Docker-in-Docker
- Kind Cluster + Jumpstarter Installation  
- Robot Framework Test-Ausführung
- Artefakt-Sammlung bei Fehlern

**Schnelle Validierung** (`.github/workflows/quick-validation.yml`):
- Syntax Checks für Python/YAML/Robot
- Dependency Resolution Testing
- Schnelle Smoke Tests

### UV Package Management

Modernes Python Dependency Management:

```toml
# pyproject.toml
[dependency-groups]
test = ["robotframework", "requests", "robotframework-requests"]

[tool.uv]
dev-dependencies = ["jumpstarter"]
```

```bash
# UV Befehle
uv sync                      # Dependencies installieren
uv run python script.py     # Python mit Abhängigkeiten ausführen
uv run jmp --help          # Jumpstarter CLI
```

## Troubleshooting

### Häufige Probleme

**DevContainer Setup fehlgeschlagen:**
```bash
# Container neu erstellen
docker system prune -f
# VS Code: "Dev Containers: Rebuild Container"
```

**Services nicht erreichbar:**
```bash
# Setup wiederholen
.devcontainer/setup-dind.sh

# Service Status prüfen
kubectl get pods -n jumpstarter-system
kubectl describe pod <pod-name> -n jumpstarter-system
```

**Robot Tests fehlschlagen:**
```bash
# Test-Umgebung validieren
make network-test

# Einzelne Tests debuggen  
robot --include health --loglevel DEBUG tests/robot/
```

### Debug-Befehle

```bash
# Cluster Status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Jumpstarter Logs
kubectl logs -f deployment/jumpstarter-controller -n jumpstarter-system
kubectl logs -f deployment/jumpstarter-router -n jumpstarter-system

# Docker-in-Docker Status
docker ps
docker exec -it kind-control-plane crictl ps
```

## Architektur-Details

### Kind Cluster Konfiguration

```yaml
# kind-config.yaml
- 1x Control Plane Node (mit Ingress-fähig)
- 2x Worker Nodes  
- NodePort Mappings: 30010 (Controller), 30011 (Router)
- Ingress Controller: NGINX
```

### Jumpstarter Helm Chart

```bash
# Helm Installation (automatisiert)
helm upgrade --install jumpstarter ./helm-chart/jumpstarter \
  --namespace jumpstarter-system \
  --create-namespace \
  --values helm-chart/jumpstarter/values.yaml \
  --wait
```

### DevContainer Features

```json
// devcontainer.json (Auszug)
"features": {
  "ghcr.io/devcontainers/features/docker-in-docker:2": {},
  "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {
    "kubectl": "latest", "helm": "latest", "minikube": "none"
  },
  "ghcr.io/jsburckhardt/devcontainer-features/uv:1": {}
}
```

## Integration Patterns

### Distributed Mode Testing

```bash
# Mock Hardware Exporter
make create-exporter    # Erstellt Exporter mit Mock Drivers

# Client Connection
make client-shell       # Verbindung zu Mock Hardware
# In Client Shell:
power.get()            # Mock Power Driver testen
storage.list()         # Mock Storage Driver testen
```

### CI/CD Testing

Robot Framework Tests sind für DevContainer-Umgebung optimiert:

```robot
# Angepasst für Container-Networking
${result}=    Run Process    docker    exec    kind-control-plane    
...           kubectl    get    pods    -n    jumpstarter-system
```

## Weiterführende Ressourcen

- **Jumpstarter Documentation**: [jumpstarter.dev](https://jumpstarter.dev)
- **DevContainer Specs**: [containers.dev](https://containers.dev)
- **UV Package Manager**: [docs.astral.sh/uv](https://docs.astral.sh/uv)
- **Robot Framework**: [robotframework.org](https://robotframework.org)
- **Kind Documentation**: [kind.sigs.k8s.io](https://kind.sigs.k8s.io)

---

Diese Dokumentation beschreibt das vollständig automatisierte DevContainer-Setup für Jumpstarter-Entwicklung mit modernen Tools und umfassenden Tests.
