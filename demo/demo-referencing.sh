#!/bin/bash
# Ejecuta las consultas $lookup de la demostración de Referencing contra el contenedor mongodb.
# Requisito: la base ya está levantada en su última versión (docker compose up -d --build).
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && { set -a; . ./.env; set +a; }

docker compose exec -T mongodb mongosh --quiet \
    -u "${MONGO_ADMIN_USER:-root}" -p "${MONGO_ADMIN_PASSWORD}" --authenticationDatabase admin \
    < demo/referencing-queries.js
