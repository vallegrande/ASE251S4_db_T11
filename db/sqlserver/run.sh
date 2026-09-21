#!/bin/bash

set -e

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

if [ ! -f "$SQLCMD" ]; then
    SQLCMD="/opt/mssql-tools/bin/sqlcmd"
fi

echo "=========================================="
echo " AgriMarket - SQL Server Initialization"
echo "=========================================="

echo "Esperando a SQL Server..."

until $SQLCMD \
    -S "$SQL_HOST" \
    -U "$SQL_ADMIN_USER" \
    -P "$SQL_ADMIN_PASSWORD" \
    -C \
    -Q "SELECT 1" >/dev/null 2>&1
do
    sleep 3
    echo "SQL Server todavía no está disponible..."
done

echo "SQL Server disponible."

$SQLCMD \
    -S "$SQL_HOST" \
    -U "$SQL_ADMIN_USER" \
    -P "$SQL_ADMIN_PASSWORD" \
    -C \
    -Q "IF DB_ID('Agrimarket') IS NULL CREATE DATABASE Agrimarket;"

echo "Base de datos Agrimarket verificada."

if [ "$1" = "init" ]; then

    echo "Ejecutando baseline..."

    $SQLCMD \
        -S "$SQL_HOST" \
        -U "$SQL_ADMIN_USER" \
        -P "$SQL_ADMIN_PASSWORD" \
        -C \
        -d Agrimarket \
        -i /lab/bootstrap/V001__baseline.sql

    echo "Ejecutando cambios versionados..."

    for FILE in /lab/changes/V*.sql
    do
        [ -e "$FILE" ] || continue

        echo "Ejecutando $(basename "$FILE")..."

        $SQLCMD \
            -S "$SQL_HOST" \
            -U "$SQL_ADMIN_USER" \
            -P "$SQL_ADMIN_PASSWORD" \
            -C \
            -d Agrimarket \
            -i "$FILE"
    done

    echo "=========================================="
    echo " AgriMarket SQL Server inicializado"
    echo "=========================================="

elif [ "$1" = "check" ]; then

    echo "Verificando tablas..."

    $SQLCMD \
        -S "$SQL_HOST" \
        -U "$SQL_ADMIN_USER" \
        -P "$SQL_ADMIN_PASSWORD" \
        -C \
        -d Agrimarket \
        -Q "SELECT name FROM sys.tables ORDER BY name;"

fi