import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import * as schema from "../src/lib/db/schema";
import { listInventoryItems } from "../src/lib/db/repositories/inventoryRepository";
import { resolveInstancePerkGrid } from "../src/lib/inventory/instances/resolveInstancePerkGrid";
import { buildPlugMapForInventory } from "../src/lib/inventory/instances/loadInstanceContext";
import { loadWeaponSocketContext } from "../src/lib/inventory/instances/weaponSocketContext";
import { getServices } from "../src/lib/services";

const sqlite = new Database(".cache/app.db", { readonly: true });
const db = drizzle(sqlite, { schema });
const item = listInventoryItems(db as never, 1).find(
  (i) => i.instanceId === "6917530149510693442",
)!;
const { entityCache, manifest } = await getServices();
const version = (await manifest.getStatus()).cachedVersion ?? "0";
const plugHashes = [
  ...item.plugHashes,
  ...item.socketPlugs!.flatMap((s) => [
    s.equippedPlugHash,
    ...s.reusablePlugHashes,
  ]),
];
const [plugMap, plugCtx] = await Promise.all([
  buildPlugMapForInventory(entityCache, manifest, version, plugHashes),
  loadWeaponSocketContext(manifest, version, item.itemHash, plugHashes),
]);
const grid = resolveInstancePerkGrid({
  item,
  plugMap,
  plugCategoryByHash: plugCtx.plugCategoryByHash,
  plugItemTypeByHash: plugCtx.plugItemTypeByHash,
  weaponPerkSocketIndexes: plugCtx.weaponPerkSocketIndexes,
});
console.log(
  grid.columns.map((c) => ({
    label: c.label,
    kind: c.columnKind,
    n: c.options.length,
    names: c.options.map((o) => o.displayName),
  })),
);
console.log("capture", grid.captureStatus, "total options", grid.columns.reduce((a, c) => a + c.options.length, 0));
