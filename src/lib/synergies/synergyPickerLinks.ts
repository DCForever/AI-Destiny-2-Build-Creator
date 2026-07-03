import { getServices } from "@/lib/services";
import { sortByName } from "@/lib/sortByName";
import {
  matchDescriptionQuery,
  sortByMatchRankThenName,
} from "@/lib/search/descriptionMatch";
import type { SynergyLinkInput } from "@/lib/synergies/schemas";

export type SynergyPickerItem = {
  kind: SynergyLinkInput["kind"];
  hash?: number;
  name: string;
  description: string;
  originTraitName?: string;
  originTraitHash?: number;
  perkHash?: number;
  parentItemHash?: number;
  armorSetName?: string;
  bonusPieces?: 2 | 4;
  bonusName?: string;
  armorSetHash?: number;
};

function shouldPreferPickerItem(current: SynergyPickerItem, next: SynergyPickerItem): boolean {
  const currentDesc = current.description?.trim() ?? "";
  const nextDesc = next.description?.trim() ?? "";
  if (nextDesc.length !== currentDesc.length) return nextDesc.length > currentDesc.length;
  const currentHash = current.hash ?? Number.MAX_SAFE_INTEGER;
  const nextHash = next.hash ?? Number.MAX_SAFE_INTEGER;
  return nextHash < currentHash;
}

function dedupePickerItemsByName(items: SynergyPickerItem[]): SynergyPickerItem[] {
  const seen = new Map<string, SynergyPickerItem>();
  for (const item of items) {
    const existing = seen.get(item.name);
    if (!existing || shouldPreferPickerItem(existing, item)) {
      seen.set(item.name, item);
    }
  }
  return [...seen.values()];
}

function finalizePickerItems(
  items: SynergyPickerItem[],
  limit: number,
  query: string,
): SynergyPickerItem[] {
  const q = query.trim();
  if (!q) {
    return sortByName(dedupePickerItemsByName(items)).slice(0, limit);
  }

  const ranked = sortByMatchRankThenName(
    items.map((item) => ({
      item,
      matchField: matchDescriptionQuery(q, {
        name: item.name,
        description: item.description,
        otherTexts: item.bonusName ? [item.bonusName, item.armorSetName ?? ""] : undefined,
      }).matchField,
    })),
  );

  return dedupePickerItemsByName(ranked).slice(0, limit);
}

export async function searchSynergyLinkPickerItems(
  kind: "origin_trait" | "weapon_perk" | "armor_set_bonus",
  query: string,
  limit: number,
): Promise<SynergyPickerItem[]> {
  const q = query.trim();
  const { entityCache } = await getServices();

  if (kind === "origin_trait") {
    const traits = await entityCache.getStore("origin-traits");
    const items = traits
      .filter(
        (t) =>
          !q ||
          matchDescriptionQuery(q, {
            name: t.name,
            searchName: t.searchName,
            description: t.description,
          }).matched,
      )
      .map((t) => ({
        kind: "origin_trait" as const,
        hash: t.hash,
        name: t.name,
        description: t.description,
        originTraitName: t.name,
        originTraitHash: t.hash,
      }));
    return finalizePickerItems(items, limit, query);
  }

  if (kind === "weapon_perk") {
    const perks = await entityCache.getStore("weapon-perks");
    const items = perks
      .filter(
        (p) =>
          !q ||
          matchDescriptionQuery(q, {
            name: p.name,
            searchName: p.searchName,
            description: p.description,
          }).matched,
      )
      .map((p) => ({
        kind: "weapon_perk" as const,
        hash: p.hash,
        name: p.name,
        description: p.description,
        perkHash: p.hash,
      }));
    return finalizePickerItems(items, limit, query);
  }

  const sets = await entityCache.getStore("set-bonuses");
  const items: SynergyPickerItem[] = [];
  for (const set of sets) {
    for (const perk of set.perks) {
      const matched =
        !q ||
        matchDescriptionQuery(q, {
          name: set.name,
          searchName: set.searchName,
          otherTexts: [perk.name, perk.description],
        }).matched;
      if (!matched) continue;
      items.push({
        kind: "armor_set_bonus",
        name: `${set.name} ${perk.requiredCount}pc — ${perk.name}`,
        description: perk.description,
        armorSetName: set.name,
        bonusPieces: perk.requiredCount as 2 | 4,
        bonusName: perk.name,
        armorSetHash: set.hash,
      });
      if (items.length >= limit * 2) break;
    }
    if (items.length >= limit * 2) break;
  }
  return finalizePickerItems(items, limit, query);
}
