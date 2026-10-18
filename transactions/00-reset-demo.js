// Deja los datos de las demostraciones como al inicio (se puede ejecutar cuantas veces quieras).
const database = db.getSiblingDB("Agrimarket");

database.carts.deleteMany({ _id: { $in: ["demo-cart-001", "demo-cart-002"] } });
database.order_events.deleteMany({ orderId: { $in: [NumberInt(9001), NumberInt(9002), NumberInt(9003)] } });
database.customers.updateOne({ _id: NumberLong(1) }, { $set: { totalVisits: NumberInt(0) }, $unset: { lastPurchaseDate: "" } });
database.products.updateOne({ _id: NumberLong(2) }, { $set: { basePrice: NumberDecimal("95.00") } });
database.products.updateOne({ _id: NumberLong(1) }, { $set: { description: "Fungicida preventivo y curativo" } });
database.product_price_history.deleteMany({ reason: "DEMO-TX" });

print("Datos de demostración restablecidos.");
