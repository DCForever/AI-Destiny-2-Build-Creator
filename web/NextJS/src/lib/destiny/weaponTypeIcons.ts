/**
 * Weapon type → destiny-icons SVG (same mapping DIM uses).
 * Files live under public/destiny-icons/weapons/ (vendored from justrealmilk/destiny-icons).
 */

import { CATALOG_WEAPON_ARCHETYPES } from "@/lib/catalog/filterOptions";

export type CatalogWeaponType = (typeof CATALOG_WEAPON_ARCHETYPES)[number];

/** Public URL path for a weapon type glyph. */
export const WEAPON_TYPE_ICON_PATH: Record<CatalogWeaponType, string> = {
  "Auto Rifle": "/destiny-icons/weapons/auto_rifle.svg",
  "Pulse Rifle": "/destiny-icons/weapons/pulse_rifle.svg",
  "Scout Rifle": "/destiny-icons/weapons/scout_rifle.svg",
  "Hand Cannon": "/destiny-icons/weapons/hand_cannon.svg",
  Sidearm: "/destiny-icons/weapons/sidearm.svg",
  "Submachine Gun": "/destiny-icons/weapons/smg.svg",
  Bow: "/destiny-icons/weapons/bow.svg",
  "Fusion Rifle": "/destiny-icons/weapons/fusion_rifle.svg",
  Glaive: "/destiny-icons/weapons/glaive.svg",
  "Sniper Rifle": "/destiny-icons/weapons/sniper_rifle.svg",
  Shotgun: "/destiny-icons/weapons/shotgun.svg",
  "Trace Rifle": "/destiny-icons/weapons/beam_weapon.svg",
  "Grenade Launcher": "/destiny-icons/weapons/grenade_launcher.svg",
  "Rocket Launcher": "/destiny-icons/weapons/rocket_launcher.svg",
  "Linear Fusion Rifle": "/destiny-icons/weapons/wire_rifle.svg",
  "Machine Gun": "/destiny-icons/weapons/machinegun.svg",
  Sword: "/destiny-icons/weapons/sword_heavy.svg",
};

const BY_NORMALIZED = new Map<string, string>(
  Object.entries(WEAPON_TYPE_ICON_PATH).map(([name, path]) => [
    name.toLowerCase(),
    path,
  ]),
);

/** Plural / DIM label aliases. */
const ALIASES: Record<string, CatalogWeaponType> = {
  bows: "Bow",
  "submachine guns": "Submachine Gun",
  smg: "Submachine Gun",
  "trace rifles": "Trace Rifle",
  "grenade launchers": "Grenade Launcher",
  "linear fusion rifles": "Linear Fusion Rifle",
  "machine guns": "Machine Gun",
  swords: "Sword",
  glaives: "Glaive",
};

export function weaponTypeIconPath(
  typeName: string | null | undefined,
): string | null {
  if (!typeName?.trim()) return null;
  const raw = typeName.trim();
  const direct = WEAPON_TYPE_ICON_PATH[raw as CatalogWeaponType];
  if (direct) return direct;
  const lower = raw.toLowerCase();
  if (BY_NORMALIZED.has(lower)) return BY_NORMALIZED.get(lower)!;
  const alias = ALIASES[lower];
  if (alias) return WEAPON_TYPE_ICON_PATH[alias];
  return null;
}
