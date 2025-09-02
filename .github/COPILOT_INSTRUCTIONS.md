# Jumpstarter DevContainer Setup

These instructions describe the automated DevContainer setup for Jumpstarter with Kind (Kubernetes in Docker), based on Helm Charts and modern DevContainer features.

## Overview

The jumpstarter-server is a fully automated Kubernetes development environment with:

- **Kind Cluster**: 3-node Kubernetes cluster with Ingress Controller
- **Jumpstarter Services**: Controller and Router via Helm Chart deployment
- **DevContainer**: Docker-in-Docker with automated setup
- **UV Package Manager**: Python 3.11 environment with modern dependency management
- **Robot Framework**: Comprehensive integration tests

## Quick Start

### 1. Open DevContainer

```bash
# Open VS Code DevContainer
# Automatic setup starts automatically via setup-dind.sh
```

### 2. Check Services

```bash
# Test all services
make network-test

# Check services manually
kubectl get pods -n jumpstarter-system
kubectl get svc -n jumpstarter-system
```

### 3. Use Jumpstarter

```bash
# Create example exporter
make create-exporter

# Run tests
make test-robot
```

## DevContainer Architecture

### Automated Features

- **Docker-in-Docker**: Via official Microsoft feature
- **Kubernetes Tools**: kubectl, helm, kind via devcontainers feature
- **Python Environment**: Python 3.11 with UV package manager
- **VS Code Extensions**: Kubernetes Tools, Python, Robot Framework

### Service Access

```bash
# Controller (NodePort 30010)
curl http://localhost:30010/v1/health

# Router (NodePort 30011)
curl http://localhost:30011/v1/health

# Kubernetes Dashboard
kubectl port-forward svc/kubernetes-dashboard 8080:80 -n kubernetes-dashboard
```

## Automated Setup

### .devcontainer/setup-dind.sh

The setup script automatically performs the following steps:

1. **Docker-in-Docker Configuration**
2. **Kind Cluster Creation** (3 nodes + Ingress)
3. **Jumpstarter Helm Installation**
4. **Python Environment Setup** with UV
5. **Service Validation**

### Configuration Files

```text
.devcontainer/
├── devcontainer.json          # DevContainer Configuration
├── setup-dind.sh             # Automated Setup
└── features/
    └── uv/                    # UV Package Manager Feature

kind-config.yaml               # Kind Cluster Configuration
pyproject.toml                 # Python Dependencies (UV)
uv.lock                        # Dependency Lock File
```

## Development

### Make Targets

```bash
# Development environment
make dev                       # Setup/Start Jumpstarter
make network-test             # Service Connectivity Tests
make logs                     # Show service logs

# Python/UV
make install                  # Install dependencies
make shell                    # UV-managed shell

# Testing
make test-robot              # Robot Framework Tests
make test-robot-tags TAGS=health  # Specific tests

# Examples
make create-exporter         # Create mock exporter
make run-exporter           # Start exporter
make client-shell           # Client shell
```

### Robot Framework Tests

Comprehensive test suite with 8 tests:

```bash
# Run all tests
make test-robot

# Test categories
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

**Complete Integration** (`.github/workflows/test-jumpstarter-setup.yml`):
- DevContainer setup with Docker-in-Docker
- Kind cluster + Jumpstarter installation
- Robot Framework test execution
- Artifact collection on failures

**Quick Validation** (`.github/workflows/quick-validation.yml`):
- Syntax checks for Python/YAML/Robot
- Dependency resolution testing
- Quick smoke tests

### UV Package Management

Modern Python dependency management:

```toml
# pyproject.toml
[dependency-groups]
test = ["robotframework", "requests", "robotframework-requests"]

[tool.uv]
dev-dependencies = ["jumpstarter"]
```

```bash
# UV commands
uv sync                      # Install dependencies
uv run python script.py     # Run Python with dependencies
uv run jmp --help          # Jumpstarter CLI
```

## Troubleshooting

### Common Issues

**DevContainer setup failed:**
```bash
# Recreate container
docker system prune -f
# VS Code: "Dev Containers: Rebuild Container"
```

**Services not accessible:**
```bash
# Repeat setup
.devcontainer/setup-dind.sh

# Check service status
kubectl get pods -n jumpstarter-system
kubectl describe pod <pod-name> -n jumpstarter-system
```

**Robot tests failing:**
```bash
# Validate test environment
make network-test

# Debug individual tests
robot --include health --loglevel DEBUG tests/robot/
```

### Debug Commands

```bash
# Cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Jumpstarter logs
kubectl logs -f deployment/jumpstarter-controller -n jumpstarter-system
kubectl logs -f deployment/jumpstarter-router -n jumpstarter-system

# Docker-in-Docker status
docker ps
docker exec -it kind-control-plane crictl ps
```

## Architecture Details

### Kind Cluster Configuration

```yaml
# kind-config.yaml
- 1x Control Plane Node (with Ingress-capable)
- 2x Worker Nodes
- NodePort mappings: 30010 (Controller), 30011 (Router)
- Ingress Controller: NGINX
```

### Jumpstarter Helm Chart

```bash
# Helm installation (automated)
helm upgrade --install jumpstarter ./helm-chart/jumpstarter \
  --namespace jumpstarter-system \
  --create-namespace \
  --values helm-chart/jumpstarter/values.yaml \
  --wait
```

### DevContainer Features

```json
// devcontainer.json (excerpt)
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
make create-exporter    # Creates exporter with mock drivers

# Client Connection
make client-shell       # Connect to mock hardware
# In client shell:
power.get()            # Test mock power driver
storage.list()         # Test mock storage driver
```

### CI/CD Testing

Robot Framework tests are optimized for DevContainer environment:

```robot
# Adapted for container networking
${result}=    Run Process    docker    exec    kind-control-plane
...           kubectl    get    pods    -n    jumpstarter-system
```

## Further Resources

- **Jumpstarter Documentation**: [jumpstarter.dev](https://jumpstarter.dev)
- **DevContainer Specs**: [containers.dev](https://containers.dev)
- **UV Package Manager**: [docs.astral.sh/uv](https://docs.astral.sh/uv)
- **Robot Framework**: [robotframework.org](https://robotframework.org)
- **Kind Documentation**: [kind.sigs.k8s.io](https://kind.sigs.k8s.io)

---

This documentation describes the fully automated DevContainer setup for Jumpstarter development with modern tools and comprehensive tests.
