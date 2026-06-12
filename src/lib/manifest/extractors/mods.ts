import type { ModRecord, ModSlotCategory } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { iterItems, projectBase } from "./common";

const ITEM_TYPE_MOD = 19;
const MOD_CAT_PREFIX = "enhancements.";

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isModItem(item: RawInventoryItem): boolean {
  return (
    item.itemType === ITEM_TYPE_MOD &&
    (item.plug?.plugCategoryIdentifier ?? "").startsWith(MOD_CAT_PREFIX)
  );
}

function toModSlotCategory(cat: string): ModSlotCategory | null {
  if (/enhancements\.(v2_)?head/.test(cat)) return "helmet";
  if (/enhancements\.(v2_)?arms/.test(cat)) return "arms";
  if (/enhancements\.(v2_)?chest/.test(cat)) return "chest";
  if (/enhancements\.(v2_)?legs/.test(cat)) return "legs";
  if (/enhancements\.(v2_)?class/.test(cat)) return "classItem";
  if (/tuning/.test(cat)) return "tuning";
  if (/enhancements\.general/.test(cat) || /enhancements\.universal/.test(cat)) return "general";
  return null;
}

function resolveEnergyCost(item: RawInventoryItem): number | null {
  const cost = item.plug?.energyCost?.energyCost;
  return typeof cost === "number" ? cost : null;
}

async function extractMods(loadTable: LoadTable): Promise<ModRecord[]> {
  const itemTable = await loadTable("DestinyInventoryItemDefinition");
  const result: ModRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isModItem(item)) continue;

    const cat = item.plug?.plugCategoryIdentifier ?? "";
    const slotCategory = toModSlotCategory(cat);
    if (!slotCategory) continue;

    result.push({
      ...projectBase(item),
      description: item.displayProperties.description,
      slotCategory,
      energyCost: resolveEnergyCost(item),
    });
  }

  return result;
}

export const modsExtractor: Extractor<"mods"> = {
  store: "mods",
  extract: (loadTable) => extractMods(loadTable),
};
