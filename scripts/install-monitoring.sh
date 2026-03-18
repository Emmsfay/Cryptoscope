#!/usr/bin/env bash
# scripts/install-monitoring.sh
# Installs Prometheus + Grafana + Alertmanager via kube-prometheus-stack Helm chart
set -euo pipefail

NAMESPACE="monitoring"
RELEASE="kube-prometheus-stack"

echo "==> Adding Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "==> Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing kube-prometheus-stack..."
helm upgrade --install ${RELEASE} prometheus-community/kube-prometheus-stack \
  --namespace ${NAMESPACE} \
  --values monitoring/prometheus-values.yaml \

echo ""
echo "✓ Monitoring stack installed!"
echo ""
echo "==> Access Grafana:"
echo "    kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring"
echo "    URL: http://localhost:3000"
echo "    User: admin"
echo "    Pass: $(kubectl get secret kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 -d)"
