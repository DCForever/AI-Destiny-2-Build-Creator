import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import * as schema from "../src/lib/db/schema";
import { listInventoryItems } from "../src/lib/db/repositories/inventoryRepository";
import { collectEquipmentPlugHashes } from "../src/lib/inventory/instances/collectPlugHashes";
import { buildPlugMapForInventory } from "../src/lib/inventory/instances/loadInstanceContext";
import { resolveInstancePerkGrid } from "../src/lib/inventory/instances/resolveInstancePerkGrid";
import { loadWeaponSocketContext } from "../src/lib/inventory/instances/weaponSocketContext";
import { presentByHashes } from "../src/lib/catalog/entityPresentation";
import { getServices } from "../src/lib/services";

function ms(start: bigint) {
  return Number(process.hrtime.bigint() - start) / 1e6;
}

const sqlite = new Database(".cache/app.db", { readonly: true });
const db = drizzle(sqlite, { schema });
const items = listInventoryItems(db as never, 1);
const weapon = items.find((i) => i.instanceId === "6917530149510693442");
if (!weapon) {
  console.error("missing sample weapon");
  process.exit(1);
}

// Simulate scoped instances list (one catalog item / same search name)
const sameHash = items.filter((i) => i.itemHash === weapon.itemHash);
const scopedPlugs = collectEquipmentPlugHashes(sameHash);
const allPlugs = collectEquipmentPlugHashes(items);

const { entityCache, manifest } = await getServices();
const version = (await manifest.getStatus()).cachedVersion!;

// Cold full (legacy path cost still measurable once tables load)
let t = process.hrtime.bigint();
await buildPlugMapForInventory(entityCache, manifest, version, allPlugs);
const fullColdMs = ms(t);

// Warm full
t = process.hrtime.bigint();
await buildPlugMapForInventory(entityCache, manifest, version, allPlugs);
const fullWarmMs = ms(t);

// Scoped single-item (catalog detail path after fix)
t = process.hrtime.bigint();
const oneMap = await buildPlugMapForInventory(
  entityCache,
  manifest,
  version,
  scopedPlugs,
);
const scopedWarmMs = ms(t);

// Second scoped
t = process.hrtime.bigint();
await buildPlugMapForInventory(entityCache, manifest, version, scopedPlugs);
const scopedWarm2Ms = ms(t);

// Perk-grid path warm
t = process.hrtime.bigint();
const plugCtx = await loadWeaponSocketContext(
  manifest,
  version,
  weapon.itemHash,
  scopedPlugs,
);
const grid = resolveInstancePerkGrid({
  item: weapon,
  plugMap: oneMap,
  plugCategoryByHash: plugCtx.plugCategoryByHash,
  plugItemTypeByHash: plugCtx.plugItemTypeByHash,
  weaponPerkSocketIndexes: plugCtx.weaponPerkSocketIndexes,
});
const gridWarmMs = ms(t);

const sample = scopedPlugs.slice(0, 50);
t = process.hrtime.bigint();
const p1 = await presentByHashes(sample);
const presentMs = ms(t);
t = process.hrtime.bigint();
const p2 = await presentByHashes(sample);
const presentWarmMs = ms(t);

console.log(
  JSON.stringify(
    {
      allPlugs: allPlugs.length,
      scopedPlugs: scopedPlugs.length,
      fullColdMs: Math.round(fullColdMs),
      fullWarmMs: Math.round(fullWarmMs),
      scopedWarmMs: Math.round(scopedWarmMs),
      scopedWarm2Ms: Math.round(scopedWarm2Ms),
      gridWarmMs: Math.round(gridWarmMs),
      gridCapture: grid.captureStatus,
      gridOptions: grid.columns.reduce((n, c) => n + c.options.length, 0),
      multiCols: grid.columns.filter((c) => c.options.length > 1).length,
      presentMs: Math.round(presentMs),
      presentWarmMs: Math.round(presentWarmMs),
      presentResolved: [...p1.values()].filter((x) => x.hash != null).length,
      present2Resolved: [...p2.values()].filter((x) => x.hash != null).length,
      sampleIcon: p1.get(sample[0]!)?.icon != null || oneMap.get(sample[0]! )?.icon != null,
    },
    null,
    2,
  ),
);
