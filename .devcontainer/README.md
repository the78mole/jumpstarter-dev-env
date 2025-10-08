# DevContainer Configuration

This devcontainer configuration uses the external image `ghcr.io/the78mole/jumpstarter-dev:latest`.

## Changes

- **Dockerfile.backup**: Original Dockerfile configuration as reference
- **devcontainer.json**: Configured for external image with Docker-in-Docker support

## External Image Features

The external image `ghcr.io/the78mole/jumpstarter-dev:latest` already contains:
- kubectl and Helm
- uv (Python Package Manager)
- Jumpstarter CLI
- Robot Framework
- All necessary development tools

Only Docker-in-Docker is added as a feature because it is required at runtime.
