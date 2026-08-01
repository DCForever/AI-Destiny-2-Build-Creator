import type { FragmentRecord } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { asRawStatDef } from "./rawTypes";
import { iterItems, projectBase, deriveElement } from "./common";

const FRAGMENT_TYPE_RE = /Fragment$/;
const FRAGMENT_CAT_RE = /\.fragments$/;

/** The six Armor 3.0 stat hashes whose values fragments modify. */
const ARMOR_STAT_HASHES = new Set([
  2996146975, // Mobility
  392767087,  // Resilience
  1943323491, // Recovery
  1735777505, // Discipline
  144602215,  // Intellect
  4244567560, // Strength
]);

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isFragmentItem(item: RawInventoryItem): boolean {
  const typeName = item.itemTypeDisplayName ?? "";
  const cat = item.plug?.plugCategoryIdentifier ?? "";
  return FRAGMENT_TYPE_RE.test(typeName) || FRAGMENT_CAT_RE.test(cat);
}

function buildStatNameMap(statTable: RawTable): Map<number, string> {
  const map = new Map<number, string>();
  for (const v of Object.values(statTable)) {
    const stat = asRawStatDef(v);
    if (!stat || !stat.displayProperties.name.trim()) continue;
    if (ARMOR_STAT_HASHES.has(stat.hash)) {
      map.set(stat.hash, stat.displayProperties.name);
    }
  }
  return map;
}

function buildStatModifiers(
  item: RawInventoryItem,
  statNameMap: Map<number, string>,
): Record<string, number> {
  const mods: Record<string, number> = {};
  for (const stat of item.investmentStats ?? []) {
    if (stat.isConditionallyActive) continue;
    const name = statNameMap.get(stat.statTypeHash);
    if (name && stat.value !== 0) mods[name] = stat.value;
  }
  return mods;
}

async function extractFragments(loadTable: LoadTable): Promise<FragmentRecord[]> {
  const [itemTable, statTable] = await Promise.all([
    loadTable("DestinyInventoryItemDefinition"),
    loadTable("DestinyStatDefinition"),
  ]);

  const statNameMap = buildStatNameMap(statTable);
  const result: FragmentRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isFragmentItem(item)) continue;

    const typeName = item.itemTypeDisplayName ?? "";
    const cat = item.plug?.plugCategoryIdentifier ?? "";
    const element = deriveElement(typeName, cat);

    result.push({
      ...projectBase(item),
      description: item.displayProperties.description,
      element,
      statModifiers: buildStatModifiers(item, statNameMap),
    });
  }

  return result;
}

export const fragmentsExtractor: Extractor<"fragments"> = {
  store: "fragments",
  extract: (loadTable) => extractFragments(loadTable),
};
