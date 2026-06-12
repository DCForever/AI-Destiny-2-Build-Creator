import type { PerkRecord, Hash } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { asRawInventoryItem } from "./rawTypes";
import {
  iterItems,
  projectBase,
  socketPlugHashes,
  isOriginSocket,
  isExcludedPerkSocket,
  getPerkSocketIndexes,
  perkDescription,
  getRaw,
} from "./common";

const ITEM_TYPE_WEAPON = 3;
const TIER_LEGENDARY = 5;
const WEAPON_PERKS_CATEGORY_HASH = 4241085061;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isLegendaryWeapon(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_WEAPON && item.inventory?.tierType === TIER_LEGENDARY;
}

function collectPerkHashesFromWeapon(
  item: RawInventoryItem,
  itemTable: RawTable,
  plugSets: RawTable,
): Hash[] {
  const indexes = getPerkSocketIndexes(item, WEAPON_PERKS_CATEGORY_HASH);
  const sockets = item.sockets?.socketEntries ?? [];
  const hashes: Hash[] = [];

  for (const idx of indexes) {
    const socket = sockets[idx];
    if (!socket || isExcludedPerkSocket(socket, itemTable)) continue;
    if (isOriginSocket(socket, itemTable)) continue;
    const { curated, randomized } = socketPlugHashes(socket, plugSets);
    hashes.push(...curated, ...randomized);
  }

  return hashes;
}

async function extractWeaponPerks(loadTable: LoadTable): Promise<PerkRecord[]> {
  const [itemTable, plugSets, sandboxPerks] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyPlugSetDefinition"),
    loadTable("DestinySandboxPerkDefinition"),
  ]);

  const allHashes = new Set<Hash>();
  for (const item of iterItems(itemTable)) {
    if (!isLegendaryWeapon(item)) continue;
    for (const h of collectPerkHashesFromWeapon(item, itemTable, plugSets)) {
      allHashes.add(h);
    }
  }

  const result: PerkRecord[] = [];
  for (const hash of allHashes) {
    const raw = getRaw(itemTable, hash);
    const perkItem = asRawInventoryItem(raw);
    if (!perkItem || !perkItem.displayProperties.name.trim()) continue;
    result.push({
      ...projectBase(perkItem),
      description: perkDescription(perkItem, sandboxPerks),
    });
  }

  return result;
}

export const weaponPerksExtractor: Extractor<"weapon-perks"> = {
  store: "weapon-perks",
  extract: (loadTable) => extractWeaponPerks(loadTable),
};
