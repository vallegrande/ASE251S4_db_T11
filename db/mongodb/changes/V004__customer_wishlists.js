// ================================================================
// V004 - REFERENCING (ejemplo 1 de Brando) - customer_wishlists
//
// Relación MUCHOS A MUCHOS entre el maestro customers y el maestro products.
//   - Un cliente puede guardar muchos productos como favoritos.
//   - Un producto puede estar en los favoritos de muchos clientes.
// Por eso NO se incrusta (embedding) dentro de customers ni de products:
// la lista crecería sin límite y duplicaría datos del producto (nombre,
// precio) que cambian. Cada documento guarda solo los ids que referencia.
//
//   customer_wishlists.customerId -> customers._id
//   customer_wishlists.productId  -> products._id
// ================================================================

const database = db.getSiblingDB("Agrimarket");

if (database.getCollectionInfos({ name: "customer_wishlists" }).length === 0) {
    database.createCollection("customer_wishlists", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["customerId", "productId", "addedAt"],
                properties: {
                    customerId: { bsonType: ["long", "int"], description: "Referencia a customers._id" },
                    productId: { bsonType: ["long", "int"], description: "Referencia a products._id" },
                    addedAt: { bsonType: "date" },
                    note: { bsonType: "string", maxLength: 300 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

database.customer_wishlists.createIndex(
    { customerId: 1, productId: 1 },
    { name: "uq_wishlist_customer_product", unique: true }
);
database.customer_wishlists.createIndex({ productId: 1 }, { name: "ix_wishlist_productId" });

// Las referencias deben apuntar a documentos que existen.
function mustExist(collectionName, id) {
    if (database.getCollection(collectionName).countDocuments({ _id: id }) !== 1) {
        throw new Error("Referencia inválida: " + collectionName + "._id=" + id);
    }
}

[
    { customerId: 1, productId: 1, note: "Para la próxima campaña" },
    { customerId: 1, productId: 2, note: null },
    { customerId: 2, productId: 2, note: "Cotizar por volumen" }
].forEach(function (item) {
    const customerId = NumberLong(item.customerId);
    const productId = NumberLong(item.productId);
    mustExist("customers", customerId);
    mustExist("products", productId);

    if (database.customer_wishlists.countDocuments({ customerId: customerId, productId: productId }) === 0) {
        const document = { customerId: customerId, productId: productId, addedAt: new Date() };
        if (item.note) { document.note = item.note; }
        database.customer_wishlists.insertOne(document);
    }
});

print("AgriMarket MongoDB V004 ejecutado correctamente.");
