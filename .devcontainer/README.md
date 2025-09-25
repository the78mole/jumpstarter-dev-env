# DevContainer Configuration

Diese devcontainer-Konfiguration verwendet das externe Image `ghcr.io/the78mole/jumpstarter-dev:latest`.

## Änderungen

- **Dockerfile.backup**: Ursprüngliche Dockerfile-Konfiguration als Referenz
- **devcontainer.json**: Konfiguriert für externes Image mit Docker-in-Docker Support

## Externe Image Features

Das externe Image `ghcr.io/the78mole/jumpstarter-dev:latest` enthält bereits:
- kubectl und Helm
- uv (Python Package Manager)
- Jumpstarter CLI
- Robot Framework
- Alle notwendigen Development Tools

Nur Docker-in-Docker wird als Feature hinzugefügt, da dies zur Laufzeit benötigt wird.
