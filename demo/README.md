# Demostración

Scripts para mostrar el versionamiento y el modelado con **Referencing** (ver `docs/GUION_VIDEO.md`).

| Script | Qué hace |
|---|---|
| `demo-evolucion.sh` | Recorre paso a paso: base en V003 → avanzar a la última versión → rollback a V003 → volver a avanzar. Pide ENTER entre pasos. |
| `demo-referencing.sh` | Ejecuta `referencing-queries.js`: cuatro consultas `$lookup`, una por cada ejemplo de Referencing. |
| `referencing-queries.js` | Las consultas de la demostración (también se pueden pegar en `mongosh`). |

Requisitos: Docker Compose y el archivo `.env` creado desde `.env.example`.
En Windows se ejecutan desde Git Bash o WSL.
