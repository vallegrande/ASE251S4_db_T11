// ================================================================
// AgriMarket - MongoDB
// V001 - Baseline
//
// Estado inicial de la base "Agrimarket": las 10 colecciones que usa
// el backend Spring WebFlux (modelo com.agrimarket.demo.model.mongo),
// sus índices y datos semilla para poder probar sin cargar nada a mano.
//
// IMPORTANTE: los índices de customers, staff_users y auth_sessions
// llevan el MISMO nombre que genera Spring Data (auto-index-creation),
// para que el backend no falle al arrancar por conflicto de índices.
// ================================================================

const database = db.getSiblingDB("Agrimarket");

function ensureCollection(name, validator) {
    if (database.getCollectionInfos({ name: name }).length === 0) {
        const options = {};
        if (validator) {
            options.validator = { $jsonSchema: validator };
            options.validationLevel = "strict";
            options.validationAction = "error";
        }
        database.createCollection(name, options);
    }
}

function seed(collectionName, document) {
    const collection = database.getCollection(collectionName);
    if (collection.countDocuments({ _id: document._id }) === 0) {
        collection.insertOne(document);
    }
}

// ---------------- Colecciones maestras ----------------

ensureCollection("customers", {
    bsonType: "object",
    required: ["_id", "docType", "docNumber", "firstName", "lastName", "email", "customerSince"],
    properties: {
        _id: { bsonType: ["long", "int"] },
        docType: { bsonType: "string", maxLength: 20 },
        docNumber: { bsonType: "string", maxLength: 20 },
        firstName: { bsonType: "string", maxLength: 100 },
        lastName: { bsonType: "string", maxLength: 100 },
        email: { bsonType: "string", maxLength: 255 }
    }
});

ensureCollection("products", {
    bsonType: "object",
    required: ["_id", "name", "basePrice", "categoryId", "brandId"],
    properties: {
        _id: { bsonType: ["long", "int"] },
        name: { bsonType: "string", maxLength: 200 },
        categoryId: { bsonType: "string" },
        brandId: { bsonType: "string" }
    }
});

ensureCollection("suppliers", {
    bsonType: "object",
    required: ["_id", "businessName"],
    properties: {
        _id: { bsonType: ["long", "int"] },
        businessName: { bsonType: "string", maxLength: 150 }
    }
});

ensureCollection("brands", {
    bsonType: "object",
    required: ["_id", "brandName"],
    properties: { _id: { bsonType: ["long", "int"] }, brandName: { bsonType: "string", maxLength: 150 } }
});

ensureCollection("categories", {
    bsonType: "object",
    required: ["_id", "categoryName", "level", "code"],
    properties: {
        _id: { bsonType: ["long", "int"] },
        categoryName: { bsonType: "string", maxLength: 150 },
        code: { bsonType: "string", maxLength: 20 }
    }
});

// ---------------- Colecciones de apoyo ----------------

ensureCollection("ubigeos");        // la carga el backend (UbigeoSeeder) al arrancar
ensureCollection("carts");
ensureCollection("staff_users");
ensureCollection("auth_sessions");
ensureCollection("counters");

// ---------------- Índices ----------------

database.customers.createIndex({ docType: 1, docNumber: 1 }, { name: "ux_customer_document", unique: true });
database.customers.createIndex({ email: 1 }, { name: "email", unique: true });

database.staff_users.createIndex({ email: 1 }, { name: "email", unique: true });

database.auth_sessions.createIndex({ tokenHash: 1 }, { name: "tokenHash", unique: true });
database.auth_sessions.createIndex({ expiresAt: 1 }, { name: "expiresAt", expireAfterSeconds: 0 });

database.products.createIndex({ categoryId: 1 }, { name: "ix_products_categoryId" });
database.products.createIndex({ brandId: 1 }, { name: "ix_products_brandId" });
database.products.createIndex({ sku: 1 }, { name: "ix_products_sku" });

database.carts.createIndex({ customerId: 1 }, { name: "ix_carts_customerId" });

database.suppliers.createIndex({ docNumber: 1 }, { name: "ix_suppliers_docNumber" });
database.suppliers.createIndex({ isActive: 1 }, { name: "ix_suppliers_isActive" });

// ---------------- Datos semilla (ids Long, como los genera el backend) ----------------

const now = new Date();

seed("brands", { _id: NumberLong(1), brandName: "AgroNova", isActive: true, createdAt: now, updatedAt: now });
seed("brands", { _id: NumberLong(2), brandName: "CampoVerde", isActive: true, createdAt: now, updatedAt: now });

seed("categories", { _id: NumberLong(1), categoryName: "Fungicidas", description: "Control de hongos en cultivos", level: 1, code: "FUN", orderDisplay: 1, isActive: true, createdAt: now, updatedAt: now });
seed("categories", { _id: NumberLong(2), categoryName: "Fertilizantes", description: "Nutrición del suelo y del cultivo", level: 1, code: "FER", orderDisplay: 2, isActive: true, createdAt: now, updatedAt: now });

seed("suppliers", { _id: NumberLong(1), businessName: "Distribuidora Agro Cañete S.A.C.", docType: "RUC", docNumber: "20512345678", phone: "014445566", email: "ventas@agrocanete.example.com", address: "Av. Mariscal Benavides 120, San Vicente de Cañete", contactPerson: "Marco Salas", isActive: true, createdAt: now, updatedAt: now });
seed("suppliers", { _id: NumberLong(2), businessName: "Insumos del Valle E.I.R.L.", docType: "RUC", docNumber: "20598765432", phone: "014447788", email: "contacto@insumosvalle.example.com", address: "Jr. Bolognesi 455, Imperial", contactPerson: "Rosa Paredes", isActive: true, createdAt: now, updatedAt: now });

seed("products", { _id: NumberLong(1), name: "Fungicida Cobre 50 WP", activeIngredient: "Oxicloruro de cobre", presentation: "Bolsa 1 kg", basePrice: NumberDecimal("18.50"), sku: "FUN-001", categoryId: "1", brandId: "1", description: "Fungicida preventivo y curativo", isActive: true, createdAt: now, updatedAt: now });
seed("products", { _id: NumberLong(2), name: "Fertilizante NPK 20-20-20", activeIngredient: "Nitrógeno, fósforo y potasio", presentation: "Saco 25 kg", basePrice: NumberDecimal("95.00"), sku: "FER-001", categoryId: "2", brandId: "2", description: "Fertilizante balanceado", isActive: true, createdAt: now, updatedAt: now });
seed("products", { _id: NumberLong(3), name: "Fertilizante Urea 46%", activeIngredient: "Urea", presentation: "Saco 50 kg", basePrice: NumberDecimal("120.00"), sku: "FER-002", categoryId: "2", brandId: "1", description: "Fuente de nitrógeno", isActive: true, createdAt: now, updatedAt: now });

seed("customers", { _id: NumberLong(1), docType: "DNI", docNumber: "70000001", firstName: "Ana", lastName: "Quispe", email: "ana.quispe@example.com", phone: "999000001", address: "Imperial, Cañete", totalVisits: 0, customerSince: new Date("2026-01-15"), isActive: true, createdAt: now, updatedAt: now });
seed("customers", { _id: NumberLong(2), docType: "DNI", docNumber: "70000002", firstName: "Luis", lastName: "Huamán", email: "luis.huaman@example.com", phone: "999000002", address: "Nuevo Imperial, Cañete", totalVisits: 0, customerSince: new Date("2026-02-20"), isActive: true, createdAt: now, updatedAt: now });

// El backend genera ids con counters.<nombre>_sequence (inc +1).
// Los dejamos en el último id sembrado para que el siguiente no choque.
function seedCounter(id, value) {
    if (database.counters.countDocuments({ _id: id }) === 0) {
        database.counters.insertOne({ _id: id, seq: NumberLong(value) });
    }
}
seedCounter("brands_sequence", 2);
seedCounter("categories_sequence", 2);
seedCounter("suppliers_sequence", 2);
seedCounter("products_sequence", 3);
seedCounter("customers_sequence", 2);

print("AgriMarket MongoDB V001 baseline ejecutado correctamente.");
