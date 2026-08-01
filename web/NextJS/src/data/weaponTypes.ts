/** Canonical Destiny weapon itemTypeDisplayName values for preference pickers. */
export const KNOWN_WEAPON_TYPES = [
  "Auto Rifle",
  "Bow",
  "Fusion Rifle",
  "Glaive",
  "Grenade Launcher",
  "Hand Cannon",
  "Linear Fusion Rifle",
  "Machine Gun",
  "Pulse Rifle",
  "Rocket Launcher",
  "Scout Rifle",
  "Shotgun",
  "Sidearm",
  "Sniper Rifle",
  "Submachine Gun",
  "Sword",
  "Trace Rifle",
] as const;

export type KnownWeaponType = (typeof KNOWN_WEAPON_TYPES)[number];

const KNOWN_SET = new Set<string>(KNOWN_WEAPON_TYPES);

export function isKnownWeaponType(name: string): name is KnownWeaponType {
  return KNOWN_SET.has(name.trim());
}

/** Keep only vocabulary members; drop unknown free-text entries. */
export function filterKnownWeaponTypes(names: readonly string[]): KnownWeaponType[] {
  const out: KnownWeaponType[] = [];
  const seen = new Set<string>();
  for (const raw of names) {
    const name = raw.trim();
    if (!isKnownWeaponType(name) || seen.has(name)) continue;
    seen.add(name);
    out.push(name);
  }
  return out;
}

export function toggleWeaponType(
  selected: readonly string[],
  type: KnownWeaponType,
): KnownWeaponType[] {
  const current = filterKnownWeaponTypes(selected);
  if (current.includes(type)) return current.filter((t) => t !== type);
  return [...current, type];
}
