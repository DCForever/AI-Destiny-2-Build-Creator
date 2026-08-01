import {
  linkDedupeKey,
  type MergeableLink,
} from "@/lib/synergies/mergeSynergies";
import type { SynergyPickerItem } from "@/lib/synergies/synergyPickerLinks";

/** Weapon option shape used by SynergyEditPanel weapon search. */
export type WeaponPickerOption = {
  hash: number;
  name: string;
  description?: string;
};

export function draftLinkKeys(links: MergeableLink[]): Set<string> {
  const keys = new Set<string>();
  for (const link of links) {
    keys.add(linkDedupeKey(link));
  }
  return keys;
}

export function weaponOptionToMergeable(opt: WeaponPickerOption): MergeableLink {
  return {
    kind: "weapon",
    displayName: opt.name,
    itemHash: opt.hash,
  };
}

export function pickerItemToMergeable(item: SynergyPickerItem): MergeableLink {
  // hash is the primary entity for the kind: item for weapons/exotics, plug for perks.
  const hashIsPerk =
    item.kind === "weapon_perk" ||
    item.kind === "artifact_perk" ||
    item.kind === "origin_trait" ||
    item.kind === "aspect" ||
    item.kind === "fragment" ||
    item.kind === "armor_mod" ||
    item.kind === "melee" ||
    item.kind === "grenade" ||
    item.kind === "super";

  return {
    kind: item.kind,
    displayName: item.name,
    itemHash: hashIsPerk ? (item.parentItemHash ?? null) : (item.hash ?? null),
    perkHash: item.perkHash ?? (hashIsPerk ? item.hash ?? null : null),
    parentItemHash: item.parentItemHash ?? null,
    originTraitName: item.originTraitName ?? null,
    originTraitHash: item.originTraitHash ?? (item.kind === "origin_trait" ? item.hash ?? null : null),
    armorSetName: item.armorSetName ?? null,
    bonusPieces: item.bonusPieces ?? null,
    bonusName: item.bonusName ?? null,
    armorSetHash: item.armorSetHash ?? (item.kind === "armor_set_bonus" ? item.hash ?? null : null),
  };
}

/** Drop search hits that are already in the draft link list (same coverage key). */
export function filterOutLinkedWeapons(
  options: WeaponPickerOption[],
  draftLinks: MergeableLink[],
): WeaponPickerOption[] {
  const linked = draftLinkKeys(draftLinks);
  return options.filter(
    (opt) => !linked.has(linkDedupeKey(weaponOptionToMergeable(opt))),
  );
}

export function filterOutLinkedPickerItems(
  options: SynergyPickerItem[],
  draftLinks: MergeableLink[],
): SynergyPickerItem[] {
  const linked = draftLinkKeys(draftLinks);
  return options.filter(
    (item) => !linked.has(linkDedupeKey(pickerItemToMergeable(item))),
  );
}
