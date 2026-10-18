const database = db.getSiblingDB("Agrimarket");
print("Colecciones en Agrimarket:");
database.getCollectionNames().sort().forEach(function (n) { print("  - " + n); });
