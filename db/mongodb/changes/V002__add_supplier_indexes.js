// V002 - Índice por razón social en proveedores
const dbAgriMarket = db.getSiblingDB("Agrimarket");

dbAgriMarket.suppliers.createIndex(
    { businessName: 1 },
    { name: "ix_suppliers_businessName" }
);

print("AgriMarket MongoDB V002 ejecutado correctamente.");
