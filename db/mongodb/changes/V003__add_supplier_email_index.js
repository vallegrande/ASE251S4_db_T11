// V003 - Índice por email en proveedores
const dbAgriMarket = db.getSiblingDB("Agrimarket");

dbAgriMarket.suppliers.createIndex(
    { email: 1 },
    { name: "ix_suppliers_email" }
);

print("AgriMarket MongoDB V003 ejecutado correctamente.");
