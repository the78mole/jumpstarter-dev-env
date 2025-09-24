.PHONY: help setup teardown deploy test status logs clean dev python-setup create-exporter run-exporter create-client exporter-shell k9s k9s-all test-robot test-robot-quick test-integration ci-test

help: ## Zeigt diese Hilfe an
	@echo "Jumpstarter Server - Make Commands:"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

dev: ## Startet die komplette Entwicklungsumgebung (empfohlen)
	@echo "🚀 Starting Jumpstarter development environment..."
	@./.devcontainer/setup-dind.sh

setup: ## Erstellt Kind Cluster und installiert NGINX Ingress
	@echo "Creating kind cluster with jumpstarter configuration..."
	@if ! kind get clusters | grep -q "^jumpstarter-server$$"; then \
		kind create cluster --name jumpstarter-server --config=kind-config.yaml; \
	else \
		echo "Kind cluster 'jumpstarter-server' already exists"; \
	fi
	@echo "Installing NGINX Ingress Controller..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "Waiting for ingress controller to be ready..."
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
	@echo "✅ Setup complete!"

deploy: ## Installiert Jumpstarter via Helm Chart
	@echo "Installing Jumpstarter via Helm..."
	@if ! helm list -A | grep -q jumpstarter; then \
		helm install jumpstarter oci://quay.io/jumpstarter-dev/helm/jumpstarter --version 0.7.0-dev-8-g83e23d3; \
		echo "Waiting for pods to be ready..."; \
		sleep 10; \
		kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jumpstarter --timeout=120s; \
	else \
		echo "Jumpstarter already installed"; \
	fi
	@echo "✅ Deployment complete!"

status: ## Zeigt Status aller Pods und Services an
	@echo "📊 Jumpstarter Status:"
	@echo ""
	@echo "Pods:"
	kubectl get pods -n jumpstarter-lab
	@echo ""
	@echo "Services:"
	kubectl get svc -n jumpstarter-lab
	@echo ""
	@echo "🌐 Access URLs:"
	@echo "  HTTP Interface:   http://localhost:5080 (not used by browser)"
	@echo "  GRPC Controller:  localhost:8082 (NodePort 30010)"
	@echo "  GRPC Router:      localhost:8083 (NodePort 30011)"
	@echo ""
	@echo "ℹ️  Note: Use 'jmp shell --client <name>' to interact with exporters"

logs: ## Zeigt aktuelle Logs der Jumpstarter Pods an
	@echo "📋 Recent Jumpstarter Logs:"
	@echo ""
	@echo "Controller:"
	kubectl logs -n jumpstarter-lab -l control-plane=controller-manager --tail=10
	@echo ""
	@echo "Router:"
	kubectl logs -n jumpstarter-lab -l control-plane=controller-router --tail=10

test: ## Führt Netzwerk- und Service-Tests aus
	@echo "🔍 Running connectivity tests..."
	@./scripts/test.sh

k9s: ## Startet k9s Dashboard für Cluster-Überwachung
	@echo "🎯 Starting k9s dashboard in jumpstarter-lab namespace..."
	@echo "💡 Use 'Ctrl+A' in k9s to switch to all namespaces view"
	k9s -n jumpstarter-lab

k9s-all: ## Startet k9s Dashboard mit allen Namespaces
	@echo "🌐 Starting k9s dashboard with all namespaces..."
	k9s -A

teardown: ## Entfernt Jumpstarter Installation (behält Cluster)
	@echo "Removing Jumpstarter installation..."
	@if helm list -A | grep -q jumpstarter; then \
		helm uninstall jumpstarter; \
	else \
		echo "Jumpstarter not installed"; \
	fi
	@echo "✅ Teardown complete!"

clean: ## Löscht Kind Cluster komplett
	@echo "Deleting kind cluster..."
	kind delete cluster --name jumpstarter-server
	@echo "✅ Cluster deleted!"

cleanup: ## Räumt alles auf: Cluster, Docker-Container, Netzwerke, Images
	@echo "🧹 Complete cleanup - removing all Jumpstarter resources..."
	@echo "Step 1: Removing Jumpstarter installation..."
	@if helm list -A 2>/dev/null | grep -q jumpstarter; then \
		helm uninstall jumpstarter -n jumpstarter-lab; \
	else \
		echo "  No Jumpstarter Helm release found"; \
	fi
	@echo "Step 2: Deleting Kind cluster..."
	@if kind get clusters 2>/dev/null | grep -q jumpstarter-server; then \
		kind delete cluster --name jumpstarter-server; \
	else \
		echo "  No Kind cluster found"; \
	fi
	@echo "Step 3: Cleaning up Docker resources..."
	@echo "  Removing stopped containers..."
	@docker container prune -f 2>/dev/null || true
	@echo "  Removing unused networks..."
	@docker network prune -f 2>/dev/null || true
	@echo "  Removing dangling images..."
	@docker image prune -f 2>/dev/null || true
	@echo "✅ Complete cleanup finished!"
	@echo "💡 To restart: run 'make dev'"

restart: teardown deploy ## Neustart der Jumpstarter Komponenten
	@echo "🔄 Restarting Jumpstarter..."

full-setup: setup deploy status ## Komplettes Setup mit Status-Anzeige
	@echo "🎉 Full setup completed!"

troubleshoot: ## Hilfe bei kubectl/VS Code Problemen
	@echo "🔧 Running troubleshooting..."
	@./scripts/fix-vscode-kubectl.sh

setup-dns: ## Konfiguriert DNS für nip.io Domains
	@echo "🌐 Setting up DNS for Jumpstarter domains..."
	@echo "127.0.0.1 grpc.jumpstarter.127.0.0.1.nip.io" | sudo tee -a /etc/hosts
	@echo "127.0.0.1 router.jumpstarter.127.0.0.1.nip.io" | sudo tee -a /etc/hosts
	@echo "✅ DNS configured"

test-dns: ## Testet DNS-Auflösung
	@echo "🔍 Testing DNS resolution..."
	@ping -c 1 grpc.jumpstarter.127.0.0.1.nip.io
	@ping -c 1 router.jumpstarter.127.0.0.1.nip.io

# Python/Jumpstarter Commands

python-setup: ## Installiert Python Dependencies mit uv
	@echo "🐍 Setting up Python environment..."
	@if command -v uv >/dev/null 2>&1; then \
		echo "Installing dependencies with uv..."; \
		uv pip install jumpstarter-cli jumpstarter-driver-opendal jumpstarter-driver-power jumpstarter-driver-composite; \
		echo "✅ Python environment ready!"; \
		echo "💡 Usage:"; \
		echo "  make create-exporter"; \
		echo "  make run-exporter"; \
		echo "  make create-client"; \
		echo "  make exporter-shell"; \
	else \
		echo "❌ uv not found. Please rebuild the dev container."; \
	fi

create-exporter: ## Erstellt einen Beispiel-Exporter für Distributed Mode
	@echo "📦 Creating example exporter..."
	@mkdir -p ~/.config/jumpstarter/exporters
	jmp admin create exporter example-distributed --label environment=dev --save --insecure-tls-config --nointeractive --out ~/.config/jumpstarter/exporters/example-distributed.yaml 2>/dev/null || echo "Exporter may already exist"
	@cp examples/example-distributed.yaml ~/.config/jumpstarter/exporters/ 2>/dev/null || true
	@echo "✅ Exporter created: ~/.config/jumpstarter/exporters/example-distributed.yaml"

run-exporter: ## Startet den Beispiel-Exporter (Vordergrund)
	@echo "🚀 Starting exporter..."
	@echo "Note: This will run in foreground. Use Ctrl+C to stop."
	jmp run --exporter-config ~/.config/jumpstarter/exporters/example-distributed.yaml

create-client: ## Erstellt einen Client für den Exporter
	@echo "👤 Creating client..."
	@mkdir -p ~/.config/jumpstarter/clients
	jmp admin create client hello --save --unsafe --insecure-tls-config --nointeractive --out ~/.config/jumpstarter/clients/hello.yaml 2>/dev/null || echo "Client may already exist"
	@echo "✅ Client created: ~/.config/jumpstarter/clients/hello.yaml"

exporter-shell: ## Startet eine Shell zum Exporter
	@echo "🐚 Starting exporter shell..."
	@echo "Note: Make sure the exporter is running first (make run-exporter)"
	jmp shell --client hello --selector environment=dev

python-shell: ## Startet eine Python Shell mit Jumpstarter
	@echo "🐍 Starting Python shell with Jumpstarter..."
	uv run python

list-exporters: ## Zeigt alle aktiven Exporter an
	@echo "📋 Active Exporters:"
	jmp admin get exporter

list-clients: ## Zeigt alle aktiven Clients an
	@echo "👥 Active Clients:"
	jmp admin get client

list-devices: ## Zeigt alle verfügbaren Devices an
	@echo "🔌 Available Devices:"
	jmp admin get exporter --devices

show-exporter: ## Zeigt Details zum Beispiel-Exporter an
	@echo "🔍 Exporter Details:"
	jmp admin get exporter example-distributed -o yaml

show-client: ## Zeigt Details zum Hello-Client an
	@echo "🔍 Client Details:"
	jmp admin get client hello -o yaml

jumpstarter-status: ## Zeigt Status aller Jumpstarter Komponenten an
	@echo "🌐 Jumpstarter Cluster Status:"
	@$(MAKE) --no-print-directory status
	@echo ""
	@echo "📋 Jumpstarter Resources:"
	@$(MAKE) --no-print-directory list-exporters
	@echo ""
	@$(MAKE) --no-print-directory list-clients

# Complete Workflow

jumpstarter-demo: python-setup create-exporter create-client ## Komplettes Jumpstarter Demo Setup
	@echo "🎉 Jumpstarter Demo Setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Terminal 1: make run-exporter"
	@echo "2. Terminal 2: make exporter-shell"
	@echo ""
	@echo "Or test it now:"
	@echo "  make test-exporter-workflow"

test-exporter-workflow: ## Testet den kompletten Exporter-Workflow
	@echo "🧪 Testing Jumpstarter exporter workflow..."
	@echo "1. Creating fresh exporter and client..."
	@$(MAKE) --no-print-directory delete-exporter || true
	@$(MAKE) --no-print-directory delete-client || true
	@$(MAKE) --no-print-directory create-exporter
	@$(MAKE) --no-print-directory create-client
	@echo "✅ Setup complete! You can now run 'make run-exporter' and 'make exporter-shell'"

delete-exporter: ## Löscht den Beispiel-Exporter
	@echo "🗑️ Deleting exporter..."
	jmp admin delete exporter example-distributed --nointeractive 2>/dev/null || echo "Exporter doesn't exist"

delete-client: ## Löscht den Client
	@echo "🗑️ Deleting client..."
	jmp admin delete client hello --nointeractive 2>/dev/null || echo "Client doesn't exist"

test-robot: python-setup ## Führt Robot Framework Integration Tests aus
	@echo "🤖 Running Robot Framework integration tests..."
	@mkdir -p tests/robot/results
	@if command -v robot >/dev/null 2>&1; then \
		echo "Using system Robot Framework..."; \
		robot --outputdir tests/robot/results tests/robot/jumpstarter_integration.robot; \
	else \
		echo "Using uv Robot Framework..."; \
		uv sync --extra testing && \
		uv run robot --outputdir tests/robot/results tests/robot/jumpstarter_integration.robot; \
	fi
	@echo "📊 Test results available in tests/robot/results/"

test-robot-quick: python-setup ## Führt Robot Framework Tests im Dry-Run Modus aus
	@echo "🏃 Quick Robot Framework validation..."
	@if command -v robot >/dev/null 2>&1; then \
		echo "Using system Robot Framework..."; \
		robot --dryrun tests/robot/jumpstarter_integration.robot; \
	else \
		echo "Using uv Robot Framework..."; \
		uv sync --extra testing && \
		uv run robot --dryrun tests/robot/jumpstarter_integration.robot; \
	fi
	@echo "✅ Robot Framework tests validated"

test-integration: dev test-robot ## Kompletter Integrations-Test: Setup + Robot Tests
	@echo "🎯 Full integration test completed!"
	@echo "📊 Check tests/robot/results/ for detailed test reports"

ci-test: setup deploy test-robot ## CI-ähnlicher Test ohne komplettes dev setup
	@echo "🔄 CI-style test completed!"
