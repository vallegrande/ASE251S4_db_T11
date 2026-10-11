const database = db.getSiblingDB("Agrimarket");
database.getCollection("product_price_history").drop();
print("AgriMarket MongoDB V007 revertido (colección product_price_history eliminada).");
