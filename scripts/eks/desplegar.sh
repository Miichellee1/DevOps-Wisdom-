#!/usr/bin/env bash
# Despliega bdget en Amazon EKS dentro de la malla de servicios Istio y publica las metricas del despliegue.
# Requisitos: kubectl conectado al cluster (aws eks update-kubeconfig) e Istio instalado.
# Uso:  IMAGE=ghcr.io/miichellee1/devops-wisdom:sha-xxxxxxx bash scripts/eks/desplegar.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
IMAGE="${IMAGE:-ghcr.io/miichellee1/devops-wisdom:latest}"
NS=bdget
INICIO=$(date +%s)

echo "==> Imagen a desplegar: ${IMAGE}"

echo "==> StorageClass gp3 (volumen persistente de PostgreSQL)"
kubectl apply -f k8s/eks/storageclass-gp3.yaml

echo "==> Namespace con inyeccion de Istio y cuota de recursos"
kubectl apply -f k8s/eks/00-namespace-istio.yaml

echo "==> Secret de la base de datos (clave aleatoria, nunca versionada)"
if ! kubectl -n "$NS" get secret bdget-db-secret >/dev/null 2>&1; then
  kubectl -n "$NS" create secret generic bdget-db-secret \
    --from-literal=DB_USER=bdget \
    --from-literal=DB_PASSWORD="$(openssl rand -base64 24)"
fi

echo "==> Manifiestos de la aplicacion (los mismos del pipeline, con la imagen del commit)"
RENDER=$(mktemp -d)
for f in 01-configmap 02-database 03-deployment 04-service 05-hpa 06-pdb; do
  cp "k8s/${f}.yaml" "${RENDER}/"
done
sed -i "s#image: bdget:local#image: ${IMAGE}#" "${RENDER}/03-deployment.yaml"
kubectl apply -f "${RENDER}/"

# La app espera a que su sidecar de Istio este listo antes de arrancar (evita fallos al conectarse a la BD)
for obj in deployment/bdget-deployment statefulset/bdget-db; do
  kubectl -n "$NS" patch "$obj" --type merge -p \
    '{"spec":{"template":{"metadata":{"annotations":{"proxy.istio.io/config":"{\"holdApplicationUntilProxyStarts\": true}"}}}}}'
done
kubectl -n "$NS" annotate deployment/bdget-deployment \
  kubernetes.io/change-cause="imagen ${IMAGE}" --overwrite

echo "==> Generador de trafico y exportador de metricas CI/CD"
kubectl apply -f k8s/eks/trafico.yaml -f k8s/eks/ci-metrics.yaml

echo "==> Esperando el rollout"
kubectl -n "$NS" rollout status statefulset/bdget-db --timeout=300s
kubectl -n "$NS" rollout status deployment/bdget-deployment --timeout=400s
kubectl -n "$NS" rollout status deployment/trafico --timeout=180s

FIN=$(date +%s)
DURACION=$((FIN - INICIO))
echo "==> Despliegue completado en ${DURACION} s"

DEPLOY_DURATION_SECONDS="$DURACION" IMAGE="$IMAGE" bash scripts/eks/publicar-metricas-ci.sh

kubectl -n "$NS" get pods -o wide
