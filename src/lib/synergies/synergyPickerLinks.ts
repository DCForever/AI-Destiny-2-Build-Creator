import { getServices } from "@/lib/services";
import { sortByName } from "@/lib/sortByName";
import {
  matchDescriptionQuery,
  sortByMatchRankThenName,
} from "@/lib/search/descriptionMatch";
import type { SynergyLinkInput } from "@/lib/synergies/schemas";
import { formatWeaponPerkSourceLabel } from "@/lib/synergies/weaponPerkSourceLabel";

export type SynergyPickerItem = {
  kind: SynergyLinkInput["kind"];
  hash?: number;
  name: string;
  description: string;
  icon?: string | null;
  originTraitName?: string;
  originTraitHash?: number;
  perkHash?: number;
  parentItemHash?: number;
  /** Parent artifact name for artifact_perk (e.g. "Tablet of Ruin"). */
  artifactName?: string;
  /** weapon_perk: "Exotic trait" / "Legendary perk" / etc. */
  sourceLabel?: string;
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

export type SynergyPickerLinkKind =
  | "origin_trait"
  | "weapon_perk"
  | "armor_set_bonus"
  | "exotic_armor"
  | "artifact_perk"
  | "aspect"
  | "fragment"
  | "armor_mod"
  | "melee"
  | "grenade"
  | "super";

export async function searchSynergyLinkPickerItems(
  kind: SynergyPickerLinkKind,
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
        icon: t.icon,
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
        icon: p.icon,
        perkHash: p.hash,
        sourceLabel: formatWeaponPerkSourceLabel(p.source, p.plugTypeName),
      }));
    return finalizePickerItems(items, limit, query);
  }

  if (kind === "armor_set_bonus") {
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
          icon: set.icon,
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

  if (kind === "exotic_armor") {
    const armor = await entityCache.getStore("exotic-armor");
    const items = armor
      .filter(
        (a) =>
          !q ||
          matchDescriptionQuery(q, {
            name: a.name,
            searchName: a.searchName,
            description: a.intrinsic?.description ?? "",
          }).matched,
      )
      .map((a) => {
        const isClassItem = a.slot === "ClassItem";
        // DBR-ID-011: class items are perk-config targets; classic use item hash.
        // Picker still returns the shell hash for classic; class items note
        // that evidence should store spirit/perk hashes via perkHash.
        return {
          kind: "exotic_armor" as const,
          hash: a.hash,
          name: isClassItem ? `${a.name} (class item — link perks)` : a.name,
          description: isClassItem
            ? `${a.intrinsic?.description ?? ""} Class-item synergies target perk configuration, not the item shell.`
            : (a.intrinsic?.description ?? ""),
          icon: a.icon,
        };
      });
    return finalizePickerItems(items, limit, query);
  }

  if (kind === "aspect" || kind === "fragment") {
    const store = kind === "aspect" ? "aspects" : "fragments";
    const rows = await entityCache.getStore(store);
    const items = rows
      .filter(
        (r) =>
          !q ||
          matchDescriptionQuery(q, {
            name: r.name,
            searchName: r.searchName,
            description: r.description,
          }).matched,
      )
      .map((r) => ({
        kind,
        hash: r.hash,
        name: r.name,
        description: r.description ?? "",
        icon: r.icon,
      }));
    return finalizePickerItems(items, limit, query);
  }

  if (kind === "armor_mod") {
    const mods = await entityCache.getStore("mods");
    const items = mods
      .filter(
        (m) =>
          !q ||
          matchDescriptionQuery(q, {
            name: m.name,
            searchName: m.searchName,
            description: m.description,
          }).matched,
      )
      .map((m) => ({
        kind: "armor_mod" as const,
        hash: m.hash,
        name: m.name,
        description: m.description ?? "",
        icon: m.icon,
        perkHash: m.hash,
      }));
    return finalizePickerItems(items, limit, query);
  }

  if (kind === "melee" || kind === "grenade" || kind === "super") {
    const abilities = await entityCache.getStore("abilities");
    const items = abilities
      .filter((a) => a.kind === kind)
      .filter(
        (a) =>
          !q ||
          matchDescriptionQuery(q, {
            name: a.name,
            searchName: a.searchName,
            description: a.description,
          }).matched,
      )
      .map((a) => ({
        kind,
        hash: a.hash,
        name: a.name,
        description: a.description ?? "",
        icon: a.icon,
        perkHash: a.hash,
      }));
    return finalizePickerItems(items, limit, query);
  }

  // artifact_perk — name is the mod; artifactName labels which tree it comes from
  const artifacts = await entityCache.getStore("artifacts");
  const items: SynergyPickerItem[] = [];
  for (const art of artifacts) {
    for (const perk of art.perks ?? []) {
      const artifactName = perk.artifactName?.trim() || art.name;
      const matched =
        !q ||
        matchDescriptionQuery(q, {
          name: perk.name,
          searchName: perk.searchName,
          description: perk.description,
          otherTexts: [artifactName, art.name],
        }).matched;
      if (!matched) continue;
      items.push({
        kind: "artifact_perk",
        hash: perk.hash,
        name: perk.name,
        description: perk.description ?? "",
        icon: perk.icon ?? art.icon,
        perkHash: perk.hash,
        parentItemHash: art.hash,
        artifactName,
      });
    }
  }
  return finalizePickerItems(items, limit, query);
}
