#!/bin/bash
# ================================================================
# AgriMarket - Runner de versionamiento para MongoDB
#
# Uso (dentro del contenedor mongodb-init):
#   init | migrate     aplica baseline + cambios hasta TARGET_SCHEMA_VERSION (por defecto: latest)
#   rollback <n>       revierte con changes/down/*.down.js hasta dejar la base en la versión <n>
#   verify | check     verifica el contrato (historial, colecciones, índices y referencias)
#   status             muestra el historial de la colección schema_changes
#
# Convención: bootstrap/V001__baseline.js y changes/V00N__nombre.js (N consecutivo, sin saltos).
# Cada cambio queda registrado en schema_changes con su checksum SHA-256; si alguien
# modifica un script ya aplicado, el runner se detiene (no se reescribe el historial).
# ================================================================
set -euo pipefail
shopt -s nullglob
cd /lab

MONGO_HOST="${MONGO_HOST:-mongodb}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_ADMIN_USER="${MONGO_ADMIN_USER:-root}"
MONGO_ADMIN_PASSWORD="${MONGO_ADMIN_PASSWORD:?Falta MONGO_ADMIN_PASSWORD}"
MONGO_DATABASE="${MONGO_DATABASE:-Agrimarket}"
TARGET_SCHEMA_VERSION="${TARGET_SCHEMA_VERSION:-latest}"
GIT_SHA="${GIT_SHA:-local}"
RELEASE_VERSION="${RELEASE_VERSION:-local}"
export MONGO_ADMIN_USER MONGO_ADMIN_PASSWORD MONGO_DATABASE GIT_SHA RELEASE_VERSION

mongo_file() {
    mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" \
        --username "$MONGO_ADMIN_USER" --password "$MONGO_ADMIN_PASSWORD" \
        --authenticationDatabase admin --quiet "$1"
}

mongo_eval() {
    mongosh --host "$MONGO_HOST" --port "$MONGO_PORT" \
        --username "$MONGO_ADMIN_USER" --password "$MONGO_ADMIN_PASSWORD" \
        --authenticationDatabase admin --quiet \
        --eval "var labDb = db.getSiblingDB(process.env.MONGO_DATABASE); $1"
}

# "V004__nombre.js" -> 4
seq_of() {
    local n
    n="$(basename "$1")"
    n="${n#V}"
    n="${n%%_*}"
    echo $((10#$n))
}

pad() { printf 'V%03d' "$1"; }

# ---------- catálogo de cambios disponibles ----------
CHANGES=(changes/V*.js)
expected=2
for f in "${CHANGES[@]}"; do
    if [ "$(seq_of "$f")" -ne "$expected" ]; then
        echo "ERROR: se esperaba $(pad "$expected") y se encontró $f (los cambios deben ser consecutivos)" >&2
        exit 2
    fi
    expected=$((expected + 1))
done
LATEST=$((expected - 1))

resolve_target() {
    if [ "$TARGET_SCHEMA_VERSION" = "latest" ]; then
        TARGET_SCHEMA_VERSION="$LATEST"
    fi
    case "$TARGET_SCHEMA_VERSION" in
        ''|*[!0-9]*|0)
            echo "ERROR: TARGET_SCHEMA_VERSION debe ser 'latest' o un entero >= 1" >&2
            exit 2 ;;
    esac
    if [ "$TARGET_SCHEMA_VERSION" -gt "$LATEST" ]; then
        echo "ERROR: no existe la versión $TARGET_SCHEMA_VERSION; la última disponible es $(pad "$LATEST")" >&2
        exit 2
    fi
    export TARGET_SCHEMA_VERSION
}

wait_for_mongo() {
    echo "MongoDB: esperando al servidor..."
    until mongo_eval "print(db.adminCommand('ping').ok)" >/dev/null 2>&1; do
        sleep 3
    done
    echo "MongoDB: servidor disponible."
}

current_version() {
    local v
    v="$(mongo_eval "print(labDb.getCollectionInfos({name:'schema_changes'}).length ? Number(labDb.schema_changes.find().sort({sequence:-1}).limit(1).toArray()[0].sequence) : 0)" | tr -d '[:space:]')"
    echo "${v:-0}"
}

apply_script() {
    local script="$1" name seq checksum applied stored
    name="$(basename "$script")"
    seq="$(seq_of "$script")"
    checksum="$(sha256sum "$script" | awk '{print $1}')"

    applied="$(mongo_eval "print(labDb.getCollectionInfos({name:'schema_changes'}).length ? labDb.schema_changes.countDocuments({sequence: $seq}) : 0)" | tr -d '[:space:]')"

    if [ "$applied" != "0" ]; then
        stored="$(mongo_eval "print(labDb.schema_changes.findOne({sequence: $seq}).checksum)" | tr -d '[:space:]')"
        if [ "$stored" != "$checksum" ]; then
            echo "ERROR: el checksum de $name cambió después de aplicarse. No edites versiones ya aplicadas; crea una nueva." >&2
            exit 3
        fi
        echo "MongoDB: $name ya aplicado"
        return
    fi

    echo "MongoDB: aplicando $name"
    mongo_file "$script"

    export CHANGE_SEQUENCE="$seq" CHANGE_ID="${name%.js}" CHANGE_CHECKSUM="$checksum"
    mongo_file metadata/record-change.js
}

rollback_to() {
    local target="$1" current s down
    case "$target" in ''|*[!0-9]*|0) echo "ERROR: uso: rollback <versión >= 1>" >&2; exit 2 ;; esac
    current="$(current_version)"
    if [ "$target" -ge "$current" ]; then
        echo "MongoDB: la base ya está en $(pad "$current"); no hay nada que revertir hasta $(pad "$target")."
        return
    fi
    for ((s = current; s > target; s--)); do
        down=(changes/down/"$(pad "$s")"__*.down.js)
        if [ "${#down[@]}" -ne 1 ]; then
            echo "ERROR: falta el script down para $(pad "$s") en changes/down/" >&2
            exit 2
        fi
        echo "MongoDB: revirtiendo $(pad "$s") con ${down[0]}"
        mongo_file "${down[0]}"
        export CHANGE_SEQUENCE="$s"
        mongo_file metadata/remove-change.js
    done
}

action="${1:-init}"
wait_for_mongo

case "$action" in
    init|migrate)
        resolve_target
        current="$(current_version)"
        if [ "$current" -gt "$TARGET_SCHEMA_VERSION" ]; then
            echo "ERROR: la base está en $(pad "$current") y pediste $(pad "$TARGET_SCHEMA_VERSION"). Para retroceder usa: rollback $TARGET_SCHEMA_VERSION" >&2
            exit 2
        fi
        apply_script bootstrap/V001__baseline.js
        for f in "${CHANGES[@]}"; do
            [ "$(seq_of "$f")" -le "$TARGET_SCHEMA_VERSION" ] || continue
            apply_script "$f"
        done
        mongo_file checks/contract.js
        ;;
    rollback)
        rollback_to "${2:-}"
        TARGET_SCHEMA_VERSION="$(current_version)"
        export TARGET_SCHEMA_VERSION
        mongo_file checks/contract.js
        ;;
    verify|check)
        TARGET_SCHEMA_VERSION="$(current_version)"
        export TARGET_SCHEMA_VERSION
        mongo_file checks/contract.js
        ;;
    status)
        mongo_eval "print('Base: ' + labDb.getName()); print('Colecciones: ' + labDb.getCollectionNames().sort().join(', ')); print('Historial (schema_changes):'); if (labDb.getCollectionInfos({name:'schema_changes'}).length) { labDb.schema_changes.find().sort({sequence:1}).forEach(function (c) { print('  ' + c.changeId + '  sha256=' + c.checksum.substring(0, 12) + '  ' + c.appliedAt.toISOString()); }); } else { print('  (vacío)'); }"
        ;;
    *)
        echo "Uso: init | migrate | rollback <n> | verify | status" >&2
        exit 2
        ;;
esac

echo "MongoDB: listo."
