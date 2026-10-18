#!/bin/bash
# Demostración del versionamiento paso a paso (para el video).
# Presiona ENTER entre pasos. Muestra: crear la base en V003, avanzar a la última versión,
# retroceder (rollback) y volver a avanzar, verificando el contrato en cada punto.
set -euo pipefail
cd "$(dirname "$0")/.."

pause() { echo; read -r -p ">> ENTER para continuar..." _; echo; }
step()  { echo; echo "=================================================="; echo "$1"; echo "=================================================="; }

step "1) Empezar desde cero: se borran los volúmenes"
docker compose down --volumes
pause

step "2) Levantar la base en la versión V003 (antes de los cambios de Referencing)"
TARGET_SCHEMA_VERSION=3 docker compose up -d --build
sleep 5
docker compose logs --no-color mongodb-init | tail -n 8
pause

step "3) Historial y colecciones en V003 (no existen customer_wishlists, order_events, ...)"
docker compose run --rm mongodb-init status
pause

step "4) Avanzar a la última versión (aplica V004 a V007: los 4 ejemplos de Referencing)"
docker compose run --rm -e TARGET_SCHEMA_VERSION=latest mongodb-init init
docker compose run --rm mongodb-init status
pause

step "5) Ver las referencias funcionando ($lookup)"
./demo/demo-referencing.sh
pause

step "6) Intercalar: volver (rollback) a V003"
docker compose run --rm mongodb-init rollback 3
docker compose run --rm mongodb-init status
pause

step "7) Volver a avanzar a la última versión"
docker compose run --rm -e TARGET_SCHEMA_VERSION=latest mongodb-init init
docker compose run --rm mongodb-init verify
echo; echo "Listo: la base quedó en la última versión y el contrato está verificado."
