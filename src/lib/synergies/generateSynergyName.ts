import type { SynergyType } from "@/lib/synergies/schemas";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";

const MAX_NAME_LENGTH = 120;
const SEPARATOR = " — ";

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

function categoryLabel(type: SynergyType): string {
  return SYNERGY_CATEGORY_LABELS[type] ?? type;
}

export function getSynergyTypeLabel(type: SynergyType | string): string {
  return SYNERGY_CATEGORY_LABELS[type] ?? type;
}

export function generateSynergyName(input: {
  type: SynergyType;
  subType: string | null;
  linkDisplayName: string;
}): string {
  const category = categoryLabel(input.type);
  const link = input.linkDisplayName.trim() || "Unlinked";
  let name: string;

  if (requiresSubType(input.type) && input.subType) {
    name = `${category}: ${input.subType}${SEPARATOR}${link}`;
  } else {
    name = `${category}${SEPARATOR}${link}`;
  }

  if (name.length <= MAX_NAME_LENGTH) return name;

  const prefix = requiresSubType(input.type) && input.subType
    ? `${category}: ${input.subType}${SEPARATOR}`
    : `${category}${SEPARATOR}`;
  const maxLinkLen = MAX_NAME_LENGTH - prefix.length - 1;
  if (maxLinkLen <= 0) return name.slice(0, MAX_NAME_LENGTH);
  return `${prefix}${link.slice(0, maxLinkLen)}…`;
}
