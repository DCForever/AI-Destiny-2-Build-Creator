import type { ExoticArmorRecord, ArmorSlotName } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { asRawEquipmentSlot } from "./rawTypes";
import {
  iterItems,
  projectBase,
  toClassName,
  toArmorSlot,
  findSocketPlug,
} from "./common";

const ITEM_TYPE_ARMOR = 2;
const TIER_EXOTIC = 6;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isExoticArmor(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_ARMOR && item.inventory?.tierType === TIER_EXOTIC;
}

function buildSlotMap(slotTable: RawTable): Map<number, ArmorSlotName> {
  const map = new Map<number, ArmorSlotName>();
  for (const v of Object.values(slotTable)) {
    const slot = asRawEquipmentSlot(v);
    if (!slot) continue;
    const name = toArmorSlot(slot.displayProperties.name);
    if (name) map.set(slot.hash, name);
  }
  return map;
}

function findIntrinsicPlug(
  item: RawInventoryItem,
  itemTable: RawTable,
): RawInventoryItem | undefined {
  return findSocketPlug(item, itemTable, (plug) => {
    const cat = plug.plug?.plugCategoryIdentifier ?? "";
    return cat.includes("intrinsics") || plug.itemTypeDisplayName === "Intrinsic";
  });
}

function findArchetypePlug(
  item: RawInventoryItem,
  itemTable: RawTable,
): RawInventoryItem | undefined {
  return findSocketPlug(item, itemTable, (plug) => {
    const cat = plug.plug?.plugCategoryIdentifier ?? "";
    const typeName = plug.itemTypeDisplayName ?? "";
    return cat.includes("armor_archetypes") || typeName.includes("Archetype");
  });
}

function resolveArmorSlot(
  item: RawInventoryItem,
  slotMap: Map<number, ArmorSlotName>,
): ArmorSlotName | null {
  const h = item.equippingBlock?.equipmentSlotTypeHash;
  return h != null ? (slotMap.get(h) ?? null) : null;
}

async function extractExoticArmor(loadTable: LoadTable): Promise<ExoticArmorRecord[]> {
  const [itemTable, slotTable] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyEquipmentSlotDefinition"),
  ]);

  const slotMap = buildSlotMap(slotTable);
  const result: ExoticArmorRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isExoticArmor(item)) continue;

    const slot = resolveArmorSlot(item, slotMap);
    if (!slot) continue;

    const classType = toClassName(item.classType);
    if (!classType) continue;

    const intrinsicPlug = findIntrinsicPlug(item, itemTable);
    if (!intrinsicPlug) continue;

    const archetypePlug = findArchetypePlug(item, itemTable);

    result.push({
      ...projectBase(item),
      classType,
      slot,
      intrinsic: {
        name: intrinsicPlug.displayProperties.name,
        description: intrinsicPlug.displayProperties.description,
      },
      archetype: archetypePlug?.displayProperties.name ?? null,
      flavorText: item.flavorText ?? "",
    });
  }

  return result;
}

export const exoticArmorExtractor: Extractor<"exotic-armor"> = {
  store: "exotic-armor",
  extract: (loadTable) => extractExoticArmor(loadTable),
};
