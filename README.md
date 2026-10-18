# AgriMarket - Base de datos versionada (ASE251S4 · Equipo 11)

Repositorio de base de datos de **AgriMarket**: scripts versionados, verificables y reproducibles para
**SQL Server** (tablas transaccionales) y **MongoDB** (colecciones maestras y de apoyo) del backend
Spring WebFlux `ASE251S4_T11-be`.

Actividad **S09 · AP4 – Versionamiento y Modelado de Datos**. Estrategia de modelado asignada al equipo 11: **Referencing**.

## Actividad GBD: Liquibase + transacciones en MongoDB

Además de los scripts propios de la actividad anterior (`db/`), el repositorio incluye:

| Carpeta / archivo | Para qué sirve |
|---|---|
| `compose.liquibase.yaml` | SQL Server + MongoDB (replica set) + contenedores de **Liquibase** |
| `liquibase/sqlserver/` | Changelog de SQL Server (formatted SQL, 4 versiones) |
| `liquibase/mongodb/` | Changelog de MongoDB (YAML, 7 versiones, incluye los 4 ejemplos de Referencing) |
| `transactions/` | Scripts `mongosh` de **transacciones** (commit, abort y bloqueos) |
| `informe/` | Informe con las respuestas teóricas y el paso a paso |
| `demo/*.ps1` | Demostraciones guiadas para el video (PowerShell) |
| `docs/GUION_VIDEO_LIQUIBASE.md` | Guion del video de máximo 20 minutos |

```powershell
$env:COMPOSE_FILE = "compose.liquibase.yaml"      # evita escribir -f cada vez
docker compose up -d --build                      # levanta todo y aplica los changelogs
docker compose run --rm liquibase-mongodb history
docker compose run --rm liquibase-mongodb rollback-count --count=4     # retroceder 4 cambios
docker compose exec -T mongodb mongosh --quiet /transactions/01-checkout-commit.js
```

Puertos de esta versión: SQL Server `1434`, MongoDB `27018` (no chocan con `compose.yaml`).

---

## Qué contiene

```
.
├── compose.yaml                 Motores + contenedores "init" que aplican las versiones
├── compose.tools.yaml           (opcional) Mongo Express para mirar las colecciones
├── .env.example                 Variables de entorno (copiar a .env)
├── .github/workflows/ci.yml     CI: aplica, hace rollback y verifica las versiones
├── db/
│   ├── mongodb/
│   │   ├── bootstrap/           V001 baseline (10 colecciones + datos semilla)
│   │   ├── changes/             V002 … V007 (cambios incrementales)
│   │   │   └── down/            scripts para revertir cada cambio
│   │   ├── checks/contract.js   verifica historial, colecciones, índices y referencias
│   │   ├── metadata/            registra/borra cambios en schema_changes
│   │   ├── Dockerfile
│   │   └── run.sh               runner: init · rollback · verify · status
│   └── sqlserver/               misma estructura (V001 … V003)
├── demo/                        scripts para la demostración en video
└── docs/                        guías (modelado Referencing, evolución, nueva máquina, guion del video)
```

## Inicio rápido

```bash
cp .env.example .env            # y cambia las contraseñas
docker compose up -d --build    # levanta SQL Server + MongoDB y aplica todas las versiones
docker compose logs --no-color mongodb-init sqlserver-init
```

Si todo salió bien, cada init termina con `contrato ... verificado` y `listo`.

## Versiones

| Versión | Motor | Cambio | Responsable |
|---|---|---|---|
| V001 | Mongo + SQL | Baseline: colecciones/tablas, índices y datos semilla | Equipo |
| V002 | Mongo | Índice `suppliers.businessName` | Equipo |
| V002 | SQL | Índice `IX_order_status` | Equipo |
| V003 | Mongo | Índice `suppliers.email` | Equipo |
| V003 | SQL | Columna `inventory.is_active` | Equipo |
| **V004** | Mongo | **Referencing:** `customer_wishlists` (cliente ↔ producto) | Brando |
| **V005** | Mongo | **Referencing:** `order_events` (pedido SQL → cliente) | Brando |
| **V006** | Mongo | **Referencing:** `supplier_products` (proveedor ↔ producto) | Giancarlos |
| **V007** | Mongo | **Referencing:** `product_price_history` (historial → producto) | Giancarlos |

SQL Server termina en V003; si pides una versión mayor, el runner de SQL Server usa su última versión.

## Cambiar de versión (intercalar)

```bash
# Crear la base hasta una versión concreta
docker compose down --volumes
TARGET_SCHEMA_VERSION=3 docker compose up -d --build

# Avanzar a la última
docker compose run --rm -e TARGET_SCHEMA_VERSION=latest mongodb-init init

# Retroceder a V003 (usa db/mongodb/changes/down/*)
docker compose run --rm mongodb-init rollback 3

# Ver el historial / verificar
docker compose run --rm mongodb-init status
docker compose run --rm mongodb-init verify
```

Regla de oro: **nunca edites un script ya aplicado** (el checksum cambia y el runner se detiene). Para cambiar algo, crea la siguiente versión.

## Documentación

- [`docs/MODELADO_REFERENCING.md`](docs/MODELADO_REFERENCING.md) – qué es Referencing, los 4 ejemplos y el mapa de entidades
- [`docs/EVOLUCION_MANUAL.md`](docs/EVOLUCION_MANUAL.md) – cómo agregar un cambio nuevo
- [`docs/INICIALIZACION_NUEVA_MAQUINA.md`](docs/INICIALIZACION_NUEVA_MAQUINA.md) – puesta en marcha desde cero
- [`docs/GUION_VIDEO.md`](docs/GUION_VIDEO.md) – guion del video demostrativo

> Las contraseñas de `.env.example` son solo de desarrollo.
