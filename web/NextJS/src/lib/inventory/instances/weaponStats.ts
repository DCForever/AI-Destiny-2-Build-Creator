/**
 * Weapon combat stats as shown in DIM item details.
 * Hashes from DestinyStatDefinition / community DIM mappings.
 */

export type WeaponStatName =
  | "RPM"
  | "Impact"
  | "Range"
  | "Stability"
  | "Handling"
  | "Reload Speed"
  | "Aim Assistance"
  | "Airborne"
  | "Zoom"
  | "Ammo Gen"
  | "Recoil Direction"
  | "Magazine";

export type BungieStatEntry = {
  statHash: number;
  value: number;
};

/** Display order matching DIM overview. */
export const WEAPON_STAT_ORDER: readonly WeaponStatName[] = [
  "RPM",
  "Impact",
  "Range",
  "Stability",
  "Handling",
  "Reload Speed",
  "Aim Assistance",
  "Airborne",
  "Zoom",
  "Ammo Gen",
  "Recoil Direction",
  "Magazine",
] as const;

const STAT_HASH_TO_NAME: Record<number, WeaponStatName> = {
  4284893193: "RPM",
  4043523819: "Impact",
  1240592695: "Range",
  155624089: "Stability",
  943549884: "Handling",
  4188031367: "Reload Speed",
  1345609583: "Aim Assistance",
  2714451661: "Airborne",
  3555269338: "Zoom",
  /** Ammo Generation (Edge of Fate era / recent). */
  3022301683: "Ammo Gen",
  2715839340: "Recoil Direction",
  3871231066: "Magazine",
};

/** Soft max for bar fill when Bungie does not supply a cap (visual only). */
export const WEAPON_STAT_BAR_MAX: Partial<Record<WeaponStatName, number>> = {
  RPM: 1000,
  Impact: 100,
  Range: 100,
  Stability: 100,
  Handling: 100,
  "Reload Speed": 100,
  "Aim Assistance": 100,
  Airborne: 100,
  Zoom: 100,
  "Ammo Gen": 100,
  "Recoil Direction": 100,
  Magazine: 100,
};

export function parseWeaponStatValues(
  stats: BungieStatEntry[] | undefined,
): Partial<Record<WeaponStatName, number>> | null {
  if (!stats?.length) return null;
  const result: Partial<Record<WeaponStatName, number>> = {};
  for (const entry of stats) {
    const name = STAT_HASH_TO_NAME[entry.statHash];
    if (!name) continue;
    result[name] = entry.value;
  }
  return Object.keys(result).length > 0 ? result : null;
}

export type WeaponStatLine = {
  name: WeaponStatName;
  value: number;
  /** 0–1 for bar width. */
  ratio: number;
};

export function weaponStatLines(
  values: Partial<Record<string, number>> | null | undefined,
): WeaponStatLine[] {
  if (!values) return [];
  const lines: WeaponStatLine[] = [];
  for (const name of WEAPON_STAT_ORDER) {
    const value = values[name];
    if (typeof value !== "number") continue;
    const max = WEAPON_STAT_BAR_MAX[name] ?? 100;
    lines.push({
      name,
      value,
      ratio: Math.max(0, Math.min(1, value / max)),
    });
  }
  return lines;
}
