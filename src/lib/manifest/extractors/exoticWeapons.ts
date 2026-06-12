import type { ExoticWeaponRecord, WeaponSlotName, ElementName } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { asRawEquipmentSlot, asRawDamageType } from "./rawTypes";
import {
  iterItems,
  projectBase,
  toWeaponSlot,
  toAmmoType,
  toElementName,
  findSocketPlug,
} from "./common";

const ITEM_TYPE_WEAPON = 3;
const TIER_EXOTIC = 6;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isExoticWeapon(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_WEAPON && item.inventory?.tierType === TIER_EXOTIC;
}

function buildSlotMap(slotTable: RawTable): Map<number, WeaponSlotName> {
  const map = new Map<number, WeaponSlotName>();
  for (const v of Object.values(slotTable)) {
    const slot = asRawEquipmentSlot(v);
    if (!slot) continue;
    const name = toWeaponSlot(slot.displayProperties.name);
    if (name) map.set(slot.hash, name);
  }
  return map;
}

function buildDamageMap(damageTable: RawTable): Map<number, ElementName> {
  const map = new Map<number, ElementName>();
  for (const v of Object.values(damageTable)) {
    const dt = asRawDamageType(v);
    if (!dt) continue;
    const name = toElementName(dt.displayProperties.name);
    if (name) map.set(dt.hash, name);
  }
  return map;
}

function findIntrinsicPlug(
  item: RawInventoryItem,
  itemTable: RawTable,
): RawInventoryItem | undefined {
  return findSocketPlug(item, itemTable, (plug) =>
    (plug.plug?.plugCategoryIdentifier ?? "").includes("intrinsics"),
  );
}

function findCatalystPlug(
  item: RawInventoryItem,
  itemTable: RawTable,
): RawInventoryItem | undefined {
  return findSocketPlug(item, itemTable, (plug) =>
    plug.displayProperties.name.endsWith("Catalyst"),
  );
}

function resolveSlot(item: RawInventoryItem, slotMap: Map<number, WeaponSlotName>): WeaponSlotName | null {
  const h = item.equippingBlock?.equipmentSlotTypeHash;
  return h != null ? (slotMap.get(h) ?? null) : null;
}

function resolveElement(item: RawInventoryItem, damageMap: Map<number, ElementName>): ElementName | null {
  const h = item.defaultDamageTypeHash;
  return h != null ? (damageMap.get(h) ?? null) : null;
}

async function extractExoticWeapons(loadTable: LoadTable): Promise<ExoticWeaponRecord[]> {
  const [itemTable, slotTable, damageTable] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyEquipmentSlotDefinition"),
    loadTable("DestinyDamageTypeDefinition"),
  ]);

  const slotMap = buildSlotMap(slotTable);
  const damageMap = buildDamageMap(damageTable);
  const result: ExoticWeaponRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isExoticWeapon(item)) continue;

    const slot = resolveSlot(item, slotMap);
    if (!slot) continue;

    const element = resolveElement(item, damageMap);
    if (!element) continue;

    const ammo = toAmmoType(item.equippingBlock?.ammoType);
    if (!ammo) continue;

    const intrinsicPlug = findIntrinsicPlug(item, itemTable);
    if (!intrinsicPlug) continue;

    const catalystPlug = findCatalystPlug(item, itemTable);

    result.push({
      ...projectBase(item),
      slot,
      element,
      ammo,
      frame: intrinsicPlug.displayProperties.name,
      intrinsic: {
        name: intrinsicPlug.displayProperties.name,
        description: intrinsicPlug.displayProperties.description,
      },
      catalyst: catalystPlug
        ? {
            name: catalystPlug.displayProperties.name,
            description: catalystPlug.displayProperties.description,
          }
        : null,
      flavorText: item.flavorText ?? "",
    });
  }

  return result;
}

export const exoticWeaponsExtractor: Extractor<"exotic-weapons"> = {
  store: "exotic-weapons",
  extract: (loadTable) => extractExoticWeapons(loadTable),
};
