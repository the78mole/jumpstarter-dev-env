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
    else
        echo "❌ kubectl found but not working"
    fi
    
    echo ""
    echo "📋 VS Code Settings to add:"
    echo '{'
    echo '  "vs-kubernetes.kubectl-path": "'$(which kubectl)'",'
    echo '  "kubernetes.kubectl-path": "'$(which kubectl)'"'
    echo '}'
    
    echo ""
    echo "🔄 To fix VS Code Kubernetes Extension:"
    echo "1. Reload VS Code Window (Ctrl+Shift+P -> 'Developer: Reload Window')"
    echo "2. Or restart the Kubernetes extension"
    echo "3. Or use Command Palette: 'Kubernetes: Set kubectl path'"
    
else
    echo "❌ kubectl not found in PATH"
    echo "Available in PATH:"
    echo $PATH | tr ':' '\n'
fi
