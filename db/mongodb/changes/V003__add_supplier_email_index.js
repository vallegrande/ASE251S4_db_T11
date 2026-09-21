const dbAgriMarket = db.getSiblingDB("agrimarket");

dbAgriMarket.suppliers.createIndex(
    { email: 1 },
    { name: "ix_suppliers_email" }
);

print("AgriMarket MongoDB V003 ejecutado correctamente.");