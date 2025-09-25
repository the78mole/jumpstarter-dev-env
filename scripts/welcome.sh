#!/bin/bash
# Einfaches Post-DevContainer Setup

echo "🎯 Jumpstarter Server DevContainer Ready!"

# Setup kubectl configuration
echo "⚙️  Setting up kubectl configuration..."
mkdir -p ~/.kube
chmod 755 ~/.kube

# Check if Kind cluster exists and setup kubeconfig
if kind get clusters 2>/dev/null | grep -q "jumpstarter-server"; then
    echo "🔧 Configuring kubectl for existing Kind cluster..."
    kind get kubeconfig --name jumpstarter-server > ~/.kube/config 2>/dev/null
    chmod 644 ~/.kube/config

    # Add KUBECONFIG to bashrc if not already there
    if ! grep -q "KUBECONFIG" ~/.bashrc 2>/dev/null; then
        echo 'export KUBECONFIG=/home/vscode/.kube/config' >> ~/.bashrc
    fi

    # Set for current session
    export KUBECONFIG=/home/vscode/.kube/config

    echo "✅ kubectl configured for Kind cluster jumpstarter-server"
else
    echo "⚠️  Kind cluster 'jumpstarter-server' not found - will be created by 'make dev'"
fi

# Make jmp tools globally available
echo "🔗 Setting up Jumpstarter CLI global access..."
if [ -f "/workspaces/jumpstarter-dev-env/.venv/bin/jmp" ]; then
    sudo ln -sf /workspaces/jumpstarter-dev-env/.venv/bin/jmp /usr/local/bin/jmp
    sudo ln -sf /workspaces/jumpstarter-dev-env/.venv/bin/jmp-admin /usr/local/bin/jmp-admin
    sudo ln -sf /workspaces/jumpstarter-dev-env/.venv/bin/jmp-driver /usr/local/bin/jmp-driver
    sudo ln -sf /workspaces/jumpstarter-dev-env/.venv/bin/j /usr/local/bin/j
    echo "✅ jmp, jmp-admin, jmp-driver, and j are now globally available"
else
    echo "⚠️  .venv not found - jmp tools will be available after Python environment activation"
fi

# Make development tools globally available
echo "🔗 Setting up development tools global access..."
TOOLS_INSTALLED=""

if [ -f "/workspaces/jumpstarter-dev-env/.venv/bin/pre-commit" ]; then
    sudo ln -sf /workspaces/jumpstarter-dev-env/.venv/bin/pre-commit /usr/local/bin/pre-commit
    TOOLS_INSTALLED="$TOOLS_INSTALLED pre-commit"
fi

if [ -f "/workspaces/jumpstarter-dev-env/.venv/bin/black" ]; then
    sudo ln -sf /workspaces/jumpstarter-dev-env/.venv/bin/black /usr/local/bin/black
    TOOLS_INSTALLED="$TOOLS_INSTALLED black"
fi

if [ -n "$TOOLS_INSTALLED" ]; then
    echo "✅ Development tools now globally available:$TOOLS_INSTALLED"
else
    echo "⚠️  Development tools not found in .venv"
fi

echo ""
echo "Next Steps:"
echo "1. Run: make dev          # Complete setup with Kind cluster + Jumpstarter"
echo "2. Run: make test-robot   # Test Robot Framework integration"
echo "3. Run: make k9s          # Kubernetes dashboard"
echo ""
echo "Manual setup if needed:"
echo "- make setup             # Only Kind cluster + Ingress"
echo "- make deploy            # Only Jumpstarter installation"
echo ""
echo "For troubleshooting:"
echo "- make troubleshoot      # Fix kubectl/VS Code issues"
echo "- ./scripts/test.sh      # Basic connectivity tests"
echo ""
echo "Happy coding! 🚀"
