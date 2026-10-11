const database = db.getSiblingDB("Agrimarket");
if (database.suppliers.getIndexes().some(function (i) { return i.name === "ix_suppliers_businessName"; })) {
    database.suppliers.dropIndex("ix_suppliers_businessName");
}
print("AgriMarket MongoDB V002 revertido.");
