const database = db.getSiblingDB("Agrimarket");
database.getCollection("customer_wishlists").drop();
print("AgriMarket MongoDB V004 revertido (colección customer_wishlists eliminada).");
