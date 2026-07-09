import type { AbilityRecord, AbilityKind } from "../types/records";
import type { Extractor, RawTable, RawTableName } from "../types/services";
import type { RawInventoryItem } from "./rawTypes";
import {
  deriveAbilityVerbs,
  deriveSubclassAffinities,
} from "./abilityEnrichment";
import { iterItems, projectBase, toClassName, deriveElement } from "./common";

const ABILITY_CAT_RE = /\.(supers|grenades|melee|class_abilities|movement)$/;

const KIND_MAP: Record<string, AbilityKind> = {
  supers: "super",
  grenades: "grenade",
  melee: "melee",
  class_abilities: "classAbility",
  movement: "movement",
};

type LoadTable = (table: RawTableName) => Promise<RawTable>;

function isAbilityItem(item: RawInventoryItem): boolean {
  const cat = item.plug?.plugCategoryIdentifier ?? "";
  return ABILITY_CAT_RE.test(cat);
}

function resolveKind(categoryId: string): AbilityKind | null {
  const match = ABILITY_CAT_RE.exec(categoryId);
  if (!match) return null;
  return KIND_MAP[match[1]] ?? null;
}

async function extractAbilities(loadTable: LoadTable): Promise<AbilityRecord[]> {
  const itemTable = await loadTable("DestinyInventoryItemDefinition");
  const result: AbilityRecord[] = [];

  for (const item of iterItems(itemTable)) {
    if (!isAbilityItem(item)) continue;

    const cat = item.plug?.plugCategoryIdentifier ?? "";
    const kind = resolveKind(cat);
    if (!kind) continue;

    const typeName = item.itemTypeDisplayName ?? "";
    const element = deriveElement(typeName, cat);
    const classType = toClassName(item.classType);
    const description = item.displayProperties.description;

    result.push({
      ...projectBase(item),
      description,
      kind,
      classType,
      element,
      // Rebuild abilities entity cache after extractor changes (013 enrichment fields).
      subclassAffinities: deriveSubclassAffinities({
        hash: item.hash,
        plugCategoryIdentifier: cat,
        classType,
        element,
      }),
      verbs: deriveAbilityVerbs({ hash: item.hash, description }),
    });
  }

  return result;
}

export const abilitiesExtractor: Extractor<"abilities"> = {
  store: "abilities",
  extract: (loadTable) => extractAbilities(loadTable),
};
