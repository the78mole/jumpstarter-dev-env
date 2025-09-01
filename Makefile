.PHONY: help setup teardown deploy test status logs clean dev

help: ## Zeigt diese Hilfe an
	@echo "Jumpstarter Server - Make Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

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
	@echo "  Web Interface:    http://localhost:5080"
	@echo "  GRPC Controller:  localhost:8082"
	@echo "  GRPC Router:      localhost:8083"

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
	@echo "Starting k9s dashboard..."
	k9s

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

restart: teardown deploy ## Neustart der Jumpstarter Komponenten
	@echo "🔄 Restarting Jumpstarter..."

full-setup: setup deploy status ## Komplettes Setup mit Status-Anzeige
	@echo "🎉 Full setup completed!"

troubleshoot: ## Hilfe bei kubectl/VS Code Problemen
	@echo "🔧 Running troubleshooting..."
	@./scripts/fix-vscode-kubectl.sh
