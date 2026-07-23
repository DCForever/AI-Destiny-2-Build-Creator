import Database from "better-sqlite3";

const db = new Database(".cache/app.db", { readonly: true });

const meta = db.prepare("SELECT * FROM inventory_sync_meta").all();
console.log("meta", meta);

const counts = db
  .prepare(
    `SELECT
      COUNT(*) as total,
      SUM(CASE WHEN socket_plugs IS NULL THEN 1 ELSE 0 END) as null_sp,
      SUM(CASE WHEN socket_plugs IS NOT NULL THEN 1 ELSE 0 END) as with_sp,
      SUM(CASE WHEN bucket IN ('Kinetic','Energy','Power') THEN 1 ELSE 0 END) as weapons
    FROM inventory_items`,
  )
  .get();
console.log("counts", counts);

const weapons = db
  .prepare(
    `SELECT bucket, location,
      SUM(CASE WHEN socket_plugs IS NULL THEN 1 ELSE 0 END) as null_sp,
      SUM(CASE WHEN socket_plugs IS NOT NULL THEN 1 ELSE 0 END) as with_sp,
      COUNT(*) as n
    FROM inventory_items
    WHERE bucket IN ('Kinetic','Energy','Power')
    GROUP BY bucket, location`,
  )
  .all();
console.log("weapons by bucket/loc", weapons);

const samples = db
  .prepare(
    `SELECT instance_id, item_hash, bucket, location,
      CASE WHEN socket_plugs IS NULL THEN 'NULL' ELSE 'SET' END as sp,
      length(socket_plugs) as sp_len,
      substr(COALESCE(socket_plugs,''),1,280) as sp_head
    FROM inventory_items
    WHERE bucket IN ('Kinetic','Energy','Power')
    ORDER BY synced_at DESC
    LIMIT 15`,
  )
  .all();
console.log("samples", JSON.stringify(samples, null, 2));

const allWeapons = db
  .prepare(
    `SELECT instance_id, item_hash, location, bucket, socket_plugs, plug_hashes
     FROM inventory_items
     WHERE bucket IN ('Kinetic','Energy','Power')`,
  )
  .all();

let multiCol = 0;
let singleOnly = 0;
let empty = 0;
let nullSp = 0;
const multiExamples = [];
for (const r of allWeapons) {
  if (r.socket_plugs == null) {
    nullSp++;
    continue;
  }
  let sp;
  try {
    sp = JSON.parse(r.socket_plugs);
  } catch {
    continue;
  }
  if (!Array.isArray(sp) || sp.length === 0) {
    empty++;
    continue;
  }
  const max = Math.max(0, ...sp.map((s) => (s.reusablePlugHashes || []).length));
  if (max > 1) {
    multiCol++;
    multiExamples.push({
      id: r.instance_id,
      hash: r.item_hash,
      loc: r.location,
      bucket: r.bucket,
      maxReusable: max,
      cols: sp.length,
      sample: sp.slice(0, 3).map((s) => ({
        kind: s.columnKind,
        label: s.columnLabel,
        equipped: s.equippedPlugHash,
        reusables: s.reusablePlugHashes?.length,
      })),
    });
  } else {
    singleOnly++;
  }
}

console.log({
  weapons: allWeapons.length,
  nullSp,
  empty,
  multiCol,
  singleOnly,
  multiExamples: multiExamples.slice(0, 8),
});

// Look for Aisha - item hash search via plug or name not available; dump energy vault with power-ish
const energyVault = db
  .prepare(
    `SELECT instance_id, item_hash, power, socket_plugs IS NULL as null_sp, length(socket_plugs) as sp_len
     FROM inventory_items
     WHERE bucket = 'Energy' AND location = 'vault'
     ORDER BY power DESC LIMIT 20`,
  )
  .all();
console.log("energy vault top", energyVault);
