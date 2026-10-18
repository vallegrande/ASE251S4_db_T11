// ================================================================
// TRANSACCIÓN 4 (Giancarlos) - CAMBIAR EL PRECIO  ->  ABORT
//
// Se intenta poner un precio inválido (negativo). La regla de negocio lo detecta DESPUÉS
// de haber modificado el producto y registrado el historial, y aborta: se deshace todo.
// ================================================================
const database = db.getSiblingDB("Agrimarket");
if (!db.hello().setName) {
    throw new Error("Este MongoDB NO es un replica set: no soporta transacciones. Usa compose.liquibase.yaml.");
}

const PRODUCT_ID = NumberLong(2);
database.products.updateOne({ _id: PRODUCT_ID }, { $set: { basePrice: NumberDecimal("95.00") } });
database.product_price_history.deleteMany({ reason: "DEMO-TX" });

print("\n=== ANTES ===");
print("  precio actual: " + database.products.findOne({ _id: PRODUCT_ID }).basePrice);

const session = db.getMongo().startSession();
const sdb = session.getDatabase("Agrimarket");
try {
    session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    print("\n>>> startTransaction");

    const antes = sdb.products.findOne({ _id: PRODUCT_ID }).basePrice;
    sdb.products.updateOne({ _id: PRODUCT_ID }, { $set: { basePrice: NumberDecimal("-5.00") } });
    const despues = sdb.products.findOne({ _id: PRODUCT_ID }).basePrice;
    sdb.product_price_history.insertOne({ productId: PRODUCT_ID, oldPrice: antes, newPrice: despues, changedAt: new Date(), changedBy: "giancarlos", reason: "DEMO-TX" });
    print("    producto y historial modificados DENTRO de la transacción (precio nuevo: " + despues + ")");

    if (parseFloat(despues.toString()) <= 0) {
        print("    Regla de negocio: el precio debe ser mayor a 0 -> abortTransaction()");
        session.abortTransaction();
    } else {
        session.commitTransaction();
    }
} catch (e) {
    print("ERROR: " + e.message);
    try { session.abortTransaction(); } catch (_) { }
} finally {
    session.endSession();
}

print("\n=== DESPUÉS (todo se deshizo) ===");
print("  precio actual: " + database.products.findOne({ _id: PRODUCT_ID }).basePrice);
print("  cambios en el historial: " + database.product_price_history.countDocuments({ reason: "DEMO-TX" }));
