// Consultas de la demostración de REFERENCING: cada $lookup "sigue" la referencia
// de una colección hacia el documento al que apunta.
const database = db.getSiblingDB("Agrimarket");

print("\n=== 1) Favoritos del cliente 1 (customer_wishlists -> products)  [Brando, V004] ===");
database.customer_wishlists.aggregate([
    { $match: { customerId: NumberLong(1) } },
    { $lookup: { from: "products", localField: "productId", foreignField: "_id", as: "product" } },
    { $unwind: "$product" },
    { $project: { _id: 0, customerId: 1, productId: 1, producto: "$product.name", precioBase: "$product.basePrice", nota: "$note" } }
]).forEach(printjson);

print("\n=== 2) Historial del pedido 1 (order_events -> customers)  [Brando, V005] ===");
database.order_events.aggregate([
    { $match: { orderId: 1 } },
    { $sort: { eventAt: 1 } },
    { $lookup: { from: "customers", localField: "customerId", foreignField: "_id", as: "customer" } },
    { $unwind: "$customer" },
    { $project: { _id: 0, orderId: 1, evento: "$eventType", cliente: { $concat: ["$customer.firstName", " ", "$customer.lastName"] }, nota: "$note" } }
]).forEach(printjson);

print("\n=== 3) Proveedores del producto 3 (supplier_products -> suppliers)  [Giancarlos, V006] ===");
database.supplier_products.aggregate([
    { $match: { productId: NumberLong(3) } },
    { $lookup: { from: "suppliers", localField: "supplierId", foreignField: "_id", as: "supplier" } },
    { $unwind: "$supplier" },
    { $project: { _id: 0, proveedor: "$supplier.businessName", skuProveedor: "$supplierSku", costo: "$unitCost", diasEntrega: "$leadTimeDays" } },
    { $sort: { costo: 1 } }
]).forEach(printjson);

print("\n=== 4) Historial de precios del producto 2 (product_price_history -> products)  [Giancarlos, V007] ===");
database.product_price_history.aggregate([
    { $match: { productId: NumberLong(2) } },
    { $sort: { changedAt: 1 } },
    { $lookup: { from: "products", localField: "productId", foreignField: "_id", as: "product" } },
    { $unwind: "$product" },
    { $project: { _id: 0, producto: "$product.name", precioAnterior: "$oldPrice", precioNuevo: "$newPrice", fecha: "$changedAt", motivo: "$reason" } }
]).forEach(printjson);
