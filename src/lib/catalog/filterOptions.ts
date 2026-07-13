/** Shared multi-filter chip options for Catalog browse and Set slot fill. */

export const CATALOG_ELEMENTS = [
  "Kinetic",
  "Arc",
  "Solar",
  "Void",
  "Stasis",
  "Strand",
  "Prismatic",
] as const;

export const CATALOG_AMMO_TYPES = ["Primary", "Special", "Heavy"] as const;

export const CATALOG_WEAPON_ARCHETYPES = [
  "Auto Rifle",
  "Pulse Rifle",
  "Scout Rifle",
  "Hand Cannon",
  "Sidearm",
  "Submachine Gun",
  "Bow",
  "Fusion Rifle",
  "Glaive",
  "Sniper Rifle",
  "Shotgun",
  "Trace Rifle",
  "Grenade Launcher",
  "Rocket Launcher",
  "Linear Fusion Rifle",
  "Machine Gun",
  "Sword",
] as const;

/** Common armor 3.0 archetypes (frame field on armor catalog rows). */
export const CATALOG_ARMOR_ARCHETYPES = [
  "Bulwark",
  "Brawler",
  "Grenadier",
  "Specialist",
  "Gunner",
  "Paragon",
] as const;

export function toggleFilterValue(list: string[], value: string): string[] {
  return list.includes(value)
    ? list.filter((v) => v !== value)
    : [...list, value];
}
