#!/bin/bash

set -e

MONGO_HOST="${MONGO_HOST:-mongodb}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_ADMIN_USER:-root}"
MONGO_PASSWORD="${MONGO_ADMIN_PASSWORD}"
MONGO_DB="${MONGO_DB:-agrimarket}"

MONGO_CMD="mongosh --host $MONGO_HOST --port $MONGO_PORT -u $MONGO_USER -p $MONGO_PASSWORD --authenticationDatabase admin"

echo "=========================================="
echo " AgriMarket - MongoDB Initialization"
echo "=========================================="

echo "Esperando a MongoDB..."

until $MONGO_CMD --quiet --eval "db.adminCommand('ping').ok" >/dev/null 2>&1
do
    sleep 3
    echo "MongoDB todavía no está disponible..."
done

echo "MongoDB disponible."

$MONGO_CMD --quiet --eval "
const database = db.getSiblingDB('$MONGO_DB');
database.schema_changes.createIndex(
    { version: 1 },
    { unique: true, name: 'uk_schema_changes_version' }
);
"

run_migration() {

    FILE="$1"
    VERSION=$(basename "$FILE" | cut -d'_' -f1)

    CHECKSUM=$(sha256sum "$FILE" | awk '{print $1}')

    EXISTS=$($MONGO_CMD --quiet --eval "
        const database = db.getSiblingDB('$MONGO_DB');
        const result = database.schema_changes.findOne({version: '$VERSION'});
        print(result ? 'YES' : 'NO');
    ")

    if [ "$EXISTS" = "YES" ]; then

        STORED_CHECKSUM=$($MONGO_CMD --quiet --eval "
            const database = db.getSiblingDB('$MONGO_DB');
            const result = database.schema_changes.findOne({version: '$VERSION'});
            print(result.checksum);
        ")

        if [ "$STORED_CHECKSUM" != "$CHECKSUM" ]; then
            echo "ERROR: El checksum de $FILE cambió."
            exit 1
        fi

        echo "$VERSION ya fue ejecutado."

    else

        echo "Ejecutando $FILE..."

        $MONGO_CMD "$FILE"

        $MONGO_CMD --quiet --eval "
            const database = db.getSiblingDB('$MONGO_DB');
            database.schema_changes.insertOne({
                version: '$VERSION',
                script: '$(basename "$FILE")',
                checksum: '$CHECKSUM',
                executedAt: new Date(),
                releaseVersion: '$RELEASE_VERSION',
                gitSha: '$GIT_SHA'
            });
        "

        echo "$VERSION ejecutado correctamente."
    fi
}

if [ "$1" = "init" ]; then

    echo "Ejecutando baseline..."

    run_migration /lab/bootstrap/V001__baseline.js

    echo "Ejecutando cambios versionados..."

    for FILE in /lab/changes/V*.js
    do
        [ -e "$FILE" ] || continue
        run_migration "$FILE"
    done

    echo "=========================================="
    echo " AgriMarket MongoDB inicializado"
    echo "=========================================="

elif [ "$1" = "check" ]; then

    echo "Verificando MongoDB..."

    $MONGO_CMD --quiet --eval "
        const database = db.getSiblingDB('$MONGO_DB');
        print('Base de datos: ' + database.getName());
        print('Colecciones:');
        database.getCollectionNames().forEach(print);
        print('Versiones ejecutadas:');
        database.schema_changes.find().sort({version: 1}).forEach(printjson);
    "

fi