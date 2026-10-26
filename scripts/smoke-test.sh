#!/usr/bin/env bash
# Smoke test funcional del microservicio desplegado.
# Uso: scripts/smoke-test.sh [BASE_URL]   (por defecto http://localhost:8080)
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
RETRIES="${RETRIES:-30}"

echo "==> Esperando que ${BASE_URL} este disponible..."
for i in $(seq 1 "$RETRIES"); do
  if curl -fs "${BASE_URL}/actuator/health/readiness" > /dev/null; then
    echo "    Servicio listo (intento $i)"
    break
  fi
  if [ "$i" -eq "$RETRIES" ]; then
    echo "ERROR: el servicio no respondio a tiempo"
    exit 1
  fi
  sleep 5
done

check() {
  local description="$1" expected="$2" actual="$3"
  if [ "$actual" != "$expected" ]; then
    echo "FALLO: ${description} (esperado HTTP ${expected}, obtenido ${actual})"
    exit 1
  fi
  echo "OK:    ${description} -> HTTP ${actual}"
}

status() { curl -s -o /dev/null -w "%{http_code}" "$@"; }

check "Health check (Actuator)" 200 "$(status "${BASE_URL}/actuator/health")"
check "Listar estudiantes" 200 "$(status "${BASE_URL}/students")"

CREATED=$(curl -fs -X POST -H "Content-Type: application/json" -d '{"name":"Smoketest"}' "${BASE_URL}/students")
ID=$(echo "$CREATED" | sed -E 's/.*"id":([0-9]+).*/\1/')
echo "OK:    Crear estudiante -> id ${ID}"

check "Obtener estudiante creado" 200 "$(status "${BASE_URL}/students/${ID}")"
check "Buscar por nombre" 200 "$(status "${BASE_URL}/students/search?name=smoke")"
check "Conteo de estudiantes" 200 "$(status "${BASE_URL}/students/count")"
check "Validacion de datos invalidos" 400 "$(status -X POST -H "Content-Type: application/json" -d '{"name":"1nv@lido"}' "${BASE_URL}/students")"
check "Eliminar estudiante" 204 "$(status -X DELETE "${BASE_URL}/students/${ID}")"
check "Estudiante eliminado ya no existe" 404 "$(status "${BASE_URL}/students/${ID}")"

echo "==> Smoke test completado exitosamente"
