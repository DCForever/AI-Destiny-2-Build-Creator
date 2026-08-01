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
  console.error("missing sample weapon instance");
  process.exit(1);
}
const allPlugHashes = collectEquipmentPlugHashes(items);
const oneItemPlugs = [
  ...weapon.plugHashes,
  ...(weapon.socketPlugs?.flatMap((s) => [
    s.equippedPlugHash,
    ...s.reusablePlugHashes,
  ]) ?? []),
];
console.log({
  inventoryItems: items.length,
  allPlugHashes: allPlugHashes.length,
  oneItemPlugs: oneItemPlugs.length,
});

const { entityCache, manifest } = await getServices();
const version = (await manifest.getStatus()).cachedVersion!;

let t = process.hrtime.bigint();
const fullMap = await buildPlugMapForInventory(
  entityCache,
  manifest,
  version,
  allPlugHashes,
);
const fullMapMs = ms(t);

t = process.hrtime.bigint();
const oneMap = await buildPlugMapForInventory(
  entityCache,
  manifest,
  version,
  oneItemPlugs,
);
const oneMapMs = ms(t);

t = process.hrtime.bigint();
const fullMap2 = await buildPlugMapForInventory(
  entityCache,
  manifest,
  version,
  allPlugHashes,
);
const fullMapWarmMs = ms(t);

t = process.hrtime.bigint();
const plugCtx = await loadWeaponSocketContext(
  manifest,
  version,
  weapon.itemHash,
  oneItemPlugs,
);
const grid = resolveInstancePerkGrid({
  item: weapon,
  plugMap: oneMap,
  plugCategoryByHash: plugCtx.plugCategoryByHash,
  plugItemTypeByHash: plugCtx.plugItemTypeByHash,
  weaponPerkSocketIndexes: plugCtx.weaponPerkSocketIndexes,
});
const gridMs = ms(t);

const sampleHashes = oneItemPlugs.slice(0, 50);
t = process.hrtime.bigint();
const present1 = await presentByHashes(sampleHashes);
const presentMs = ms(t);
t = process.hrtime.bigint();
const present2 = await presentByHashes(sampleHashes);
const presentWarmMs = ms(t);

const out = {
  fullMapMs: Math.round(fullMapMs),
  fullMapSize: fullMap.size,
  fullMapWarmMs: Math.round(fullMapWarmMs),
  fullMap2Size: fullMap2.size,
  oneMapMs: Math.round(oneMapMs),
  oneMapSize: oneMap.size,
  gridMs: Math.round(gridMs),
  gridCapture: grid.captureStatus,
  gridOptions: grid.columns.reduce((n, c) => n + c.options.length, 0),
  presentMs: Math.round(presentMs),
  presentWarmMs: Math.round(presentWarmMs),
  presentResolved: [...present1.values()].filter((p) => p.hash != null).length,
  present2Resolved: [...present2.values()].filter((p) => p.hash != null).length,
};
console.log(JSON.stringify(out, null, 2));
