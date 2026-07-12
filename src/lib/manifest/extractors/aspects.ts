import type { AspectRecord, DestinyClassName } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import { iterItems, projectBase, toClassName, deriveElement } from "./common";

const ASPECT_CATEGORY_RE = /^(titan|hunter|warlock|shared)\.(arc|solar|void|stasis|strand|prismatic)\.aspects$/;
const ASPECT_ENERGY_STAT_HASH = 2223994109;

const CLASS_FROM_CAT: Record<string, DestinyClassName> = {
  titan: "Titan",
  hunter: "Hunter",
  warlock: "Warlock",
};

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isAspectItem(item: RawInventoryItem): boolean {
  const cat = item.plug?.plugCategoryIdentifier ?? "";
  const typeName = item.itemTypeDisplayName ?? "";
  return ASPECT_CATEGORY_RE.test(cat) || typeName.endsWith("Aspect");
}

function getFragmentCapacity(item: RawInventoryItem): number {
  const stat = item.investmentStats?.find((s) => s.statTypeHash === ASPECT_ENERGY_STAT_HASH);
  if (stat !== undefined) return stat.value;
  return item.sockets?.socketEntries?.length ?? 0;
}

function classTypeFromCategory(categoryId: string): DestinyClassName | null {
  const match = /^(titan|hunter|warlock)\./i.exec(categoryId);
  if (!match) return null;
  return CLASS_FROM_CAT[match[1].toLowerCase()] ?? null;
}

async function extractAspects(loadTable: LoadTable): Promise<AspectRecord[]> {
  const itemTable = await loadTable("DestinyInventoryItemDefinition");
  const result: AspectRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isAspectItem(item)) continue;

    const typeName = item.itemTypeDisplayName ?? "";
    const cat = item.plug?.plugCategoryIdentifier ?? "";
    const element = deriveElement(typeName, cat);
    const classType = toClassName(item.classType) ?? classTypeFromCategory(cat);

    result.push({
      ...projectBase(item),
      description: item.displayProperties.description,
      classType,
      element,
      fragmentCapacity: getFragmentCapacity(item),
    });
  }

  return result;
}

export const aspectsExtractor: Extractor<"aspects"> = {
  store: "aspects",
  extract: (loadTable) => extractAspects(loadTable),
};
