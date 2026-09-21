const dbAgriMarket = db.getSiblingDB("agrimarket");

dbAgriMarket.suppliers.createIndex(
    { businessName: 1 },
    { name: "ix_suppliers_businessName" }
);

print("AgriMarket MongoDB V002 ejecutado correctamente.");