const database = db.getSiblingDB("Agrimarket");
if (database.suppliers.getIndexes().some(function (i) { return i.name === "ix_suppliers_email"; })) {
    database.suppliers.dropIndex("ix_suppliers_email");
}
print("AgriMarket MongoDB V003 revertido.");
