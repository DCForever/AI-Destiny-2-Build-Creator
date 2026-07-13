import type { SynergyType } from "@/lib/synergies/schemas";

const MAX_NAME_LENGTH = 120;

export const SYNERGY_CATEGORY_LABELS: Record<string, string> = {
  melee: "Melee",
  verb: "Verb",
  grenade: "Grenade",
  super: "Super",
  element: "Element",
  primary_weapon: "Primary Weapon",
  special_weapon: "Special Weapon",
  heavy_weapon: "Heavy Weapon",
  dps: "DPS",
  damage: "DPS",
  healing: "Healing",
  solo: "Solo",
  damage_resist: "DR",
  general_weapon: "General Weapon",
  weapon_archetype: "Weapon Archetype",
  team: "Team",
  kinetic_weapon: "Kinetic Weapon",
};

export function getSynergyTypeLabel(type: SynergyType | string): string {
  return SYNERGY_CATEGORY_LABELS[type] ?? type;
}

/** Display label for a build/library Synergy Type designation (no object suffix). */
export function formatSynergyTypeDesignation(input: {
  type: SynergyType | string;
  subType?: string | null;
}): string {
  const category = getSynergyTypeLabel(input.type);
  const sub = input.subType?.trim();
  if (sub) return `${category}: ${sub}`;
  return category;
}

export function synergyTypeDesignationKey(input: {
  type: string;
  subType?: string | null;
}): string {
  const sub = input.subType?.trim() || "";
  return `${input.type}::${sub}`;
}

/**
 * Stored library name is the designation only (e.g. "Verb: Devour").
 * `linkDisplayName` is accepted for call-site compatibility but ignored.
 */
export function generateSynergyName(input: {
  type: SynergyType;
  subType: string | null;
  linkDisplayName?: string;
}): string {
  const name = formatSynergyTypeDesignation({
    type: input.type,
    subType: input.subType,
  });
  if (name.length <= MAX_NAME_LENGTH) return name;
  return name.slice(0, MAX_NAME_LENGTH);
}
