// ================================================================
// V007 - REFERENCING (ejemplo 2 de Giancarlos) - product_price_history
//
// Historial de cambios de precio de un producto (maestro products).
// El historial crece con el tiempo y casi nunca se consulta junto con el
// producto, así que NO se incrusta en products (el documento principal
// se mantiene liviano). Cada cambio apunta al producto por su id.
//
//   product_price_history.productId -> products._id
// ================================================================

const database = db.getSiblingDB("Agrimarket");

if (database.getCollectionInfos({ name: "product_price_history" }).length === 0) {
    database.createCollection("product_price_history", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["productId", "oldPrice", "newPrice", "changedAt"],
                properties: {
                    productId: { bsonType: ["long", "int"], description: "Referencia a products._id" },
                    oldPrice: { bsonType: "decimal" },
                    newPrice: { bsonType: "decimal" },
                    changedAt: { bsonType: "date" },
                    changedBy: { bsonType: "string", maxLength: 100 },
                    reason: { bsonType: "string", maxLength: 300 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

database.product_price_history.createIndex(
    { productId: 1, changedAt: -1 },
    { name: "ix_price_history_product_time" }
);

[
    { productId: 1, oldPrice: "17.00", newPrice: "18.50", date: "2026-03-01", reason: "Aumento del costo del proveedor" },
    { productId: 2, oldPrice: "85.00", newPrice: "90.00", date: "2026-04-10", reason: "Ajuste de temporada" },
    { productId: 2, oldPrice: "90.00", newPrice: "95.00", date: "2026-08-15", reason: "Aumento del costo del proveedor" }
].forEach(function (item) {
    const productId = NumberLong(item.productId);
    if (database.products.countDocuments({ _id: productId }) !== 1) {
        throw new Error("Referencia inválida: products._id=" + productId);
    }
    const changedAt = new Date(item.date);
    if (database.product_price_history.countDocuments({ productId: productId, changedAt: changedAt }) === 0) {
        database.product_price_history.insertOne({
            productId: productId,
            oldPrice: NumberDecimal(item.oldPrice),
            newPrice: NumberDecimal(item.newPrice),
            changedAt: changedAt,
            changedBy: "admin",
            reason: item.reason
        });
    }
});

print("AgriMarket MongoDB V007 ejecutado correctamente.");
