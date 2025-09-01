#!/bin/bash
set -e

echo "=== Testing Jumpstarter Services (Docker-in-Docker) ==="
echo ""

# Cluster Status prüfen
echo "📊 Checking cluster status..."
kubectl get nodes -o wide

echo ""
echo "🔍 Checking Jumpstarter pods:"
kubectl get pods -n jumpstarter-lab -o wide

echo ""
echo "🌐 Checking services:"
kubectl get svc -n jumpstarter-lab

echo ""
echo "🚪 Checking ingress:"
kubectl get ingress -n jumpstarter-lab

echo ""
echo "=== Network Connectivity Tests ==="

# Port-Tests
echo "Testing localhost ports..."
for port in 5080 8082 8083; do
    if timeout 3 nc -z localhost $port 2>/dev/null; then
        echo "✅ localhost:$port - OPEN"
    else
        echo "❌ localhost:$port - CLOSED"
    fi
done

echo ""
echo "=== HTTP Tests ==="

# HTTP-Tests
echo "Testing HTTP endpoints..."
for endpoint in "http://localhost:5080" "http://localhost:5080/health"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$endpoint" 2>/dev/null || echo "000")
    if [ "$status" != "000" ]; then
        echo "✅ $endpoint - HTTP $status"
    else
        echo "❌ $endpoint - NO RESPONSE"
    fi
done

echo ""
echo "=== Service Logs (last 10 lines) ==="
echo ""
echo "🎮 Controller logs:"
kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-controller --tail=5 2>/dev/null || echo "No controller logs available"

echo ""
echo "🔀 Router logs:"
kubectl logs -n jumpstarter-lab -l app.kubernetes.io/name=jumpstarter-router --tail=5 2>/dev/null || echo "No router logs available"

echo ""
echo "=== Summary ==="
echo "If all ports show as OPEN, Jumpstarter is ready to use!"
echo "If ports are CLOSED, try restarting the dev container."
