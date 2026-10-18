# Demostración de TRANSACCIONES en MongoDB (replica set).
# Requisito: haber levantado la base con Liquibase (demo-liquibase.ps1 o: docker compose up -d --build).
# Ejecutar en PowerShell:  .\demo\demo-transacciones.ps1      (ENTER entre pasos)
$ErrorActionPreference = "Continue"
Set-Location (Split-Path -Parent $PSScriptRoot)
$env:COMPOSE_FILE = "compose.liquibase.yaml"

function Paso($texto) {
    Write-Host ""; Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host $texto -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}
function Pausa { Read-Host "`n>> ENTER para continuar" | Out-Null }
function Script($nombre) { docker compose exec -T mongodb mongosh --quiet "/transactions/$nombre" }

Paso "0) Comprobar que MongoDB es un replica set (obligatorio para transacciones)"
docker compose up -d --build --wait mongodb
docker compose run --rm liquibase-mongodb update
docker compose exec -T mongodb mongosh --quiet --eval "rs.status().set"
Pausa

Paso "1) BRANDO - Confirmar una compra: COMMIT (carrito + cliente + evento, todo junto)"
Script "00-reset-demo.js"
Script "01-checkout-commit.js"
Pausa

Paso "2) BRANDO - Confirmar una compra: ABORT (no queda nada a medias)"
Script "02-checkout-abort.js"
Pausa

Paso "3) GIANCARLOS - Cambiar precio: COMMIT (producto + historial)"
Script "03-price-change-commit.js"
Pausa

Paso "4) GIANCARLOS - Cambiar precio: ABORT (precio inválido, se deshace todo)"
Script "04-price-change-abort.js"
Pausa

Paso "5) LOCKS - Qué pasa con el documento mientras la transacción está abierta"
Script "05-locks-write-conflict.js"
Pausa

Paso "6) Limpiar los datos de la demostración"
Script "00-reset-demo.js"
