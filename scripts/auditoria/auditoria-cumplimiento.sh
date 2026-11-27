#!/usr/bin/env bash
# Auditoria automatizada de cumplimiento: verifica las politicas de seguridad y calidad del proyecto.
# Cada politica referencia la buena practica o norma de la que proviene.
# Si alguna politica no se cumple, el script termina con error y el pipeline se detiene.
# El reporte queda en la salida estandar y, dentro de GitHub Actions, en el resumen de la ejecucion.
set -uo pipefail

cd "$(dirname "$0")/../.."
FALLAS=0
FILAS=""

registrar() {
  local id="$1" politica="$2" norma="$3" ok="$4" detalle="$5" estado
  if [ "$ok" = "1" ]; then estado="CUMPLE"; else estado="NO CUMPLE"; FALLAS=$((FALLAS + 1)); fi
  printf '%-7s %-10s %s (%s)\n' "$id" "$estado" "$politica" "$detalle"
  FILAS="${FILAS}| ${id} | ${politica} | ${norma} | ${estado} | ${detalle} |"$'\n'
}

MANIFIESTOS=$(ls k8s/0*.yaml k8s/eks/*.yaml 2>/dev/null)

# POL-01 Contenedor sin privilegios de root
if grep -Eq '^USER +[0-9]+' Dockerfile && ! grep -Eq '^USER +(root|0)(:|$)' Dockerfile; then
  registrar POL-01 "La imagen se ejecuta con un usuario sin privilegios" "CIS Docker Benchmark 4.1" 1 "USER $(grep -E '^USER' Dockerfile | tail -1 | awk '{print $2}')"
else
  registrar POL-01 "La imagen se ejecuta con un usuario sin privilegios" "CIS Docker Benchmark 4.1" 0 "falta USER no root en el Dockerfile"
fi

# POL-02 Imagen con verificacion de salud
if grep -q '^HEALTHCHECK' Dockerfile; then ok=1; d="HEALTHCHECK definido"; else ok=0; d="falta HEALTHCHECK"; fi
registrar POL-02 "La imagen define un HEALTHCHECK" "CIS Docker Benchmark 4.6" "$ok" "$d"

# POL-03 Imagenes base con version fija (sin :latest)
if grep -E '^FROM ' Dockerfile | grep -Eq ':latest|^FROM [^:]+$'; then ok=0; d="imagen base sin version"; else ok=1; d="todas las imagenes base tienen version"; fi
registrar POL-03 "Imagenes base con version fija" "CIS Docker Benchmark 4.2" "$ok" "$d"

# POL-04 Contenedores de Kubernetes con limites de recursos
SIN_LIMITES=""
for f in $MANIFIESTOS; do
  c=$(grep -c 'image:' "$f"); l=$(grep -c 'limits:' "$f")
  if [ "$c" -gt 0 ] && [ "$l" -lt "$c" ]; then SIN_LIMITES="$SIN_LIMITES $f"; fi
done
if [ -z "$SIN_LIMITES" ]; then ok=1; d="todos los contenedores tienen limits"; else ok=0; d="sin limits:$SIN_LIMITES"; fi
registrar POL-04 "Contenedores con limites de CPU y memoria" "Kubernetes Pod Security / gobernanza" "$ok" "$d"

# POL-05 Pods que no corren como root
SIN_NONROOT=""
for f in $MANIFIESTOS; do
  if grep -q '^kind: \(Deployment\|StatefulSet\)' "$f" && ! grep -q 'runAsNonRoot: true' "$f"; then SIN_NONROOT="$SIN_NONROOT $f"; fi
done
if [ -z "$SIN_NONROOT" ]; then ok=1; d="runAsNonRoot en todos los workloads"; else ok=0; d="sin runAsNonRoot:$SIN_NONROOT"; fi
registrar POL-05 "Workloads con runAsNonRoot" "Kubernetes Pod Security Standards (restricted)" "$ok" "$d"

# POL-06 Sin escalamiento de privilegios
SIN_APE=""
for f in $MANIFIESTOS; do
  c=$(grep -c 'image:' "$f"); a=$(grep -c 'allowPrivilegeEscalation: false' "$f")
  if [ "$c" -gt 0 ] && [ "$a" -lt "$c" ]; then SIN_APE="$SIN_APE $f"; fi
done
if [ -z "$SIN_APE" ]; then ok=1; d="allowPrivilegeEscalation: false en todos los contenedores"; else ok=0; d="falta en:$SIN_APE"; fi
registrar POL-06 "Contenedores sin escalamiento de privilegios" "Kubernetes Pod Security Standards (restricted)" "$ok" "$d"

# POL-07 Imagenes de Kubernetes con version fija
if grep -h 'image:' $MANIFIESTOS | grep -Eq ':latest'; then ok=0; d="hay imagenes :latest en los manifiestos"; else ok=1; d="sin imagenes :latest"; fi
registrar POL-07 "Manifiestos sin imagenes :latest" "Buenas practicas de Kubernetes" "$ok" "$d"

# POL-08 Acciones de GitHub fijadas por SHA de commit
NO_FIJADAS=$(grep -hE '^\s*uses:' .github/workflows/*.yml | grep -vE '@[0-9a-f]{40}' | sed 's/^ *//' | sort -u)
if [ -z "$NO_FIJADAS" ]; then ok=1; d="todas las acciones fijadas por SHA"; else ok=0; d="sin fijar: $(echo "$NO_FIJADAS" | tr '\n' ' ')"; fi
registrar POL-08 "Acciones de GitHub fijadas por SHA" "OpenSSF Scorecard / SLSA (cadena de suministro)" "$ok" "$d"

# POL-09 Workflows con permisos minimos declarados
SIN_PERM=""
for f in .github/workflows/*.yml; do grep -q '^permissions:' "$f" || SIN_PERM="$SIN_PERM $f"; done
if [ -z "$SIN_PERM" ]; then ok=1; d="permissions declarado en todos los workflows"; else ok=0; d="sin permissions:$SIN_PERM"; fi
registrar POL-09 "Workflows con permisos minimos" "OpenSSF Scorecard (Token-Permissions)" "$ok" "$d"

# POL-10 Sin secretos versionados
SECRETOS=""
git ls-files --error-unmatch .env >/dev/null 2>&1 && SECRETOS="$SECRETOS .env"
if grep -hiE '(password|secret|token)[^:]*:\s*"?[A-Za-z0-9+/]{8,}' $MANIFIESTOS >/dev/null 2>&1; then SECRETOS="$SECRETOS clave-en-manifiesto"; fi
if [ -z "$SECRETOS" ]; then ok=1; d="sin archivos .env ni claves en manifiestos"; else ok=0; d="encontrado:$SECRETOS"; fi
registrar POL-10 "Sin secretos en el repositorio" "OWASP Top 10 A02 / OWASP ASVS V6" "$ok" "$d"

# POL-11 Excepciones de seguridad vigentes (con fecha de vencimiento no superada)
HOY=$(date +%Y-%m-%d); VENCIDAS=""; SIN_FECHA=""
while read -r linea; do
  linea=$(echo "${linea%$''}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  case "$linea" in ''|\#*) continue ;; esac
  exp=$(echo "$linea" | grep -oE 'exp:[0-9-]+' | cut -d: -f2)
  if [ -z "$exp" ]; then SIN_FECHA="$SIN_FECHA $(echo "$linea" | awk '{print $1}')"
  elif [[ "$exp" < "$HOY" ]]; then VENCIDAS="$VENCIDAS $(echo "$linea" | awk '{print $1}')"; fi
done < .trivyignore
if [ -z "$VENCIDAS$SIN_FECHA" ]; then ok=1; d="todas las excepciones justificadas y vigentes"; else ok=0; d="vencidas:${VENCIDAS:- ninguna} sin fecha:${SIN_FECHA:- ninguna}"; fi
registrar POL-11 "Excepciones de seguridad con vencimiento" "Gestion de riesgos (ISO/IEC 27001 A.8.8)" "$ok" "$d"

# POL-12 Cobertura minima exigida de al menos 80%
MIN=$(grep -oE '<jacoco.minimum.coverage>[0-9.]+' pom.xml | grep -oE '[0-9.]+$')
if awk "BEGIN {exit !(${MIN:-0} >= 0.80)}"; then ok=1; d="minimo configurado ${MIN}"; else ok=0; d="minimo configurado ${MIN:-ninguno}"; fi
registrar POL-12 "Cobertura minima de pruebas >= 80%" "Politica de calidad del proyecto (ISO/IEC 25010)" "$ok" "$d"

echo ""
if [ "$FALLAS" -eq 0 ]; then echo "RESULTADO: todas las politicas se cumplen"; else echo "RESULTADO: ${FALLAS} politica(s) no se cumplen"; fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Auditoria de cumplimiento"
    echo ""
    echo "| ID | Politica | Norma / referencia | Estado | Detalle |"
    echo "|---|---|---|---|---|"
    printf '%s' "$FILAS"
    echo ""
    echo "**Resultado:** $([ "$FALLAS" -eq 0 ] && echo 'todas las politicas se cumplen' || echo "${FALLAS} politica(s) no se cumplen: el pipeline se detiene")"
  } >> "$GITHUB_STEP_SUMMARY"
fi

[ "$FALLAS" -eq 0 ]
