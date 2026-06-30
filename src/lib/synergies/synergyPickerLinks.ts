import { getServices } from "@/lib/services";
import { sortByName } from "@/lib/sortByName";
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

export async function searchSynergyLinkPickerItems(
  kind: "origin_trait" | "weapon_perk" | "armor_set_bonus",
  query: string,
  limit: number,
): Promise<SynergyPickerItem[]> {
  const q = query.trim().toLowerCase();
  const { entityCache } = await getServices();

  if (kind === "origin_trait") {
    const traits = await entityCache.getStore("origin-traits");
    return sortByName(
      traits.filter((t) => !q || t.searchName.includes(q) || t.name.toLowerCase().includes(q)),
    )
      .slice(0, limit)
      .map((t) => ({
        kind: "origin_trait" as const,
        hash: t.hash,
        name: t.name,
        description: t.description,
        originTraitName: t.name,
        originTraitHash: t.hash,
      }));
  }

  if (kind === "weapon_perk") {
    const perks = await entityCache.getStore("weapon-perks");
    return sortByName(
      perks.filter((p) => !q || p.searchName.includes(q) || p.name.toLowerCase().includes(q)),
    )
      .slice(0, limit)
      .map((p) => ({
        kind: "weapon_perk" as const,
        hash: p.hash,
        name: p.name,
        description: p.description,
        perkHash: p.hash,
      }));
  }

  const sets = await entityCache.getStore("set-bonuses");
  const items: SynergyPickerItem[] = [];
  for (const set of sets) {
    const setMatches = !q || set.searchName.includes(q) || set.name.toLowerCase().includes(q);
    for (const perk of set.perks) {
      const perkMatches = !q || perk.name.toLowerCase().includes(q);
      if (!setMatches && !perkMatches) continue;
      items.push({
        kind: "armor_set_bonus",
        name: `${set.name} ${perk.requiredCount}pc — ${perk.name}`,
        description: perk.description,
        armorSetName: set.name,
        bonusPieces: perk.requiredCount as 2 | 4,
        bonusName: perk.name,
        armorSetHash: set.hash,
      });
      if (items.length >= limit) return sortByName(items).slice(0, limit);
    }
  }
  return sortByName(items).slice(0, limit);
}
