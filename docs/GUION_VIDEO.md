# Guion del video demostrativo (cada integrante con cámara activa)

Duración sugerida: 8 a 10 minutos. Cada integrante se presenta con cámara activa y explica su parte.
Ejecuta los comandos desde la carpeta del repositorio.

## 0. Preparación (antes de grabar)

```bash
cp .env.example .env
docker compose down --volumes
```

## 1. Introducción — ambos

- Equipo 11, proyecto **AgriMarket**, estrategia asignada: **Referencing**.
- Mostrar la estructura: `db/mongodb/bootstrap`, `changes`, `changes/down`, `checks`, `run.sh`.
- Explicar la regla: cada cambio es un archivo nuevo `V00N__…`, registrado con checksum en `schema_changes`.

## 2. Base en V003 — Brando

```bash
TARGET_SCHEMA_VERSION=3 docker compose up -d --build
docker compose run --rm mongodb-init status
```

Mostrar que existen las colecciones del baseline y **no** existen las de Referencing.

## 3. Brando: V004 y V005

1. Abrir `V004__customer_wishlists.js` y explicar: relación N:M cliente ↔ producto, por qué Referencing, validador e índice único.
2. Abrir `V005__order_events.js`: historial de pedido, referencia al pedido de SQL Server y al cliente.
3. Aplicar:

```bash
docker compose run --rm -e TARGET_SCHEMA_VERSION=5 mongodb-init init
docker compose run --rm mongodb-init status
```

## 4. Giancarlos: V006 y V007

1. Abrir `V006__supplier_products.js`: catálogo proveedor ↔ producto con costo y días de entrega.
2. Abrir `V007__product_price_history.js`: historial de precios, por qué no se incrusta en `products`.
3. Aplicar:

```bash
docker compose run --rm -e TARGET_SCHEMA_VERSION=latest mongodb-init init
docker compose run --rm mongodb-init status
```

## 5. Ver las referencias — ambos

```bash
./demo/demo-referencing.sh
```

Cada integrante explica el resultado de **sus dos** consultas `$lookup`.

## 6. Intercalar entre versiones — ambos

```bash
docker compose run --rm mongodb-init rollback 3      # vuelve a V003
docker compose run --rm mongodb-init status
docker compose run --rm -e TARGET_SCHEMA_VERSION=latest mongodb-init init   # avanza otra vez
docker compose run --rm mongodb-init verify
```

Mostrar que el contrato se cumple en cada punto y que el historial refleja la versión actual.

## 7. Protección del historial (opcional, 1 minuto)

Editar cualquier línea de `V004__customer_wishlists.js`, reconstruir y volver a ejecutar:

```bash
docker compose build mongodb-init
docker compose run --rm mongodb-init init
```

El runner se detiene con *"el checksum de V004… cambió después de aplicarse"*. **Deshacer el cambio**
(`git checkout -- db/mongodb/changes/V004__customer_wishlists.js`) y reconstruir de nuevo.

## 8. Cierre — ambos

Resumen: 4 ejemplos de Referencing, versionados, con rollback y verificación automática.

> Atajo: `./demo/demo-evolucion.sh` recorre los pasos 2 a 6 pidiendo ENTER entre cada uno.
