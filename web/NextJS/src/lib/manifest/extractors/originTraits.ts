import type { OriginTraitRecord, Hash } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { asRawInventoryItem } from "./rawTypes";
import {
  iterItems,
  projectBase,
  isOriginSocket,
  socketPlugHashes,
  perkDescription,
  getRaw,
} from "./common";

const ITEM_TYPE_WEAPON = 3;
const TIER_LEGENDARY = 5;

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isLegendaryWeapon(item: RawInventoryItem): boolean {
  return item.itemType === ITEM_TYPE_WEAPON && item.inventory?.tierType === TIER_LEGENDARY;
}

function collectOriginHashesFromWeapon(
  item: RawInventoryItem,
  itemTable: RawTable,
  plugSets: RawTable,
): Hash[] {
  const hashes: Hash[] = [];
  for (const socket of item.sockets?.socketEntries ?? []) {
    if (!isOriginSocket(socket, itemTable)) continue;
    hashes.push(...socketPlugHashes(socket, plugSets).curated);
  }
  return hashes;
}

async function extractOriginTraits(loadTable: LoadTable): Promise<OriginTraitRecord[]> {
  const [itemTable, plugSets, sandboxPerks] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyPlugSetDefinition"),
    loadTable("DestinySandboxPerkDefinition"),
  ]);

  const allHashes = new Set<Hash>();
  for (const item of iterItems(itemTable)) {
    if (!isLegendaryWeapon(item)) continue;
    for (const h of collectOriginHashesFromWeapon(item, itemTable, plugSets)) {
      allHashes.add(h);
    }
  }

  const result: OriginTraitRecord[] = [];
  for (const hash of allHashes) {
    const raw = getRaw(itemTable, hash);
    const traitItem = asRawInventoryItem(raw);
    if (!traitItem || !traitItem.displayProperties.name.trim()) continue;
    result.push({
      ...projectBase(traitItem),
      description: perkDescription(traitItem, sandboxPerks),
    });
  }

  return result;
}

export const originTraitsExtractor: Extractor<"origin-traits"> = {
  store: "origin-traits",
  extract: (loadTable) => extractOriginTraits(loadTable),
};
