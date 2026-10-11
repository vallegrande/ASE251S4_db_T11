const database = db.getSiblingDB("Agrimarket");
database.getCollection("supplier_products").drop();
print("AgriMarket MongoDB V006 revertido (colección supplier_products eliminada).");
