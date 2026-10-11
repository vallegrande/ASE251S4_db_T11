// ================================================================
// V005 - REFERENCING (ejemplo 2 de Brando) - order_events
//
// Historial de estados de un pedido (transaccional order de SQL Server).
//   - Un pedido tiene una cantidad NO acotada de eventos (creado, confirmado,
//     listo para recoger, entregado, anulado...). Incrustarlos haría crecer
//     el documento y obligaría a reescribirlo en cada cambio de estado.
//   - Se guarda una referencia al pedido relacional y otra al cliente.
//
//   order_events.orderId    -> dbo.[order].order_id   (SQL Server; no hay FK entre motores)
//   order_events.customerId -> customers._id          (MongoDB)
// ================================================================

const database = db.getSiblingDB("Agrimarket");

if (database.getCollectionInfos({ name: "order_events" }).length === 0) {
    database.createCollection("order_events", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: ["orderId", "customerId", "eventType", "eventAt"],
                properties: {
                    orderId: { bsonType: ["int", "long"], description: "Referencia a dbo.[order].order_id (SQL Server)" },
                    customerId: { bsonType: ["long", "int"], description: "Referencia a customers._id" },
                    eventType: { enum: ["CREATED", "CONFIRMED", "READY_FOR_PICKUP", "COMPLETED", "CANCELLED"] },
                    eventAt: { bsonType: "date" },
                    note: { bsonType: "string", maxLength: 300 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

database.order_events.createIndex({ orderId: 1, eventAt: 1 }, { name: "ix_order_events_order_time" });
database.order_events.createIndex({ customerId: 1, eventAt: -1 }, { name: "ix_order_events_customer_time" });

[
    { orderId: 1, customerId: 1, eventType: "CREATED", note: "Pedido registrado desde el checkout" },
    { orderId: 1, customerId: 1, eventType: "CONFIRMED", note: "Stock validado" },
    { orderId: 2, customerId: 2, eventType: "CREATED", note: "Pedido registrado desde el checkout" }
].forEach(function (item) {
    const customerId = NumberLong(item.customerId);
    if (database.customers.countDocuments({ _id: customerId }) !== 1) {
        throw new Error("Referencia inválida: customers._id=" + customerId);
    }
    if (database.order_events.countDocuments({ orderId: NumberInt(item.orderId), eventType: item.eventType }) === 0) {
        database.order_events.insertOne({
            orderId: NumberInt(item.orderId),
            customerId: customerId,
            eventType: item.eventType,
            eventAt: new Date(),
            note: item.note
        });
    }
});

print("AgriMarket MongoDB V005 ejecutado correctamente.");
