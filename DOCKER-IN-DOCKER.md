# Docker-in-Docker Setup for Jumpstarter

## Problem with Docker-outside-of-Docker
The original setup used Docker-outside-of-Docker, which led to networking issues:
- Kind containers run in host Docker, not in the dev container
- Port mappings don't work between dev container and host
- Services are not accessible via localhost

## Solution: Docker-in-Docker
The new configuration uses Docker-in-Docker:
- All containers run within the dev container
- Kubernetes services are accessible via NodePorts
- Robust network configuration for DevContainer environments

## DevContainer Features

The DevContainer uses official Microsoft DevContainer features:

### 🐳 **Docker-in-Docker**
- `ghcr.io/devcontainers/features/docker-in-docker:2`
- Complete Docker environment in container

### ⚓ **Kubernetes Tools**
- `ghcr.io/devcontainers/features/kubectl-helm-minikube:1`
- kubectl, Helm, and Minikube pre-installed

### 🐍 **Python 3.11**
- `ghcr.io/devcontainers/features/python:1`
- Modern Python environment

### 📦 **UV Package Manager**
- `ghcr.io/jsburckhardt/devcontainer-features/uv:1`
- Fast Python package manager by Astral

## Automated Setup

The `setup-dind.sh` script automatically performs the following steps:

1. **Check Docker daemon**: Waits until Docker is available
2. **Create Kind cluster**: With `kind-config.yaml` configuration
3. **Install NGINX Ingress**: For HTTP/HTTPS access
4. **Install Jumpstarter**: Via Helm Chart
5. **Check services**: Test NodePort availability
6. **Python environment**: UV sync for dependencies

## Performing the Migration

### 1. Recreate Dev Container
Since the fundamental Docker configuration has changed, the dev container must be recreated:

1. **Open Command Palette** (Ctrl+Shift+P / Cmd+Shift+P)
2. **Execute "Dev Containers: Rebuild Container"**
3. Wait until the container is recreated (may take longer)

### 2. Automatic Setup
After restart, the new setup runs automatically:
- `bash .devcontainer/setup-dind.sh`
- Creates Kind cluster with localhost configuration
- Installs Jumpstarter with correct port mappings

### 3. Testing
After setup, you can test:
```bash
./scripts/test.sh
```

## Service Access

### NodePort Services
Jumpstarter services are available via Kubernetes NodePorts:
- 🔗 **GRPC Controller**: localhost:30010 (NodePort)
- 🔗 **GRPC Router**: localhost:30011 (NodePort)

### Ingress Controller
- 🌐 **HTTP Ingress**: Runs in cluster (consider DevContainer limitations)
- 🔑 **Domains**: `*.jumpstarter.127.0.0.1.nip.io`

### Kubectl Port-Forward
For direct service access:
```bash
# Controller Service
kubectl port-forward -n jumpstarter-lab svc/jumpstarter-grpc 8082:8082

# Router Service
kubectl port-forward -n jumpstarter-lab svc/jumpstarter-router-grpc 8083:8083
```

## Testing & Validation

### Robot Framework Tests
Complete test suite with 8 tests:
```bash
make test-robot
```

### Manual Tests
```bash
# Cluster Status
kubectl get pods -n jumpstarter-lab
kubectl get svc -n jumpstarter-lab

# Service Connectivity
nc -z localhost 30010  # Controller
nc -z localhost 30011  # Router

# Python CLI
uv run jmp admin --help
uv run jmp admin get --help
```

## Advantages of Current Solution
- ✅ **Robust network configuration**: NodePorts work reliably
- ✅ **DevContainer-optimized**: Realistic expectations for container environments
- ✅ **Complete automation**: One command for complete setup
- ✅ **CI/CD integration**: GitHub Actions with identical configuration
- ✅ **Comprehensive tests**: Robot Framework validates all components
- ✅ **Modern Python stack**: UV + Python 3.11 for fast dependencies

## DevContainer Limitations
- ⚠️ **Port mapping**: Not all host ports work in DevContainers
- ⚠️ **Ingress access**: HTTP access works mainly cluster-internal
- ⚠️ **Network complexity**: Docker-in-Docker + Kind + DevContainer

## Solution Approaches
- ✅ **NodePort services**: Reliable access via defined ports
- ✅ **kubectl exec**: Execute commands in Kind container
- ✅ **Realistic tests**: Check what's feasible in DevContainers
- ✅ **Kubectl port-forward**: Flexible service access

This configuration provides a stable, reproducible development environment for Jumpstarter.
