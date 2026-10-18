// ================================================================
// TRANSACCIÓN 3 (Giancarlos) - CAMBIAR EL PRECIO DE UN PRODUCTO  ->  COMMIT
//
// Cambiar un precio toca DOS colecciones:
//   1) products              : nuevo basePrice
//   2) product_price_history : registro del cambio (precio anterior y nuevo)
// Si solo se hiciera una de las dos, el historial quedaría inconsistente.
// ================================================================
const database = db.getSiblingDB("Agrimarket");
if (!db.hello().setName) {
    throw new Error("Este MongoDB NO es un replica set: no soporta transacciones. Usa compose.liquibase.yaml.");
}

const PRODUCT_ID = NumberLong(2);

// --- Preparación ---
database.products.updateOne({ _id: PRODUCT_ID }, { $set: { basePrice: NumberDecimal("95.00") } });
database.product_price_history.deleteMany({ reason: "DEMO-TX" });

print("\n=== ANTES ===");
print("  precio actual: " + database.products.findOne({ _id: PRODUCT_ID }).basePrice);
print("  cambios de precio demo en el historial: " + database.product_price_history.countDocuments({ reason: "DEMO-TX" }));

const session = db.getMongo().startSession();
const sdb = session.getDatabase("Agrimarket");
try {
    session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    print("\n>>> startTransaction");

    const antes = sdb.products.findOne({ _id: PRODUCT_ID }).basePrice;
    sdb.products.updateOne({ _id: PRODUCT_ID }, { $inc: { basePrice: NumberDecimal("3.00") } });
    const despues = sdb.products.findOne({ _id: PRODUCT_ID }).basePrice;
    print("    1) precio cambiado dentro de la transacción: " + antes + " -> " + despues);

    sdb.product_price_history.insertOne({
        productId: PRODUCT_ID, oldPrice: antes, newPrice: despues, changedAt: new Date(), changedBy: "giancarlos", reason: "DEMO-TX"
    });
    print("    2) cambio registrado en el historial");

    print("\n--- Visto desde fuera, sin commit: el precio sigue en " + database.products.findOne({ _id: PRODUCT_ID }).basePrice + " ---");

    session.commitTransaction();
    print("\n>>> commitTransaction");
} catch (e) {
    print("ERROR: " + e.message);
    try { session.abortTransaction(); } catch (_) { }
} finally {
    session.endSession();
}

print("\n=== DESPUÉS ===");
print("  precio actual: " + database.products.findOne({ _id: PRODUCT_ID }).basePrice);
database.product_price_history.find({ productId: PRODUCT_ID }).sort({ changedAt: 1 }).forEach(function (h) {
    print("  historial: " + h.oldPrice + " -> " + h.newPrice + "  (" + h.reason + ")");
});
