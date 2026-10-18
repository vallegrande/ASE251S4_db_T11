// ================================================================
// TRANSACCIÓN 2 (Brando) - CONFIRMAR UNA COMPRA  ->  ABORT
//
// Caso A: regla de negocio (el carrito está vacío)  -> abortTransaction() explícito
// Caso B: error de la base de datos (el evento no cumple el validador) -> se aborta todo
// En ambos casos NADA queda a medias: carrito, cliente y eventos siguen como estaban.
// ================================================================
const database = db.getSiblingDB("Agrimarket");
if (!db.hello().setName) {
    throw new Error("Este MongoDB NO es un replica set: no soporta transacciones. Usa compose.liquibase.yaml.");
}

const CUSTOMER_ID = NumberLong(1);

function estado(cartId, orderId, titulo) {
    const cart = database.carts.findOne({ _id: cartId });
    const cust = database.customers.findOne({ _id: CUSTOMER_ID });
    print("  [" + titulo + "] carrito=" + (cart ? cart.checkoutState : "-") + " | totalVisits=" + cust.totalVisits +
        " | eventos=" + database.order_events.countDocuments({ orderId: orderId }));
}

function confirmarCompra(cartId, orderId, eventType) {
    const session = db.getMongo().startSession();
    const sdb = session.getDatabase("Agrimarket");
    try {
        session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
        sdb.carts.updateOne({ _id: cartId, checkoutState: "OPEN" }, { $set: { checkoutState: "COMPLETED" } });
        sdb.customers.updateOne({ _id: CUSTOMER_ID }, { $inc: { totalVisits: 1 } });

        const cart = sdb.carts.findOne({ _id: cartId });
        if (cart.items.length === 0) {                          // Caso A: regla de negocio
            print("    Regla de negocio: el carrito está vacío -> abortTransaction()");
            session.abortTransaction();
            return;
        }

        sdb.order_events.insertOne({ orderId: orderId, customerId: CUSTOMER_ID, eventType: eventType, eventAt: new Date() });   // Caso B puede fallar aquí
        session.commitTransaction();
        print("    commitTransaction");
    } catch (e) {
        print("    ERROR de la base de datos: " + e.codeName + " (" + e.code + ")");
        try { session.abortTransaction(); print("    abortTransaction()"); } catch (_) { print("    (el servidor ya había abortado la transacción)"); }
    } finally {
        session.endSession();
    }
}

// --- Preparación ---
database.customers.updateOne({ _id: CUSTOMER_ID }, { $set: { totalVisits: NumberInt(0) } });
database.carts.replaceOne({ _id: "demo-cart-002" }, { _id: "demo-cart-002", customerId: "1", checkoutState: "OPEN", totalAmount: NumberDecimal("0.00"), items: [], createdAt: new Date() }, { upsert: true });
database.carts.replaceOne({ _id: "demo-cart-001" }, {
    _id: "demo-cart-001", customerId: "1", checkoutState: "OPEN", totalAmount: NumberDecimal("37.00"),
    items: [{ productId: "1", productName: "Fungicida Cobre 50 WP", unitPrice: NumberDecimal("18.50"), quantity: 2, subtotal: NumberDecimal("37.00") }], createdAt: new Date()
}, { upsert: true });
database.order_events.deleteMany({ orderId: { $in: [NumberInt(9002), NumberInt(9003)] } });

print("\n=== CASO A: carrito vacío (regla de negocio) ===");
estado("demo-cart-002", NumberInt(9002), "antes");
confirmarCompra("demo-cart-002", NumberInt(9002), "CREATED");
estado("demo-cart-002", NumberInt(9002), "después (nada cambió)");

print("\n=== CASO B: el evento tiene un tipo inválido (el validador lo rechaza) ===");
estado("demo-cart-001", NumberInt(9003), "antes");
confirmarCompra("demo-cart-001", NumberInt(9003), "EXPLOTO");
estado("demo-cart-001", NumberInt(9003), "después (el carrito y el cliente NO cambiaron, aunque se habían modificado antes del error)");
