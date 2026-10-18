// ================================================================
// TRANSACCIÓN 1 (Brando) - CONFIRMAR UNA COMPRA  ->  COMMIT
//
// Confirmar una compra toca TRES colecciones a la vez:
//   1) carts          : el carrito pasa de OPEN a COMPLETED
//   2) customers      : suma una visita y guarda la fecha de última compra
//   3) order_events   : registra el evento CREATED del pedido
// Las tres cosas deben ocurrir juntas o ninguna (Atomicidad).
// ================================================================
const database = db.getSiblingDB("Agrimarket");
if (!db.hello().setName) {
    throw new Error("Este MongoDB NO es un replica set: no soporta transacciones. Usa compose.liquibase.yaml.");
}

const CART_ID = "demo-cart-001";
const CUSTOMER_ID = NumberLong(1);
const ORDER_ID = NumberInt(9001);

function estado(titulo) {
    const cart = database.carts.findOne({ _id: CART_ID });
    const cust = database.customers.findOne({ _id: CUSTOMER_ID });
    print("  [" + titulo + "]");
    print("    carrito.checkoutState : " + (cart ? cart.checkoutState : "(no existe)"));
    print("    cliente.totalVisits   : " + cust.totalVisits);
    print("    eventos del pedido    : " + database.order_events.countDocuments({ orderId: ORDER_ID }));
}

// --- Preparación (fuera de la transacción) ---
database.carts.replaceOne({ _id: CART_ID }, {
    _id: CART_ID, customerId: "1", checkoutState: "OPEN", totalAmount: NumberDecimal("37.00"),
    items: [{ productId: "1", productName: "Fungicida Cobre 50 WP", unitPrice: NumberDecimal("18.50"), quantity: 2, subtotal: NumberDecimal("37.00") }],
    createdAt: new Date()
}, { upsert: true });
database.order_events.deleteMany({ orderId: ORDER_ID });
database.customers.updateOne({ _id: CUSTOMER_ID }, { $set: { totalVisits: NumberInt(0) }, $unset: { lastPurchaseDate: "" } });

print("\n=== ANTES de la transacción ===");
estado("estado inicial");

// --- La transacción ---
const session = db.getMongo().startSession();           // 1) una SESIÓN: el contexto donde vive la transacción
const sdb = session.getDatabase("Agrimarket");           //    (todo lo que se haga con sdb pertenece a la transacción)
try {
    session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });   // 2) startTransaction
    print("\n>>> startTransaction");

    const r1 = sdb.carts.updateOne({ _id: CART_ID, checkoutState: "OPEN" },
        { $set: { checkoutState: "COMPLETED", updatedAt: new Date() } });
    if (r1.modifiedCount !== 1) { throw new Error("El carrito no estaba OPEN"); }
    print("    1) carrito marcado COMPLETED (dentro de la transacción)");

    sdb.customers.updateOne({ _id: CUSTOMER_ID }, { $inc: { totalVisits: 1 }, $set: { lastPurchaseDate: new Date() } });
    print("    2) cliente actualizado (dentro de la transacción)");

    sdb.order_events.insertOne({ orderId: ORDER_ID, customerId: CUSTOMER_ID, eventType: "CREATED", eventAt: new Date(), note: "Compra confirmada (demo transacción)" });
    print("    3) evento CREATED insertado (dentro de la transacción)");

    print("\n--- Lo que ve OTRA conexión mientras la transacción sigue abierta (AISLAMIENTO): nada ha cambiado ---");
    estado("visto desde fuera, sin commit");

    session.commitTransaction();                         // 3) commitTransaction: ahora SÍ se hacen visibles y durables
    print("\n>>> commitTransaction: las tres operaciones se confirmaron juntas");
} catch (e) {
    print("ERROR: " + e.message);
    try { session.abortTransaction(); } catch (_) { /* ya estaba abortada */ }
} finally {
    session.endSession();
}

print("\n=== DESPUÉS del commit ===");
estado("estado final");
