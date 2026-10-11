const database = db.getSiblingDB("Agrimarket");
database.getCollection("order_events").drop();
print("AgriMarket MongoDB V005 revertido (colección order_events eliminada).");
