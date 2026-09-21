// ================================================================
// AgriMarket - MongoDB
// V001 - Baseline
// ================================================================

const dbAgriMarket = db.getSiblingDB("agrimarket");

dbAgriMarket.createCollection("suppliers");

dbAgriMarket.suppliers.createIndex(
    { supplierCode: 1 },
    { unique: true, name: "uk_suppliers_supplierCode" }
);

dbAgriMarket.suppliers.createIndex(
    { docNumber: 1 },
    { name: "ix_suppliers_docNumber" }
);

dbAgriMarket.suppliers.createIndex(
    { isActive: 1 },
    { name: "ix_suppliers_isActive" }
);

print("AgriMarket MongoDB V001 baseline ejecutado correctamente.");