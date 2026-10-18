#!/bin/bash
# ================================================================
# AgriMarket - Runner de versionamiento para SQL Server
#
# Uso (dentro del contenedor sqlserver-init):
#   init | migrate     aplica baseline + cambios hasta TARGET_SCHEMA_VERSION (por defecto: latest)
#   rollback <n>       revierte con changes/down/*.down.sql hasta dejar la base en la versión <n>
#   verify | check     verifica el contrato de la versión actual
#   status             muestra el historial de la tabla dbo.schema_changes
#
# Si TARGET_SCHEMA_VERSION es mayor que la última versión de SQL Server (los cambios
# V004+ del equipo son de MongoDB), se usa la última disponible de SQL Server.
# ================================================================
set -euo pipefail
shopt -s nullglob
cd /lab

SQL_HOST="${SQL_HOST:-sqlserver}"
SQL_ADMIN_USER="${SQL_ADMIN_USER:-sa}"
SQL_ADMIN_PASSWORD="${SQL_ADMIN_PASSWORD:?Falta SQL_ADMIN_PASSWORD}"
SQL_DATABASE="${SQL_DATABASE:-Agrimarket}"
TARGET_SCHEMA_VERSION="${TARGET_SCHEMA_VERSION:-latest}"
GIT_SHA="${GIT_SHA:-local}"
RELEASE_VERSION="${RELEASE_VERSION:-local}"

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
[ -x "$SQLCMD" ] || SQLCMD="/opt/mssql-tools/bin/sqlcmd"

sql()    { "$SQLCMD" -S "$SQL_HOST" -U "$SQL_ADMIN_USER" -P "$SQL_ADMIN_PASSWORD" -C -b "$@"; }
sql_db() { sql -d "$SQL_DATABASE" "$@"; }
sql_scalar() { sql_db -h -1 -W -Q "SET NOCOUNT ON; $1" | tr -d '[:space:]'; }

seq_of() {
    local n
    n="$(basename "$1")"
    n="${n#V}"
    n="${n%%_*}"
    echo $((10#$n))
}

pad() { printf 'V%03d' "$1"; }

CHANGES=(changes/V*.sql)
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
        echo "SQL Server: la última versión de SQL Server es $(pad "$LATEST"); se usa esa."
        TARGET_SCHEMA_VERSION="$LATEST"
    fi
}

wait_for_sql() {
    echo "SQL Server: esperando al servidor..."
    until sql -Q "SELECT 1" >/dev/null 2>&1; do
        sleep 3
    done
    echo "SQL Server: servidor disponible."
    sql -Q "IF DB_ID('$SQL_DATABASE') IS NULL CREATE DATABASE [$SQL_DATABASE];"
    echo "SQL Server: base $SQL_DATABASE verificada."
}

current_version() {
    local v
    v="$(sql_scalar "IF OBJECT_ID('dbo.schema_changes','U') IS NULL SELECT 0 ELSE SELECT ISNULL(MAX(change_seq),0) FROM dbo.schema_changes")"
    echo "${v:-0}"
}

apply_script() {
    local script="$1" name seq checksum applied stored
    name="$(basename "$script")"
    seq="$(seq_of "$script")"
    checksum="$(sha256sum "$script" | awk '{print $1}')"

    applied="$(sql_scalar "IF OBJECT_ID('dbo.schema_changes','U') IS NULL SELECT 0 ELSE SELECT COUNT(*) FROM dbo.schema_changes WHERE change_seq = $seq")"

    if [ "$applied" != "0" ]; then
        stored="$(sql_scalar "SELECT checksum FROM dbo.schema_changes WHERE change_seq = $seq")"
        if [ "$stored" != "$checksum" ]; then
            echo "ERROR: el checksum de $name cambió después de aplicarse. No edites versiones ya aplicadas; crea una nueva." >&2
            exit 3
        fi
        echo "SQL Server: $name ya aplicado"
        return
    fi

    echo "SQL Server: aplicando $name"
    sql_db -i "$script"
    sql_db -v SEQ="$seq" ID="${name%.sql}" CHECKSUM="$checksum" GIT="$GIT_SHA" REL="$RELEASE_VERSION" -i metadata/record-change.sql
}

rollback_to() {
    local target="$1" current s down
    case "$target" in ''|*[!0-9]*|0) echo "ERROR: uso: rollback <versión >= 1>" >&2; exit 2 ;; esac
    current="$(current_version)"
    if [ "$target" -ge "$current" ]; then
        echo "SQL Server: la base ya está en $(pad "$current"); no hay nada que revertir hasta $(pad "$target")."
        return
    fi
    for ((s = current; s > target; s--)); do
        down=(changes/down/"$(pad "$s")"__*.down.sql)
        if [ "${#down[@]}" -ne 1 ]; then
            echo "ERROR: falta el script down para $(pad "$s") en changes/down/" >&2
            exit 2
        fi
        echo "SQL Server: revirtiendo $(pad "$s") con ${down[0]}"
        sql_db -i "${down[0]}"
        sql_db -Q "DELETE FROM dbo.schema_changes WHERE change_seq = $s;"
    done
}

run_contract() {
    sql_db -v TARGET="$1" -i checks/contract.sql
}

action="${1:-init}"
wait_for_sql

case "$action" in
    init|migrate)
        resolve_target
        current="$(current_version)"
        if [ "$current" -gt "$TARGET_SCHEMA_VERSION" ]; then
            echo "ERROR: la base está en $(pad "$current") y pediste $(pad "$TARGET_SCHEMA_VERSION"). Para retroceder usa: rollback $TARGET_SCHEMA_VERSION" >&2
            exit 2
        fi
        apply_script bootstrap/V001__baseline.sql
        for f in "${CHANGES[@]}"; do
            [ "$(seq_of "$f")" -le "$TARGET_SCHEMA_VERSION" ] || continue
            apply_script "$f"
        done
        run_contract "$TARGET_SCHEMA_VERSION"
        ;;
    rollback)
        rollback_to "${2:-}"
        run_contract "$(current_version)"
        ;;
    verify|check)
        run_contract "$(current_version)"
        ;;
    status)
        sql_db -Q "SELECT change_seq, change_id, LEFT(checksum, 12) AS sha256, applied_at FROM dbo.schema_changes ORDER BY change_seq;"
        sql_db -Q "SELECT name AS tabla FROM sys.tables ORDER BY name;"
        ;;
    *)
        echo "Uso: init | migrate | rollback <n> | verify | status" >&2
        exit 2
        ;;
esac

echo "SQL Server: listo."
