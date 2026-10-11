# Puesta en marcha en una máquina nueva

## Requisitos

- Git
- Docker Desktop (o Docker Engine + Compose v2) en ejecución
- Puertos libres: `1433` (SQL Server) y `27017` (MongoDB), o cámbialos en `.env`

## Pasos

```bash
git clone <URL-del-repositorio>
cd ASE251S4_db_T11

cp .env.example .env          # Windows (PowerShell): copy .env.example .env
# Edita .env y cambia las contraseñas (SQL Server exige mayúsculas, minúsculas, números y símbolos)

docker compose up -d --build
docker compose logs --no-color mongodb-init sqlserver-init
```

Resultado esperado en los logs:

```
MongoDB: aplicando V001__baseline.js
...
MongoDB: contrato V7 verificado (historial, colecciones, índices y referencias).
SQL Server: contrato verificado para la version objetivo.
```

## Conectarse

| Motor | Host | Usuario | Base |
|---|---|---|---|
| SQL Server | `localhost,1433` | `sa` | `Agrimarket` |
| MongoDB | `localhost:27017` | `root` (authSource `admin`) | `Agrimarket` |

Variables para el backend `ASE251S4_T11-be`:

```
MONGODB_URI=mongodb://root:<clave>@localhost:27017/Agrimarket?authSource=admin
MONGODB_DATABASE=Agrimarket
SQLSERVER_HOST=localhost
SQLSERVER_PORT=1433
SQLSERVER_DATABASE=Agrimarket
SQLSERVER_USER=sa
SQLSERVER_PASSWORD=<clave>
```

## Ver las colecciones en el navegador (opcional)

```bash
docker compose -f compose.yaml -f compose.tools.yaml up -d mongo-express   # http://localhost:8081
```

## Reiniciar todo

```bash
docker compose down --volumes
docker compose up -d --build
```

> Los datos viven en volúmenes de Docker: `down` los conserva, `down --volumes` los borra.
