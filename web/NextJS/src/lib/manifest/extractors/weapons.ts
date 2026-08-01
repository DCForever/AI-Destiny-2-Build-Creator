import type { WeaponRecord, WeaponPerkColumn, WeaponSlotName, ElementName, Hash } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem, RawSocketEntry } from "./rawTypes";
import { asRawEquipmentSlot, asRawDamageType } from "./rawTypes";
import {
  iterItems,
  projectBase,
  toWeaponSlot,
  toAmmoType,
  toElementName,
  findSocketPlug,
  socketPlugHashes,
  isOriginSocket,
  isExcludedPerkSocket,
  getPerkSocketIndexes,
} from "./common";
import { isLegendaryWeaponFramePlug } from "@/lib/synergies/weaponArchetypeSubType";

const ITEM_TYPE_WEAPON = 3;
const TIER_LEGENDARY = 5;
const WEAPON_PERKS_CATEGORY_HASH = 4241085061;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isLegendaryWeapon(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_WEAPON && item.inventory?.tierType === TIER_LEGENDARY;
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

function findFramePlug(
  item: RawInventoryItem,
  itemTable: RawTable,
): RawInventoryItem | undefined {
  return findSocketPlug(item, itemTable, isLegendaryWeaponFramePlug);
}

function collectOriginHashes(
  item: RawInventoryItem,
  itemTable: RawTable,
  plugSets: RawTable,
): Hash[] {
  const hashes: Hash[] = [];
  for (const socket of item.sockets?.socketEntries ?? []) {
    if (!isOriginSocket(socket, itemTable)) continue;
    hashes.push(...socketPlugHashes(socket, plugSets).curated);
  }
  return [...new Set(hashes)];
}

function buildSingleColumn(
  socket: RawSocketEntry,
  plugSets: RawTable,
  colIndex: number,
): WeaponPerkColumn {
  const { curated, randomized } = socketPlugHashes(socket, plugSets);
  return { column: colIndex, curated, randomized };
}

function buildPerkColumns(
  item: RawInventoryItem,
  itemTable: RawTable,
  plugSets: RawTable,
): WeaponPerkColumn[] {
  const indexes = getPerkSocketIndexes(item, WEAPON_PERKS_CATEGORY_HASH);
  const sockets = item.sockets?.socketEntries ?? [];
  const columns: WeaponPerkColumn[] = [];
  let colIdx = 0;

  for (const idx of indexes) {
    const socket = sockets[idx];
    if (!socket) continue;
    if (isExcludedPerkSocket(socket, itemTable)) continue;
    const col = buildSingleColumn(socket, plugSets, colIdx);
    if (col.curated.length === 0 && col.randomized.length === 0) continue;
    columns.push(col);
    colIdx++;
  }

  return columns;
}

async function extractWeapons(loadTable: LoadTable): Promise<WeaponRecord[]> {
  const [itemTable, slotTable, damageTable, plugSets] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyEquipmentSlotDefinition"),
    loadTable("DestinyDamageTypeDefinition"),
    loadTable("DestinyPlugSetDefinition"),
  ]);

  const slotMap = buildSlotMap(slotTable);
  const damageMap = buildDamageMap(damageTable);
  const result: WeaponRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isLegendaryWeapon(item)) continue;

    const slotHash = item.equippingBlock?.equipmentSlotTypeHash;
    const slot = slotHash != null ? (slotMap.get(slotHash) ?? null) : null;
    if (!slot) continue;

    const dmgHash = item.defaultDamageTypeHash;
    const element = dmgHash != null ? (damageMap.get(dmgHash) ?? null) : null;
    if (!element) continue;

    const ammo = toAmmoType(item.equippingBlock?.ammoType);
    if (!ammo) continue;

    const framePlug = findFramePlug(item, itemTable);
    if (!framePlug) continue;

    result.push({
      ...projectBase(item),
      slot,
      element,
      ammo,
      frame: framePlug.displayProperties.name,
      itemTypeName: item.itemTypeDisplayName ?? "",
      originTraitHashes: collectOriginHashes(item, itemTable, plugSets),
      perkColumns: buildPerkColumns(item, itemTable, plugSets),
    });
  }

  return result;
}

export const weaponsExtractor: Extractor<"weapons"> = {
  store: "weapons",
  extract: (loadTable) => extractWeapons(loadTable),
};
