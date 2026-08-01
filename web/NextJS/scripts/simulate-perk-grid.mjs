import Database from "better-sqlite3";

const db = new Database(".cache/app.db", { readonly: true });
const row = db
  .prepare(
    `SELECT * FROM inventory_items WHERE item_hash = 3709368142 OR instance_id = '6917530149510693442'`,
  )
  .get();

if (!row) {
  console.log("row not found");
  process.exit(1);
}

const socketPlugs = JSON.parse(row.socket_plugs);
console.log(
  JSON.stringify(
    {
      instance: row.instance_id,
      hash: row.item_hash,
      power: row.power,
      location: row.location,
      synced: row.synced_at,
      captureStatus:
        socketPlugs == null
          ? "pending"
          : socketPlugs.length === 0
            ? "unavailable"
            : "complete",
      columns: socketPlugs.map((s) => ({
        label: s.columnLabel,
        kind: s.columnKind,
        optionCount: new Set([
          s.equippedPlugHash,
          ...(s.reusablePlugHashes || []),
        ]).size,
        hashes: [...new Set([s.equippedPlugHash, ...(s.reusablePlugHashes || [])])],
      })),
    },
    null,
    2,
  ),
);

// Also check if catalog might use other hash
const other = db
  .prepare(
    `SELECT item_hash, instance_id, power, location,
      length(socket_plugs) as sp
     FROM inventory_items WHERE item_hash IN (2638190703, 3245493570, 3709368142)`,
  )
  .all();
console.log("all aisha hashes in inventory", other);
