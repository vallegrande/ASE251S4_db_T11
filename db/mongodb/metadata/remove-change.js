// Elimina del historial la versión revertida (la usa run.sh en el rollback).
const database = db.getSiblingDB(process.env.MONGO_DATABASE);
database.schema_changes.deleteOne({ sequence: NumberInt(Number(process.env.CHANGE_SEQUENCE)) });
