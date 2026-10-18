// Muestra la colección que Liquibase usa para recordar qué cambios ya aplicó.
// (Según la versión de la extensión, los campos pueden estar en minúsculas o en MAYÚSCULAS: se soportan ambos.)
const database = db.getSiblingDB("Agrimarket");
function campo(doc, nombre) {
    return doc[nombre] !== undefined ? doc[nombre] : doc[nombre.toUpperCase()];
}
if (database.getCollectionInfos({ name: "DATABASECHANGELOG" }).length === 0) {
    print("Todavía no existe DATABASECHANGELOG (Liquibase no ha aplicado nada).");
} else {
    print("DATABASECHANGELOG (cambios aplicados por Liquibase):");
    database.DATABASECHANGELOG.find().toArray()
        .sort(function (a, b) { return Number(campo(a, "orderExecuted")) - Number(campo(b, "orderExecuted")); })
        .forEach(function (c) {
            print("  #" + campo(c, "orderExecuted") + "  " + campo(c, "id") + "  (autor: " + campo(c, "author") + ")  md5=" + String(campo(c, "md5sum")).substring(0, 12));
        });
}
