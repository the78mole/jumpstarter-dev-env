# Docker-in-Docker Setup für Jumpstarter

## Problem mit Docker-outside-of-Docker
Das ursprüngliche Setup verwendete Docker-outside-of-Docker, was zu Netzwerkproblemen führte:
- Kind-Container laufen im Host-Docker, nicht im Dev-Container
- Port-Mappings funktionieren nicht zwischen Dev-Container und Host
- Services sind nicht über localhost erreichbar

## Lösung: Docker-in-Docker
Die neue Konfiguration verwendet Docker-in-Docker:
- Alle Container laufen innerhalb des Dev-Containers
- Kubernetes Services sind über NodePorts erreichbar
- Robuste Netzwerk-Konfiguration für DevContainer-Umgebungen

## DevContainer Features

Das DevContainer nutzt offizielle Microsoft DevContainer Features:

### 🐳 **Docker-in-Docker**
- `ghcr.io/devcontainers/features/docker-in-docker:2`
- Vollständige Docker-Umgebung im Container

### ⚓ **Kubernetes Tools**  
- `ghcr.io/devcontainers/features/kubectl-helm-minikube:1`
- kubectl, Helm, und Minikube vorinstalliert

### 🐍 **Python 3.11**
- `ghcr.io/devcontainers/features/python:1`
- Moderne Python-Umgebung

### 📦 **UV Package Manager**
- `ghcr.io/jsburckhardt/devcontainer-features/uv:1`
- Schneller Python-Paketmanager von Astral

## Automatisches Setup

Das `setup-dind.sh` Script führt automatisch folgende Schritte aus:

1. **Docker-Daemon prüfen**: Wartet bis Docker verfügbar ist
2. **Kind-Cluster erstellen**: Mit `kind-config.yaml` Konfiguration  
3. **NGINX Ingress installieren**: Für HTTP/HTTPS Zugriff
4. **Jumpstarter installieren**: Via Helm Chart
5. **Services prüfen**: NodePort-Verfügbarkeit testen
6. **Python-Umgebung**: UV sync für Dependencies

## Umstellung durchführen

### 1. Dev-Container neu erstellen
Da die grundlegende Docker-Konfiguration geändert wurde, muss der Dev-Container neu erstellt werden:

1. **Command Palette öffnen** (Ctrl+Shift+P / Cmd+Shift+P)
2. **"Dev Containers: Rebuild Container"** ausführen
3. Warten bis der Container neu erstellt ist (kann länger dauern)

### 2. Automatisches Setup
Nach dem Neustart läuft automatisch das neue Setup:
- `bash .devcontainer/setup-dind.sh`
- Erstellt Kind-Cluster mit localhost-Konfiguration
- Installiert Jumpstarter mit korrekten Port-Mappings

### 3. Testen
Nach dem Setup können Sie testen:
```bash
./scripts/test.sh
```

## Service-Zugriff

### NodePort Services
Jumpstarter Services sind über Kubernetes NodePorts verfügbar:
- 🔗 **GRPC Controller**: localhost:30010 (NodePort)
- 🔗 **GRPC Router**: localhost:30011 (NodePort)

### Ingress Controller
- 🌐 **HTTP Ingress**: Läuft im Cluster (DevContainer-Limitierungen beachten)
- 🔑 **Domains**: `*.jumpstarter.127.0.0.1.nip.io`

### Kubectl Port-Forward
Für direkten Service-Zugriff:
```bash
# Controller Service
kubectl port-forward -n jumpstarter-lab svc/jumpstarter-grpc 8082:8082

# Router Service  
kubectl port-forward -n jumpstarter-lab svc/jumpstarter-router-grpc 8083:8083
```

## Testing & Validation

### Robot Framework Tests
Vollständige Test-Suite mit 8 Tests:
```bash
make test-robot
```

### Manuelle Tests
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

## Vorteile der aktuellen Lösung
- ✅ **Robuste Netzwerk-Konfiguration**: NodePorts funktionieren zuverlässig
- ✅ **DevContainer-optimiert**: Realistische Erwartungen für Container-Umgebungen
- ✅ **Vollständige Automatisierung**: Ein Befehl für komplettes Setup
- ✅ **CI/CD Integration**: GitHub Actions mit identischer Konfiguration
- ✅ **Umfassende Tests**: Robot Framework validiert alle Komponenten
- ✅ **Modern Python Stack**: UV + Python 3.11 für schnelle Dependencies

## DevContainer-Limitierungen
- ⚠️ **Port-Mapping**: Nicht alle Host-Ports funktionieren in DevContainers
- ⚠️ **Ingress-Zugriff**: HTTP-Zugriff funktioniert hauptsächlich cluster-intern
- ⚠️ **Netzwerk-Komplexität**: Docker-in-Docker + Kind + DevContainer

## Lösungsansätze
- ✅ **NodePort-Services**: Zuverlässiger Zugriff über definierte Ports
- ✅ **kubectl exec**: Commands im Kind-Container ausführen
- ✅ **Realistische Tests**: Prüfen was in DevContainers machbar ist
- ✅ **Kubectl Port-Forward**: Flexibler Service-Zugriff

Diese Konfiguration bietet eine stabile, reproduzierbare Entwicklungsumgebung für Jumpstarter.
