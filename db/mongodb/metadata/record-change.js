// Registra un cambio aplicado en la colección schema_changes.
// Recibe CHANGE_SEQUENCE, CHANGE_ID y CHANGE_CHECKSUM por variables de entorno (las define run.sh).
const database = db.getSiblingDB(process.env.MONGO_DATABASE);

if (database.getCollectionInfos({ name: "schema_changes" }).length === 0) {
    database.createCollection("schema_changes");
    database.schema_changes.createIndex({ sequence: 1 }, { unique: true, name: "uq_schema_change_sequence" });
}

database.schema_changes.insertOne({
    sequence: NumberInt(Number(process.env.CHANGE_SEQUENCE)),
    changeId: process.env.CHANGE_ID,
    checksum: process.env.CHANGE_CHECKSUM,
    gitSha: process.env.GIT_SHA,
    releaseVersion: process.env.RELEASE_VERSION,
    appliedAt: new Date()
});
