# Evolución del esquema y de los datos

Cómo agregar un cambio nuevo de forma ordenada y reproducible.

## Estructura

```
db/
├── mongodb/
│   ├── bootstrap/      V001__baseline.js         estado inicial (solo se ejecuta desde cero)
│   ├── changes/        V002__nombre.js …         cambios incrementales, uno por versión
│   │   └── down/       V002__nombre.down.js …    cómo revertir cada cambio
│   ├── checks/         contract.js               qué debe cumplirse en cada versión
│   └── metadata/       record-change.js          historial en la colección schema_changes
└── sqlserver/          (misma estructura, archivos .sql; historial en dbo.schema_changes)
```

## Reglas

1. **Nombre:** `V00N__descripcion.js` (o `.sql`). `N` es **consecutivo**, sin saltos (si falta una versión, el runner se detiene).
2. **Un cambio nuevo = un archivo nuevo.** Nunca edites uno ya aplicado: el runner guarda su checksum SHA-256 y falla si cambia.
3. **Cada cambio tiene su `down`** en `changes/down/` con el mismo número y nombre: `V00N__descripcion.down.js`.
4. Los scripts deben ser **repetibles** (`createCollection` solo si no existe, datos semilla solo si faltan).
5. Si el cambio agrega colecciones o índices, **actualiza `checks/contract.js`** para que la verificación los conozca.

## Agregar un cambio en MongoDB (ejemplo V008)

```js
// db/mongodb/changes/V008__ejemplo.js
const database = db.getSiblingDB("Agrimarket");
if (database.getCollectionInfos({ name: "ejemplo" }).length === 0) {
    database.createCollection("ejemplo");
}
database.ejemplo.createIndex({ campo: 1 }, { name: "ix_ejemplo_campo" });
print("AgriMarket MongoDB V008 ejecutado correctamente.");
```

```js
// db/mongodb/changes/down/V008__ejemplo.down.js
db.getSiblingDB("Agrimarket").getCollection("ejemplo").drop();
```

## Aplicar y verificar

Los scripts se copian dentro de la imagen, así que hay que reconstruirla:

```bash
docker compose up -d --build            # aplica hasta la última versión
docker compose run --rm mongodb-init status
docker compose run --rm mongodb-init verify
```

## Elegir versión y retroceder

| Acción | Comando |
|---|---|
| Crear la base hasta V004 | `docker compose down --volumes && TARGET_SCHEMA_VERSION=4 docker compose up -d --build` |
| Avanzar a la última | `docker compose run --rm -e TARGET_SCHEMA_VERSION=latest mongodb-init init` |
| Retroceder a V003 | `docker compose run --rm mongodb-init rollback 3` |
| Empezar de cero | `docker compose down --volumes` |

Con `init` el runner **no retrocede solo**: si la base está en V007 y pides V004, te indica usar `rollback 4`.

## Errores típicos

| Mensaje | Causa | Solución |
|---|---|---|
| `el checksum de V00N cambió` | Editaste un script ya aplicado | Restaura el archivo y crea la siguiente versión |
| `se esperaba V00N y se encontró …` | Hay un salto en la numeración | Renumera para que sea consecutivo |
| `falta el script down para V00N` | No existe `changes/down/V00N__*.down.js` | Créalo |
| `CONTRATO NO CUMPLIDO: …` | La base no coincide con lo esperado en esa versión | Revisa el mensaje; suele faltar actualizar `contract.js` |
