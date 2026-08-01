import type { ConceptTagId } from "@/data/conceptTags";

type SubclassLike = {
  name?: string;
  super?: string;
  element?: string;
};

type NameInput = {
  className: string;
  subclass: SubclassLike;
  pinnedSuper?: string | null;
  exoticArmorName?: string | null;
  exoticArmorHash?: number | null;
  exoticWeaponName?: string | null;
  exoticWeaponHash?: number | null;
  synergyNames?: string[];
};

function armorLabel(input: NameInput): string | null {
  if (!input.exoticArmorHash) return null;
  return input.exoticArmorName?.trim() || `Exotic (${input.exoticArmorHash})`;
}

function weaponLabel(input: NameInput): string | null {
  if (!input.exoticWeaponHash) return null;
  return input.exoticWeaponName?.trim() || `Exotic (${input.exoticWeaponHash})`;
}

function elementLabel(subclass: SubclassLike): string | null {
  if (subclass.element?.trim()) return subclass.element.trim();
  return null;
}

function superLabel(input: NameInput): string | null {
  if (input.pinnedSuper?.trim()) return input.pinnedSuper.trim();
  if (input.subclass.super?.trim()) return input.subclass.super.trim();
  return null;
}

/** Derive default build name; omit missing optional segments (no "None"). */
export function deriveDefaultBuildName(input: NameInput): string {
  const parts: string[] = [input.className];
  const element = elementLabel(input.subclass);
  if (element) parts.push(element);
  const superName = superLabel(input);
  if (superName) parts.push(superName);
  const armor = armorLabel(input);
  if (armor) parts.push(armor);
  const weapon = weaponLabel(input);
  if (weapon) parts.push(weapon);
  if (input.synergyNames?.length) {
    parts.push(input.synergyNames.filter(Boolean).join(" + "));
  }
  return parts.join(" · ");
}

export type { ConceptTagId };
