# Jumpstarter Server - AI Coding Agent Instructions

## Architecture Overview

This is a **Docker-in-Docker Kubernetes development environment** for Jumpstarter, not application source code. The project provides:

- **3-node Kind cluster** with automated setup via `.devcontainer/setup-dind.sh`
- **Jumpstarter services** deployed via Helm chart (Controller + Router)
- **Python 3.11 + UV** package management for examples and testing
- **Robot Framework** integration tests with CI/CD workflows

## Essential Commands

**Primary workflow:** Use `make dev` for complete environment setup. This runs the automated setup script and ensures all services are running.

**Testing:** Use `make test-robot` to run comprehensive integration tests, or `make test` for network connectivity checks.

**Python/Exporter development:** Use `make create-exporter` and `make run-exporter` to test distributed mode with mock drivers.

## Service Architecture

Services run in Kubernetes namespace `jumpstarter-lab` with NodePort access:
- **Controller GRPC**: `localhost:8082` (NodePort 30010)
- **Router GRPC**: `localhost:8083` (NodePort 30011)
- **Web Interface**: `http://localhost:5080` (NodePort mapping from port 8080)

## Key File Patterns

**Configuration files follow specific patterns:**
- `kind-config.yaml`: 3-node cluster with specific port mappings for Docker-in-Docker
- `pyproject.toml`: Uses UV dependency groups (`[project.optional-dependencies.testing]`)
- `Makefile`: All development commands with German comments and help system

**Testing patterns:**
- Robot Framework tests in `tests/robot/` adapted for CI container networking
- Tests validate NodePort services instead of direct port connectivity
- Mock exporter creation tests actual Jumpstarter CLI integration

## DevContainer Integration

The DevContainer uses Docker-in-Docker (with proper isolation) with:
- Dedicated Docker daemon inside the container for better isolation
- Automated setup via `postCreateCommand: "bash scripts/welcome.sh"`
- Pre-configured VS Code extensions for Kubernetes, Python, and Robot Framework
- Port forwarding for NodePorts (30010, 30011) and web interfaces

## CI/CD Workflows

**Two-tier testing approach:**
- `quick-validation.yml`: Syntax validation and dry-run tests (fast feedback)
- `test-jumpstarter-setup.yml`: Full environment setup with Robot Framework tests (30min timeout)

## Python Development Patterns

**UV package management:** Use `uv run jmp` prefix for Jumpstarter CLI commands instead of direct installation.

**Mock driver integration:** The `examples/create_exporter.py` script demonstrates programmatic exporter creation with YAML config manipulation for mock storage and power drivers.

**Client-exporter workflow:** Always create both exporter and client (`make create-exporter` + `make create-client`), then test with `make exporter-shell`.

## Common Development Commands

```bash
# Development Environment
make dev              # Complete setup (recommended)
make status           # Check service status
make test             # Run connectivity tests

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

# Cleanup & Maintenance
make teardown         # Remove Jumpstarter (keep cluster)
make clean            # Delete Kind cluster only
make cleanup          # Complete cleanup: cluster, containers, networks, images
```

## Troubleshooting Conventions

**Network issues:** Run `scripts/test.sh` to validate all service connectivity and get detailed logs.

**DevContainer problems:** Use `make troubleshoot` which runs `scripts/fix-vscode-kubectl.sh` to fix VS Code kubectl integration issues.

**Service debugging:** Use `make k9s` for namespace-scoped monitoring or `make k9s-all` for cluster-wide view.

**Complete reset:** Use `make cleanup` to remove everything (cluster, containers, networks, images) and start fresh with `make dev`.

## Integration Points

**Kubernetes:** Services expect specific namespace (`jumpstarter-lab`) and rely on NGINX Ingress Controller with Kind-specific configuration.

**External dependencies:** Jumpstarter Helm chart from `oci://quay.io/jumpstarter-dev/helm/jumpstarter` with version pinning in Makefile.

**DNS resolution:** Uses nip.io domains for Ingress but tests validate NodePort access for CI compatibility.
