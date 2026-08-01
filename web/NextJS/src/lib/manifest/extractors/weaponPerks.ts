import type { PerkRecord, Hash, WeaponPerkSource } from "../types/records";
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
  findSocketPlug,
} from "./common";

const ITEM_TYPE_WEAPON = 3;
const TIER_LEGENDARY = 5;
const TIER_EXOTIC = 6;
const WEAPON_PERKS_CATEGORY_HASH = 4241085061;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isLegendaryWeapon(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_WEAPON && item.inventory?.tierType === TIER_LEGENDARY;
}

function isExoticWeapon(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_WEAPON && item.inventory?.tierType === TIER_EXOTIC;
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

function sourceForHash(
  hash: Hash,
  fromLegendary: Set<Hash>,
  fromExotic: Set<Hash>,
): WeaponPerkSource | undefined {
  const leg = fromLegendary.has(hash);
  const exo = fromExotic.has(hash);
  if (leg && exo) return "both";
  if (exo) return "exotic";
  if (leg) return "legendary";
  return undefined;
}

async function extractWeaponPerks(loadTable: LoadTable): Promise<PerkRecord[]> {
  const [itemTable, plugSets, sandboxPerks] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyPlugSetDefinition"),
    loadTable("DestinySandboxPerkDefinition"),
  ]);

  const fromLegendary = new Set<Hash>();
  const fromExotic = new Set<Hash>();

  for (const item of iterItems(itemTable)) {
    if (isLegendaryWeapon(item)) {
      for (const h of collectPerkHashesFromWeapon(item, itemTable, plugSets)) {
        fromLegendary.add(h);
      }
      continue;
    }
    if (isExoticWeapon(item)) {
      for (const h of collectPerkHashesFromWeapon(item, itemTable, plugSets)) {
        fromExotic.add(h);
      }
      // True exotic intrinsic (INTRINSICS socket), e.g. Starlight Beam.
      const intrinsic = findSocketPlug(item, itemTable, (plug) =>
        (plug.plug?.plugCategoryIdentifier ?? "").includes("intrinsics"),
      );
      if (intrinsic) fromExotic.add(intrinsic.hash);
    }
  }

  const allHashes = new Set<Hash>([...fromLegendary, ...fromExotic]);

  const result: PerkRecord[] = [];
  for (const hash of allHashes) {
    const raw = getRaw(itemTable, hash);
    const perkItem = asRawInventoryItem(raw);
    if (!perkItem || !perkItem.displayProperties.name.trim()) continue;
    const plugTypeName = perkItem.itemTypeDisplayName?.trim() || null;
    result.push({
      ...projectBase(perkItem),
      description: perkDescription(perkItem, sandboxPerks),
      source: sourceForHash(hash, fromLegendary, fromExotic),
      plugTypeName,
    });
  }

  return result;
}

export const weaponPerksExtractor: Extractor<"weapon-perks"> = {
  store: "weapon-perks",
  extract: (loadTable) => extractWeaponPerks(loadTable),
};
