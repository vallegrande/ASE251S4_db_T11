// ================================================================
// BLOQUEOS (locks) MIENTRAS UNA TRANSACCIÓN ESTÁ ABIERTA
//
// La sesión A abre una transacción y modifica el producto 1 SIN hacer commit.
//   - Otra conexión que LEE no ve el cambio (aislamiento).
//   - Otra TRANSACCIÓN que intenta modificar ese mismo documento falla de inmediato (WriteConflict).
//   - Una escritura FUERA de transacción sobre ese documento ESPERA hasta que A termine.
// Después de que A hace commit/abort, el documento queda libre.
// ================================================================
const database = db.getSiblingDB("Agrimarket");
if (!db.hello().setName) {
    throw new Error("Este MongoDB NO es un replica set: no soporta transacciones. Usa compose.liquibase.yaml.");
}

const ID = NumberLong(1);
const ORIGINAL = "Fungicida preventivo y curativo";
database.products.updateOne({ _id: ID }, { $set: { description: ORIGINAL } });

const sessionA = db.getMongo().startSession();
const sessionB = db.getMongo().startSession();
const dbA = sessionA.getDatabase("Agrimarket");
const dbB = sessionB.getDatabase("Agrimarket");

try {
    print("\n--- 1) La sesión A abre una transacción y modifica el producto 1 (sin commit) ---");
    sessionA.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    dbA.products.updateOne({ _id: ID }, { $set: { description: "Cambio de A (sin commit)" } });
    print("    A cambió la descripción dentro de su transacción");

    print("\n--- 2) Una lectura normal NO ve el cambio de A (aislamiento) ---");
    print("    descripción vista desde fuera: " + database.products.findOne({ _id: ID }).description);

    print("\n--- 3) La sesión B (otra transacción) intenta modificar el MISMO documento ---");
    sessionB.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    try {
        dbB.products.updateOne({ _id: ID }, { $set: { description: "Cambio de B" } });
        print("    (B no tuvo conflicto)");
    } catch (e) {
        print("    B falló de inmediato -> " + e.codeName + " (código " + e.code + ")");
        print("    Es un error transitorio: la aplicación debe reintentar la transacción cuando A termine.");
    }
    try { sessionB.abortTransaction(); } catch (_) { }

    print("\n--- 4) Una escritura FUERA de transacción sobre ese documento espera a que A termine ---");
    const t0 = Date.now();
    try {
        database.runCommand({
            update: "products",
            updates: [{ q: { _id: ID }, u: { $set: { description: "Cambio fuera de transacción" } } }],
            maxTimeMS: 3000
        });
        print("    la escritura terminó en " + (Date.now() - t0) + " ms");
    } catch (e) {
        print("    la escritura esperó " + (Date.now() - t0) + " ms y se canceló por tiempo (" + e.codeName + "): el documento seguía bloqueado por A");
    }

    print("\n--- 5) A hace commit: el documento se libera ---");
    sessionA.commitTransaction();
    print("    descripción ahora: " + database.products.findOne({ _id: ID }).description);

    print("\n--- 6) B reintenta su transacción y esta vez funciona ---");
    sessionB.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    dbB.products.updateOne({ _id: ID }, { $set: { description: "Cambio de B (reintento)" } });
    sessionB.commitTransaction();
    print("    descripción final: " + database.products.findOne({ _id: ID }).description);
} catch (e) {
    print("ERROR inesperado: " + e.message);
    try { sessionA.abortTransaction(); } catch (_) { }
    try { sessionB.abortTransaction(); } catch (_) { }
} finally {
    sessionA.endSession();
    sessionB.endSession();
    database.products.updateOne({ _id: ID }, { $set: { description: ORIGINAL } });   // deja el dato como estaba
}
