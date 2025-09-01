# Jumpstarter Server Development Environment

[![Test Jumpstarter Setup](https://github.com/the78mole/jumpstarter-server/actions/workflows/test-jumpstarter-setup.yml/badge.svg)](https://github.com/the78mole/jumpstarter-server/actions/workflows/test-jumpstarter-setup.yml)
[![Quick Validation](https://github.com/the78mole/jumpstarter-server/actions/workflows/quick-validation.yml/badge.svg)](https://github.com/the78mole/jumpstarter-server/actions/workflows/quick-validation.yml)

A complete development environment for Jumpstarter using Kubernetes (Kind) with Docker-in-Docker support.

## Features

- 🐳 **Docker-in-Docker** setup for isolated development
- ⚓ **Kubernetes (Kind)** cluster with official Jumpstarter configuration
- 🎯 **Auto-installation** of Jumpstarter via Helm
- 🔧 **VS Code DevContainer** with all tools pre-installed
- 🌐 **Direct localhost access** to all services
- 🤖 **Automated CI/CD** with GitHub Actions and Robot Framework tests

## Quick Start

### Option 1: DevContainer (Recommended)

1. Open this repository in VS Code
2. Click "Reopen in Container" when prompted
3. After DevContainer starts, run: `make dev`
4. Test with: `make test-robot`

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
- ✅ **UV** (Python package manager)
- ✅ **Python 3.11** with Jumpstarter dependencies
- ✅ **Robot Framework** for integration testing
- ✅ **Network tools** (netcat, telnet)
- ✅ **JSON tools** (jq)

## Service Access

After running `make dev`, services are accessible via NodePorts:

- 🔗 **GRPC Controller**: localhost:30010 (NodePort)
- 🔗 **GRPC Router**: localhost:30011 (NodePort)
- 🌐 **Ingress Controller**: Available inside Kind cluster
- 📊 **k9s Dashboard**: Run `k9s` in terminal

> **Note**: In DevContainer environments, direct port mapping may have limitations. Services are guaranteed accessible via kubectl port-forward or from within the Kind cluster.

## Project Structure

```
jumpstarter-server/
├── .devcontainer/         # DevContainer configuration
│   ├── devcontainer.json # Docker-in-Docker + Python + UV
│   ├── Dockerfile        # Custom container with tools
│   └── setup-dind.sh     # Automatic setup script
├── .github/workflows/    # CI/CD automation
│   ├── test-jumpstarter-setup.yml # Full integration tests
│   └── quick-validation.yml # Fast syntax validation
├── .vscode/              # VS Code settings
├── scripts/              # Utility scripts
│   ├── welcome.sh        # DevContainer welcome message
│   └── fix-vscode-kubectl.sh # kubectl troubleshooting
├── tests/robot/          # Robot Framework integration tests
│   ├── jumpstarter_integration.robot # Test suite
│   ├── keywords/         # Custom Robot Framework keywords
│   └── resources/        # Test resources and configurations
├── examples/             # Python examples and exporters
│   ├── create_exporter.py # Distributed mode example
│   └── example-distributed.yaml # Exporter configuration
├── kind-config.yaml      # Kind cluster configuration
├── pyproject.toml        # Python dependencies (UV managed)
├── uv.lock              # UV lockfile for reproducible builds
├── Makefile              # Development commands
├── DOCKER-IN-DOCKER.md  # Setup documentation
└── README.md            # This file
```

## Available Commands

```bash
# Development Environment
make dev              # Complete setup (recommended)
make status           # Check service status  
make test             # Run connectivity tests

# Service Management
make setup            # Create Kind cluster + NGINX
make deploy           # Install Jumpstarter via Helm
make logs             # Show recent logs
make teardown         # Remove Jumpstarter (keep cluster)
make clean            # Delete entire cluster
make restart          # Restart Jumpstarter services

# Python & Exporter Development
make python-setup     # Install Python dependencies
make create-exporter  # Create example exporter
make run-exporter     # Start the exporter (foreground)
make client-shell     # Connect to exporter
make python-shell     # Python REPL with Jumpstarter

# Testing & Quality Assurance
make test-robot       # Run Robot Framework integration tests
make test-robot-quick # Validate Robot Framework tests (dry-run)

# Troubleshooting
make troubleshoot     # Fix kubectl/VS Code issues
make k9s              # Kubernetes dashboard (jumpstarter-lab namespace)
make k9s-all          # Kubernetes dashboard (all namespaces)
```

## Python Development

The project uses **UV** for modern Python dependency management with Python 3.11:

```bash
# Setup Python environment (automatic with make dev)
make python-setup

# Create and test an exporter
make create-exporter
make run-exporter     # In one terminal
make client-shell     # In another terminal

# Direct CLI usage
uv run jmp --help
uv run jmp admin --help
uv run jmp admin get --help        # List available objects
uv run jmp admin create exporter my-exporter
```

## Manual Commands

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

## Testing & CI/CD

This project includes comprehensive automated testing:

### 🤖 **Robot Framework Integration Tests**
```bash
# Run tests locally via Makefile
make test-robot

# Or run directly with UV
uv run robot --outputdir tests/robot/results tests/robot/jumpstarter_integration.robot
```

### 🔄 **GitHub Actions Workflows**
- **Full Integration Test** (`.github/workflows/test-jumpstarter-setup.yml`)
  - Sets up complete Kind cluster with Jumpstarter
  - Tests mock exporter creation and connectivity
  - Runs Robot Framework test suite
  - 30-minute timeout for comprehensive testing
  
- **Quick Validation** (`.github/workflows/quick-validation.yml`)
  - Validates YAML, Makefile, and Python syntax
  - Dry-run Robot Framework tests
  - Fast feedback for pull requests

### 📊 **Test Coverage**
The Robot Framework tests cover:
- ✅ Web interface accessibility
- ✅ GRPC port connectivity (Controller & Router)
- ✅ DNS resolution for nip.io domains  
- ✅ Mock exporter creation and registration
- ✅ CLI command functionality
- ✅ Kubernetes pod health

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
