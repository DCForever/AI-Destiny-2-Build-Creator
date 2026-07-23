import Database from "better-sqlite3";
import fs from "fs";
import path from "path";

const db = new Database(".cache/app.db", { readonly: true });

// Find Aisha's Embrace hash from entity cache if present
const entitiesDir = ".cache/entities";
let aishaHashes = [];
if (fs.existsSync(entitiesDir)) {
  const versions = fs.readdirSync(entitiesDir);
  for (const v of versions) {
    const weaponsPath = path.join(entitiesDir, v, "weapons.json");
    const exoticPath = path.join(entitiesDir, v, "exotic-weapons.json");
    for (const p of [weaponsPath, exoticPath]) {
      if (!fs.existsSync(p)) continue;
      try {
        const data = JSON.parse(fs.readFileSync(p, "utf8"));
        for (const w of data) {
          if (/aisha/i.test(w.name || "")) {
            aishaHashes.push({ hash: w.hash, name: w.name, file: p });
          }
        }
      } catch {
        /* skip */
      }
    }
  }
}
console.log("aisha hashes from entities", aishaHashes);

// Also scan inventory for power 400 energy vault (user screenshot)
const candidates = db
  .prepare(
    `SELECT instance_id, item_hash, bucket, location, power, socket_plugs, plug_hashes, synced_at
     FROM inventory_items
     WHERE bucket = 'Energy' AND power = 400`,
  )
  .all();
console.log("energy power 400 count", candidates.length);

function summarize(row) {
  const sp = row.socket_plugs ? JSON.parse(row.socket_plugs) : null;
  return {
    instance_id: row.instance_id,
    item_hash: row.item_hash,
    location: row.location,
    power: row.power,
    synced_at: row.synced_at,
    socketPlugsNull: row.socket_plugs == null,
    columns: sp?.map((s) => ({
      idx: s.socketIndex,
      kind: s.columnKind,
      label: s.columnLabel,
      equipped: s.equippedPlugHash,
      reusableCount: s.reusablePlugHashes?.length ?? 0,
      reusables: s.reusablePlugHashes,
    })),
  };
}

if (aishaHashes.length) {
  const hashes = aishaHashes.map((h) => h.hash);
  const placeholders = hashes.map(() => "?").join(",");
  const rows = db
    .prepare(
      `SELECT * FROM inventory_items WHERE item_hash IN (${placeholders})`,
    )
    .all(...hashes);
  console.log("aisha inventory rows", rows.map(summarize));
}

// Pick first energy 400 with multi if any
for (const row of candidates.slice(0, 5)) {
  console.log("candidate", summarize(row));
}

// Simulate resolveInstancePerkGrid status
const multi = candidates.find((r) => {
  if (!r.socket_plugs) return false;
  const sp = JSON.parse(r.socket_plugs);
  return sp.some((s) => (s.reusablePlugHashes || []).length > 1);
});
if (multi) {
  console.log("first multi energy 400", summarize(multi));
} else {
  console.log("no multi among energy power 400");
  // any aisha-like name via hash  - search all energy with multi and power around 400
  const any = db
    .prepare(
      `SELECT instance_id, item_hash, power, location, socket_plugs FROM inventory_items WHERE bucket='Energy'`,
    )
    .all()
    .map((r) => {
      const sp = r.socket_plugs ? JSON.parse(r.socket_plugs) : [];
      const max = Math.max(0, ...sp.map((s) => (s.reusablePlugHashes || []).length));
      return { ...r, max, cols: sp.length };
    })
    .filter((r) => r.max > 1 && r.power >= 390 && r.power <= 410)
    .slice(0, 5);
  console.log("energy multi near 400", any.map((r) => ({ id: r.instance_id, hash: r.item_hash, power: r.power, max: r.max, cols: r.cols })));
}
