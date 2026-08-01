/**
 * Armor 3.0 archetypes — the original six (The Edge of Fate) plus the six
 * added in Update 9.7.0 ("Armor > Armor Stats"). Each piece has a fixed
 * primary and secondary stat from its archetype, plus a random tertiary stat
 * from the remaining four. Sources cached in `src/data/meta/sources/`.
 */

import type { ArmorStatName } from "./statBenefits";

export interface ArmorArchetype {
  name: string;
  primary: ArmorStatName;
  secondary: ArmorStatName;
  /** True for the six archetypes introduced in Update 9.7.0. */
  addedIn970: boolean;
}

export const ARMOR_ARCHETYPES: readonly ArmorArchetype[] = [
  { name: "Brawler", primary: "Melee", secondary: "Health", addedIn970: false },
  { name: "Bulwark", primary: "Health", secondary: "Class", addedIn970: false },
  { name: "Grenadier", primary: "Grenade", secondary: "Super", addedIn970: false },
  { name: "Paragon", primary: "Super", secondary: "Melee", addedIn970: false },
  { name: "Specialist", primary: "Class", secondary: "Weapons", addedIn970: false },
  { name: "Gunner", primary: "Weapons", secondary: "Grenade", addedIn970: false },
  { name: "Siegebreaker", primary: "Health", secondary: "Grenade", addedIn970: true },
  { name: "Skirmisher", primary: "Melee", secondary: "Weapons", addedIn970: true },
  { name: "Demolitionist", primary: "Grenade", secondary: "Class", addedIn970: true },
  { name: "Colossus", primary: "Super", secondary: "Health", addedIn970: true },
  { name: "Reaver", primary: "Class", secondary: "Melee", addedIn970: true },
  { name: "Powerhouse", primary: "Weapons", secondary: "Super", addedIn970: true },
];

export const ARMOR_SYSTEM_NOTES: readonly string[] = [
  "All 12 archetypes drop from every source of Armor 3.0 gear",
  "All Armor 3.0 exotics are Tier 5 with access to all tuning mods (9.7.0)",
  "Raid mod slots exist only on Armor 2.0 raid gear",
  "Armorer Ghost mods give ~1 in 2 odds of dropping the chosen archetype (9.7.0)",
];

export function findArchetypeByName(name: string): ArmorArchetype | null {
  const normalized = name.trim().toLowerCase();
  if (!normalized) return null;
  return (
    ARMOR_ARCHETYPES.find((a) => a.name.toLowerCase() === normalized) ?? null
  );
}

/** Archetypes whose primary or secondary matches the given stat. */
export function findArchetypesForStat(
  stat: ArmorStatName,
): readonly ArmorArchetype[] {
  return ARMOR_ARCHETYPES.filter(
    (a) => a.primary === stat || a.secondary === stat,
  );
}
