#!/bin/bash

echo "=== VS Code Kubernetes Extension Fix ==="
echo ""
echo "kubectl path: $(which kubectl)"
echo "kubectl version: $(kubectl version --client --short 2>/dev/null || echo 'Not available')"
echo ""

if command -v kubectl &> /dev/null; then
    echo "✅ kubectl is available at: $(which kubectl)"
    
    # Teste kubectl
    if kubectl version --client &> /dev/null; then
        echo "✅ kubectl is working correctly"
        
        # Test cluster connection if available
        if kubectl cluster-info &> /dev/null; then
            echo "✅ kubectl can connect to cluster"
            kubectl get nodes 2>/dev/null | head -5
        else
            echo "⚠️  kubectl works but no cluster connection"
        fi
    else
        echo "❌ kubectl found but not working"
    fi
    
    echo ""
    echo "📋 VS Code Settings (already configured in DevContainer):"
    echo '{'
    echo '  "vs-kubernetes.kubectl-path": "/usr/bin/kubectl",'
    echo '  "kubernetes.kubectlPath": "/usr/bin/kubectl",'
    echo '  "vs-kubernetes.helm-path": "/usr/bin/helm",'
    echo '  "kubernetes.helmPath": "/usr/bin/helm"'
    echo '}'
    
    echo ""
    echo "🔄 To fix VS Code Kubernetes Extension:"
    echo "1. Reload VS Code Window (Ctrl+Shift+P -> 'Developer: Reload Window')"
    echo "2. Or restart the DevContainer (Ctrl+Shift+P -> 'Dev Containers: Rebuild Container')"
    echo "3. Or use Command Palette: 'Kubernetes: Set kubectl path' -> /usr/bin/kubectl"
    echo ""
    echo "🎯 Quick fix command:"
    echo "   Ctrl+Shift+P -> 'Developer: Reload Window'"
    
else
    echo "❌ kubectl not found in PATH"
    echo "Available in PATH:"
    echo $PATH | tr ':' '\n'
    echo ""
    echo "💡 Try installing kubectl:"
    echo "   curl -LO 'https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl'"
    echo "   chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
fi
