# Demostración paso a paso de LIQUIBASE (SQL Server + MongoDB).
# Ejecutar en PowerShell desde cualquier carpeta:  .\demo\demo-liquibase.ps1
# Presiona ENTER entre pasos.
$ErrorActionPreference = "Continue"
Set-Location (Split-Path -Parent $PSScriptRoot)
$env:COMPOSE_FILE = "compose.liquibase.yaml"

# Carga las variables del .env (SQL_ADMIN_PASSWORD, etc.)
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
}

function Paso($texto) {
    Write-Host ""; Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host $texto -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}
function Pausa { Read-Host "`n>> ENTER para continuar" | Out-Null }
function SqlQuery($q) { docker compose exec -T sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $env:SQL_ADMIN_PASSWORD -C -d Agrimarket -Q $q }

Paso "1) Empezar desde cero: se borran contenedores y volúmenes"
docker compose down --volumes
Pausa

Paso "2) Levantar SOLO los motores (SQL Server y MongoDB como replica set)"
docker compose up -d --build --wait mongodb sqlserver
docker compose build liquibase-mongodb
Pausa

Paso "3) SQL Server: ¿qué cambios están pendientes? (status)"
docker compose run --rm liquibase-sqlserver status --verbose
Pausa

Paso "4) SQL Server: aplicar los cambios (update) y ver el historial"
docker compose run --rm liquibase-sqlserver update
docker compose run --rm liquibase-sqlserver history
SqlQuery "SELECT id, author, dateexecuted FROM DATABASECHANGELOG ORDER BY orderexecuted;"
Pausa

Paso "5) MongoDB: aplicar SOLO hasta la versión 3 (update-count)"
docker compose run --rm liquibase-mongodb update-count --count=3
docker compose exec -T mongodb mongosh --quiet /demo/mongo-collections.js
docker compose exec -T mongodb mongosh --quiet /demo/mongo-liquibase-history.js
Pausa

Paso "6) MongoDB: avanzar a la última versión (V004 a V007: Referencing)"
docker compose run --rm liquibase-mongodb update
docker compose exec -T mongodb mongosh --quiet /demo/mongo-collections.js
docker compose exec -T mongodb mongosh --quiet /demo/mongo-liquibase-history.js
Pausa

Paso "7) Ver las referencias funcionando (consultas lookup)"
docker compose exec -T mongodb mongosh --quiet /demo/referencing-queries.js
Pausa

Paso "8) ROLLBACK: retroceder los últimos 4 cambios (vuelve a la versión 3)"
docker compose run --rm liquibase-mongodb rollback-count --count=4
docker compose exec -T mongodb mongosh --quiet /demo/mongo-collections.js
docker compose exec -T mongodb mongosh --quiet /demo/mongo-liquibase-history.js
Pausa

Paso "9) Volver a avanzar a la última versión"
docker compose run --rm liquibase-mongodb update
docker compose exec -T mongodb mongosh --quiet /demo/mongo-liquibase-history.js
Write-Host "`nListo: SQL Server y MongoDB versionados con Liquibase." -ForegroundColor Green
