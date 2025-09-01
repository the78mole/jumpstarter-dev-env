# Jumpstarter Server Development Environment

A complete development environment for Jumpstarter using Kubernetes (Kind) with Docker-in-Docker support.

## Features

- 🐳 **Docker-in-Docker** setup for isolated development
- ⚓ **Kubernetes (Kind)** cluster with official Jumpstarter configuration
- 🎯 **Auto-installation** of Jumpstarter via Helm
- 🔧 **VS Code DevContainer** with all tools pre-installed
- 🌐 **Direct localhost access** to all services

## Quick Start

### Option 1: DevContainer (Recommended)

1. Open this repository in VS Code
2. Click "Reopen in Container" when prompted
3. Wait for automatic setup to complete
4. Test with: `./scripts/test.sh`

### Option 2: Manual Setup

```bash
# 1. Install tools
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/

# 2. Run setup
bash .devcontainer/setup-dind.sh
```

## Pre-installed Tools

The DevContainer includes all necessary tools:

- ✅ **Docker** (Docker-in-Docker)
- ✅ **kubectl** (Latest stable)
- ✅ **Helm** (Latest version)
- ✅ **Kind** (v0.20.0)
- ✅ **k9s** (Kubernetes Dashboard)
- ✅ **Network tools** (netcat, telnet)
- ✅ **JSON tools** (jq)

## Service Access

With Docker-in-Docker, all services are directly accessible:

- 🌐 **Web Interface**: http://localhost:5080
- 🔗 **GRPC Controller**: localhost:8082
- 🔗 **GRPC Router**: localhost:8083
- 📊 **k9s Dashboard**: Run `k9s` in terminal

## Project Structure

```
├── .devcontainer/          # DevContainer configuration
│   ├── Dockerfile         # Custom image with tools
│   ├── devcontainer.json  # VS Code DevContainer config
│   └── setup-dind.sh      # Automatic setup script
├── .vscode/               # VS Code settings
├── scripts/               # Utility scripts
│   ├── test.sh           # Comprehensive test suite
│   └── fix-vscode-kubectl.sh # kubectl troubleshooting
├── kind-config.yaml       # Kind cluster configuration
├── DOCKER-IN-DOCKER.md   # Setup documentation
└── README.md             # This file
```

## Available Commands

```bash
# Test everything
./scripts/test.sh

# Fix VS Code kubectl issues
./scripts/fix-vscode-kubectl.sh

# Manual setup (if needed)
bash .devcontainer/setup-dind.sh

# Access Kubernetes dashboard
k9s

# Check cluster status
kubectl get pods -n jumpstarter-lab
kubectl get svc -n jumpstarter-lab
kubectl get ingress -n jumpstarter-lab
```

## Troubleshooting

### kubectl not working in VS Code
1. Reload VS Code window: `Ctrl+Shift+P` → "Developer: Reload Window"
2. Or run: `./scripts/fix-vscode-kubectl.sh`

### Ports not accessible
1. Rebuild DevContainer: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
2. Or check if Docker-in-Docker is working: `docker ps`

### Jumpstarter not starting
1. Check pods: `kubectl get pods -n jumpstarter-lab`
2. Check logs: `kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-controller`

## Architecture

This setup uses:
- **Kind** for local Kubernetes cluster
- **Docker-in-Docker** for proper port mapping
- **NGINX Ingress** for web access
- **Helm** for Jumpstarter installation
- **NodePorts** for GRPC services

See [DOCKER-IN-DOCKER.md](DOCKER-IN-DOCKER.md) for detailed technical information.

## License

See [LICENSE](LICENSE) file.
