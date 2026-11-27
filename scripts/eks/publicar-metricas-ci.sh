#!/usr/bin/env bash
# Publica en el cluster las metricas del pipeline CI/CD (formato Prometheus) para el dashboard de Grafana.
# Los valores llegan por variables de entorno; en el pipeline salen de JaCoCo, Surefire y Trivy.
#   COVERAGE_PERCENT          cobertura de lineas (JaCoCo)
#   TESTS_TOTAL / TESTS_FAILED pruebas ejecutadas y fallidas (Surefire)
#   CRITICAL_VULNS / HIGH_VULNS vulnerabilidades encontradas por Trivy
#   DEPLOY_DURATION_SECONDS   tiempo del despliegue en EKS
#   PIPELINE_DURATION_SECONDS tiempo total del pipeline (desde el commit hasta el despliegue)
set -euo pipefail

NS=bdget
COMMIT="${GIT_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo local)}"
IMAGE="${IMAGE:-desconocida}"
AHORA=$(date +%s)

METRICAS=$(mktemp)
cat > "$METRICAS" <<EOF
# HELP ci_test_coverage_percent Cobertura de lineas de las pruebas (JaCoCo).
# TYPE ci_test_coverage_percent gauge
ci_test_coverage_percent ${COVERAGE_PERCENT:-0}
# HELP ci_tests_total Pruebas automatizadas ejecutadas en el pipeline.
# TYPE ci_tests_total gauge
ci_tests_total ${TESTS_TOTAL:-0}
# HELP ci_tests_failed Pruebas fallidas en el pipeline.
# TYPE ci_tests_failed gauge
ci_tests_failed ${TESTS_FAILED:-0}
# HELP ci_vulnerabilities Vulnerabilidades detectadas por Trivy en la imagen desplegada.
# TYPE ci_vulnerabilities gauge
ci_vulnerabilities{severity="critical"} ${CRITICAL_VULNS:-0}
ci_vulnerabilities{severity="high"} ${HIGH_VULNS:-0}
# HELP ci_deploy_duration_seconds Tiempo del ultimo despliegue en EKS.
# TYPE ci_deploy_duration_seconds gauge
ci_deploy_duration_seconds ${DEPLOY_DURATION_SECONDS:-0}
# HELP ci_pipeline_duration_seconds Tiempo total del pipeline, desde el commit hasta el despliegue.
# TYPE ci_pipeline_duration_seconds gauge
ci_pipeline_duration_seconds ${PIPELINE_DURATION_SECONDS:-0}
# HELP ci_last_deploy_timestamp_seconds Momento del ultimo despliegue (epoch).
# TYPE ci_last_deploy_timestamp_seconds gauge
ci_last_deploy_timestamp_seconds ${AHORA}
# HELP ci_deploy_info Commit e imagen del ultimo despliegue (trazabilidad).
# TYPE ci_deploy_info gauge
ci_deploy_info{commit="${COMMIT}",image="${IMAGE}"} 1
EOF

kubectl -n "$NS" create configmap ci-metrics --from-file=metrics.txt="$METRICAS" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "==> Metricas CI/CD publicadas:"
grep -v '^#' "$METRICAS"
