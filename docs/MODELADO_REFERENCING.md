# Modelado de datos con Referencing (MongoDB)

## 1. ¿Qué es?

En MongoDB hay dos formas de relacionar información:

- **Embedding:** los datos relacionados se guardan **dentro** del mismo documento.
- **Referencing:** los datos viven en **colecciones separadas** y se conectan guardando el `_id` del otro documento
  (equivalente a una llave foránea en SQL). Para unirlos se usa `$lookup` o una segunda consulta.

```js
// Referencing: el favorito solo guarda los ids
{ customerId: NumberLong(1), productId: NumberLong(2), addedAt: ISODate("...") }
```

## 2. ¿Para qué sirve?

Para mantener **cada dato en un solo lugar**: si el nombre o el precio de un producto cambia, se actualiza una vez
y todos los que lo referencian ven el cambio. También evita documentos gigantes que crecen sin parar.

## 3. ¿Cuándo conviene utilizarlo?

- Relaciones **muchos a muchos** (cliente ↔ producto, proveedor ↔ producto).
- Listas **sin límite** o que crecen con el tiempo (historiales, eventos).
- Datos **compartidos** por muchos documentos o que **cambian seguido**.
- Cuando el documento relacionado se consulta **por separado** con frecuencia.

## 4. Ventajas y limitaciones

| Ventajas | Limitaciones |
|---|---|
| Sin duplicación de datos; una sola fuente de verdad | Leer todo junto requiere `$lookup` o varias consultas |
| Documentos pequeños y livianos | MongoDB **no valida** la referencia por sí solo (no hay FK); hay que cuidarla |
| Escrituras eficientes (se agrega un documento, no se reescribe uno grande) | Más colecciones e índices que mantener |
| Modela bien relaciones N:M y crecimiento ilimitado | Si siempre se lee junto, embedding sería más rápido |

En este repositorio la integridad se protege con **validadores `$jsonSchema`**, **índices únicos** y el
**contrato `checks/contract.js`**, que verifica que ninguna referencia apunte a un documento inexistente.

## 5. Mapa de entidades del proyecto

| Entidad | Motor | Rol | Responsable |
|---|---|---|---|
| `customers` | MongoDB | **Maestro** | Brando |
| `order`, `order_detail` | SQL Server | **Transaccional** | Brando |
| `products` | MongoDB | **Maestro** | Giancarlos |
| `purchase_order`, `purchase_order_detail` | SQL Server | **Transaccional** | Giancarlos |
| `suppliers`, `brands`, `categories`, `ubigeos` | MongoDB | Maestros de apoyo | Equipo |
| `carts`, `staff_users`, `auth_sessions`, `counters` | MongoDB | Apoyo del backend | Equipo |
| `store`, `inventory` | SQL Server | Tiendas e inventario | Equipo |

## 6. Aplicaciones en el proyecto (2 por integrante)

### Brando — maestro `customers`, transaccional `order`

**Ejemplo 1 · V004 `customer_wishlists` (cliente ↔ producto)**
- Referencias: `customerId → customers._id`, `productId → products._id`.
- Por qué Referencing: es N:M y la lista de favoritos de un cliente puede crecer sin límite; incrustar los productos
  duplicaría nombre y precio, que cambian. Un índice único `(customerId, productId)` evita repetidos.
- Valor de negocio: recordar productos de interés para campañas y reposición.

**Ejemplo 2 · V005 `order_events` (historial del pedido)**
- Referencias: `orderId → dbo.[order].order_id` (SQL Server), `customerId → customers._id`.
- Por qué Referencing: un pedido acumula una cantidad no acotada de eventos (creado, confirmado, listo para recoger,
  entregado, anulado). Guardarlos como evento aparte evita reescribir un documento grande en cada cambio de estado.
  Entre motores distintos no existe FK, por eso la referencia es lógica.
- Valor de negocio: trazabilidad del pedido de recogida en tienda.

### Giancarlos — maestro `products`, transaccional `purchase_order`

**Ejemplo 1 · V006 `supplier_products` (proveedor ↔ producto)**
- Referencias: `supplierId → suppliers._id`, `productId → products._id`.
- Por qué Referencing: es N:M con datos propios de la relación (sku del proveedor, costo, días de entrega).
  No pertenece ni al proveedor ni al producto, así que va en su propia colección.
- Valor de negocio: elegir al proveedor más barato o rápido al armar una orden de compra.

**Ejemplo 2 · V007 `product_price_history` (historial de precios)**
- Referencia: `productId → products._id`.
- Por qué Referencing: el historial crece con el tiempo y rara vez se lee junto con el producto; el documento
  `products` se mantiene liviano.
- Valor de negocio: auditar cambios de precio y analizar márgenes.

## 7. Comparación Embedding vs Referencing (aplicado a AgriMarket)

| Criterio | Embedding | Referencing |
|---|---|---|
| Ejemplo en el proyecto | `customers.ubigeo` y `carts.items` ya van incrustados | los 4 ejemplos de este repositorio |
| Lectura | Una sola consulta | `$lookup` / segunda consulta |
| Duplicación | Sí (copia de datos) | No |
| Crecimiento del documento | Limitado (16 MB por documento) | Sin límite práctico |
| Consistencia | Hay que actualizar todas las copias | Un solo lugar |
| Ideal para | Datos que se leen siempre juntos y casi no cambian | N:M, historiales, datos compartidos o cambiantes |

## 8. Cómo ver las referencias funcionando

```bash
./demo/demo-referencing.sh
```

Ejecuta cuatro `$lookup` (uno por ejemplo). Las consultas están en `demo/referencing-queries.js`.

## 9. Notas técnicas

- Los `_id` de `customers`, `products` y `suppliers` son `Long`. Las referencias nuevas usan **el mismo tipo que el `_id`
  de destino** para que `$lookup` funcione sin conversiones. (Algunas clases Java existentes, como `Product.categoryId`,
  guardan la referencia como `String`; no se modificaron.)
- El backend todavía no tiene clases Java para las 4 colecciones nuevas; los scripts de BD ya las crean con datos
  de ejemplo. Mapearlas con `@Document` es un paso opcional posterior.
- Los índices de `customers`, `staff_users` y `auth_sessions` en V001 usan los nombres que genera Spring Data
  (`email`, `tokenHash`, `expiresAt`, `ux_customer_document`) para no chocar con `auto-index-creation`.
- Los ids sembrados (productos 1-3, clientes 1-2, proveedores 1-2) coinciden entre MongoDB y SQL Server.
