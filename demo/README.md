# Demostración

Scripts para mostrar el versionamiento y el modelado con **Referencing** (ver `docs/GUION_VIDEO.md`).

| Script | Qué hace |
|---|---|
| `demo-evolucion.sh` | Recorre paso a paso: base en V003 → avanzar a la última versión → rollback a V003 → volver a avanzar. Pide ENTER entre pasos. |
| `demo-referencing.sh` | Ejecuta `referencing-queries.js`: cuatro consultas `$lookup`, una por cada ejemplo de Referencing. |
| `referencing-queries.js` | Las consultas de la demostración (también se pueden pegar en `mongosh`). |

Requisitos: Docker Compose y el archivo `.env` creado desde `.env.example`.
En Windows se ejecutan desde Git Bash o WSL.

## Scripts de PowerShell (Liquibase y transacciones)

| Script | Qué hace |
|---|---|
| `demo-liquibase.ps1` | Liquibase paso a paso: SQL Server y MongoDB, `update`, `update-count`, rollback y volver a avanzar |
| `demo-transacciones.ps1` | Transacciones de MongoDB: commit, abort y bloqueos |

Si PowerShell no deja ejecutarlos, habilita scripts solo en esa ventana:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\demo\demo-liquibase.ps1
```
