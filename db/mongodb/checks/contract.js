// ================================================================
// Contrato de la versión: comprueba que la base quedó exactamente como
// debe estar en TARGET_SCHEMA_VERSION (historial, colecciones, índices
// y referencias que apuntan a documentos que existen).
// ================================================================
const database = db.getSiblingDB(process.env.MONGO_DATABASE || "Agrimarket");
const target = Number(process.env.TARGET_SCHEMA_VERSION);

function fail(message) {
    throw new Error("CONTRATO NO CUMPLIDO: " + message);
}

if (!Number.isInteger(target) || target < 1) {
    fail("TARGET_SCHEMA_VERSION inválido");
}

// 1. Historial consecutivo 1..target
const changes = database.schema_changes.find().sort({ sequence: 1 }).toArray();
if (changes.length !== target) {
    fail("el historial tiene " + changes.length + " cambios y se esperaban " + target);
}
changes.forEach(function (change, index) {
    if (Number(change.sequence) !== index + 1) {
        fail("falta la versión " + (index + 1) + " en schema_changes");
    }
});

// 2. Colecciones que deben existir (o no) según la versión
const collectionsByVersion = {
    1: ["customers", "products", "suppliers", "brands", "categories", "ubigeos", "carts", "staff_users", "auth_sessions", "counters"],
    4: ["customer_wishlists"],
    5: ["order_events"],
    6: ["supplier_products"],
    7: ["product_price_history"]
};
const existing = database.getCollectionNames();
Object.keys(collectionsByVersion).forEach(function (version) {
    collectionsByVersion[version].forEach(function (name) {
        const shouldExist = Number(version) <= target;
        const exists = existing.indexOf(name) !== -1;
        if (shouldExist && !exists) { fail("falta la colección " + name + " (V" + version + ")"); }
        if (!shouldExist && exists) { fail("la colección " + name + " no debería existir en V" + target); }
    });
});

// 3. Índices que deben existir (o no) según la versión
const indexesByVersion = {
    2: [["suppliers", "ix_suppliers_businessName"]],
    3: [["suppliers", "ix_suppliers_email"]],
    4: [["customer_wishlists", "uq_wishlist_customer_product"]],
    5: [["order_events", "ix_order_events_order_time"]],
    6: [["supplier_products", "uq_supplier_products"]],
    7: [["product_price_history", "ix_price_history_product_time"]]
};
function hasIndex(collectionName, indexName) {
    if (existing.indexOf(collectionName) === -1) { return false; }
    return database.getCollection(collectionName).getIndexes().some(function (i) { return i.name === indexName; });
}
Object.keys(indexesByVersion).forEach(function (version) {
    indexesByVersion[version].forEach(function (pair) {
        const shouldExist = Number(version) <= target;
        const exists = hasIndex(pair[0], pair[1]);
        if (shouldExist && !exists) { fail("falta el índice " + pair[1] + " (V" + version + ")"); }
        if (!shouldExist && exists) { fail("el índice " + pair[1] + " no debería existir en V" + target); }
    });
});

// 4. Integridad referencial: cada referencia debe apuntar a un documento existente
function orphans(collectionName, field, targetCollection) {
    if (existing.indexOf(collectionName) === -1) { return 0; }
    const result = database.getCollection(collectionName).aggregate([
        { $lookup: { from: targetCollection, localField: field, foreignField: "_id", as: "ref" } },
        { $match: { ref: { $size: 0 } } },
        { $count: "n" }
    ]).toArray();
    return result.length ? Number(result[0].n) : 0;
}
[
    ["customer_wishlists", "customerId", "customers"],
    ["customer_wishlists", "productId", "products"],
    ["order_events", "customerId", "customers"],
    ["supplier_products", "supplierId", "suppliers"],
    ["supplier_products", "productId", "products"],
    ["product_price_history", "productId", "products"]
].forEach(function (rule) {
    const broken = orphans(rule[0], rule[1], rule[2]);
    if (broken > 0) {
        fail(broken + " documento(s) de " + rule[0] + "." + rule[1] + " apuntan a " + rule[2] + " inexistente");
    }
});

print("MongoDB: contrato V" + target + " verificado (historial, colecciones, índices y referencias).");
