import type { CreatableSynergyType, SynergyType } from "@/lib/synergies/schemas";

export const SUB_TYPE_REQUIRED_TYPES = ["verb", "melee", "grenade", "super", "element"] as const;

export type SubTypeRequiredType = (typeof SUB_TYPE_REQUIRED_TYPES)[number];

export function requiresSubType(type: SynergyType): type is SubTypeRequiredType {
  return (SUB_TYPE_REQUIRED_TYPES as readonly string[]).includes(type);
}

export function allowsBaseSubType(type: SynergyType): boolean {
  return type === "melee" || type === "grenade" || type === "super";
}

export function isCreatableSynergyType(type: string): type is CreatableSynergyType {
  return !["kinetic_weapon", "damage"].includes(type);
}
