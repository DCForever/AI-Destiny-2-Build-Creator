import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import * as schema from "../src/lib/db/schema.ts";
import { listInventoryItems } from "../src/lib/db/repositories/inventoryRepository.ts";
import { resolveInstancePerkGrid } from "../src/lib/inventory/instances/resolveInstancePerkGrid.ts";
import { buildPlugMapForInventory } from "../src/lib/inventory/instances/loadInstanceContext.ts";
import { loadWeaponSocketContext } from "../src/lib/inventory/instances/weaponSocketContext.ts";
import { getServices } from "../src/lib/services.ts";
import { weaponStatLines } from "../src/lib/inventory/instances/weaponStats.ts";

const sqlite = new Database(".cache/app.db", { readonly: true });
const db = drizzle(sqlite, { schema });
const items = listInventoryItems(db as never, 1);
const item = items.find((i) => i.instanceId === "6917530149510693442");
console.log("loaded", {
  found: !!item,
  socketPlugs: item?.socketPlugs?.length,
  barrel: item?.socketPlugs?.find((s) => s.columnKind === "barrel"),
  power: item?.power,
  stats: item?.statValues,
});
if (!item) process.exit(1);

const { entityCache, manifest } = await getServices();
const version = (await manifest.getStatus()).cachedVersion ?? "0";
const plugHashes = [
  ...item.plugHashes,
  ...(item.socketPlugs?.flatMap((s) => [
    s.equippedPlugHash,
    ...s.reusablePlugHashes,
  ]) ?? []),
];
const [plugMap, plugCtx] = await Promise.all([
  buildPlugMapForInventory(entityCache, manifest, version, plugHashes),
  loadWeaponSocketContext(manifest, version, item.itemHash, plugHashes),
]);
const grid = resolveInstancePerkGrid({
  item,
  plugMap,
  plugCategoryByHash: plugCtx.plugCategoryByHash,
  weaponPerkSocketIndexes: plugCtx.weaponPerkSocketIndexes,
});
console.log(
  JSON.stringify(
    {
      captureStatus: grid.captureStatus,
      stats: weaponStatLines(item.statValues),
      columns: grid.columns.map((c) => ({
        label: c.label,
        kind: c.columnKind,
        options: c.options.map((o) => ({
          name: o.displayName,
          equipped: o.isEquipped,
          hash: o.hash,
          hasIcon: Boolean(o.icon),
          descLen: (o.description || "").length,
        })),
      })),
    },
    null,
    2,
  ),
);
