import { SQLiteDatabaseClient } from "@abaplint/database-sqlite";

// Called by the transpiled output/init.mjs. The in-memory database carries the
// REPOSRC rows the open-abap-gui framework scans to discover transactions.
export async function setupDatabase(abap, schemas, insert) {
  database = new SQLiteDatabaseClient();
  abap.context.databaseConnections.DEFAULT = database;
  await database.connect();
  await database.execute(schemas.sqlite);
  await database.execute(insert);
}

export let database;
