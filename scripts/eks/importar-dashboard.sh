#!/usr/bin/env bash
# Importa (o actualiza) el dashboard versionado observability/grafana-dashboard-bdget.json en Grafana.
# Usa un port-forward temporal al Service de Grafana del namespace istio-system.
set -euo pipefail

cd "$(dirname "$0")/../.."
kubectl -n istio-system port-forward svc/grafana 3000:3000 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
sleep 4

curl -fsS -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  --data-binary @observability/grafana-dashboard-bdget.json
echo
echo "==> Dashboard importado: abre Grafana > Dashboards > 'bdget - DevOps (CI/CD y operación en EKS)'"
