// ================================================================
// V006 - REFERENCING (ejemplo 1 de Giancarlos) - supplier_products
//
// Catálogo de compra: qué proveedor vende qué producto y a qué costo.
// Relación MUCHOS A MUCHOS entre suppliers y products, con datos propios
// de la relación (sku del proveedor, costo, días de entrega). Es la fuente
// para armar las órdenes de compra (purchase_order / purchase_order_detail).
//
//   supplier_products.supplierId -> suppliers._id
//   supplier_products.productId  -> products._id
// ================================================================

const database = db.getSiblingDB("Agrimarket");

if (database.getCollectionInfos({ name: "supplier_products" }).length === 0) {
    database.createCollection("supplier_products", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["supplierId", "productId", "unitCost", "isActive"],
                properties: {
                    supplierId: { bsonType: ["long", "int"], description: "Referencia a suppliers._id" },
                    productId: { bsonType: ["long", "int"], description: "Referencia a products._id" },
                    supplierSku: { bsonType: "string", maxLength: 50 },
                    unitCost: { bsonType: "decimal", description: "Costo unitario de compra" },
                    leadTimeDays: { bsonType: ["int", "long"], minimum: 0 },
                    isActive: { bsonType: "bool" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

database.supplier_products.createIndex(
    { supplierId: 1, productId: 1 },
    { name: "uq_supplier_products", unique: true }
);
database.supplier_products.createIndex({ productId: 1 }, { name: "ix_supplier_products_productId" });

function mustExist(collectionName, id) {
    if (database.getCollection(collectionName).countDocuments({ _id: id }) !== 1) {
        throw new Error("Referencia inválida: " + collectionName + "._id=" + id);
    }
}

[
    { supplierId: 1, productId: 1, sku: "DAC-FUN-001", cost: "15.20", days: 3 },
    { supplierId: 1, productId: 3, sku: "DAC-FER-046", cost: "98.00", days: 5 },
    { supplierId: 2, productId: 2, sku: "IDV-NPK-202020", cost: "78.50", days: 4 },
    { supplierId: 2, productId: 3, sku: "IDV-UREA-50", cost: "101.00", days: 4 }
].forEach(function (item) {
    const supplierId = NumberLong(item.supplierId);
    const productId = NumberLong(item.productId);
    mustExist("suppliers", supplierId);
    mustExist("products", productId);

    if (database.supplier_products.countDocuments({ supplierId: supplierId, productId: productId }) === 0) {
        database.supplier_products.insertOne({
            supplierId: supplierId,
            productId: productId,
            supplierSku: item.sku,
            unitCost: NumberDecimal(item.cost),
            leadTimeDays: NumberInt(item.days),
            isActive: true
        });
    }
});

print("AgriMarket MongoDB V006 ejecutado correctamente.");
