import type { SavedLoadout } from "@/lib/db/types";

import { exoticNamesMatch } from "./normalizeExoticName";
import type {
  ArmorExoticFilter,
  ExoticFilterCriteria,
  LoadoutExoticSummary,
  WeaponExoticFilter,
} from "./types";

function matchesExact(
  summaryHash: number | null,
  summaryName: string,
  filter: { hash?: number; name?: string },
): boolean {
  if (filter.hash !== undefined && summaryHash !== null) {
    return summaryHash === filter.hash;
  }
  if (filter.name !== undefined) {
    return exoticNamesMatch(summaryName, filter.name);
  }
  return false;
}

function matchesArmorFilter(
  summary: LoadoutExoticSummary,
  filter: ArmorExoticFilter,
): boolean {
  const armor = summary.exoticArmor;
  if (!armor) return false;

  if (filter.mode === "exact") {
    return matchesExact(armor.hash, armor.name, filter);
  }

  if (!filter.slot || !armor.slot) return false;
  if (armor.slot !== filter.slot) return false;
  if (!armor.classType) return false;
  return armor.classType === summary.className;
}

function matchesWeaponFilter(
  summary: LoadoutExoticSummary,
  filter: WeaponExoticFilter,
): boolean {
  const weapon = summary.exoticWeapon;
  if (!weapon) return false;

  if (filter.mode === "exact") {
    return matchesExact(weapon.hash, weapon.name, filter);
  }

  return weapon.slot === filter.slot;
}

export function matchesExoticFilter(
  summary: LoadoutExoticSummary,
  criteria: ExoticFilterCriteria,
): boolean {
  const hasArmor = criteria.armor != null;
  const hasWeapon = criteria.weapon != null;

  if (!hasArmor && !hasWeapon) return true;

  if (hasArmor && !matchesArmorFilter(summary, criteria.armor!)) {
    return false;
  }
  if (hasWeapon && !matchesWeaponFilter(summary, criteria.weapon!)) {
    return false;
  }
  return true;
}

export function filterLoadouts(
  loadouts: SavedLoadout[],
  criteria: ExoticFilterCriteria,
  summaries: Map<string, LoadoutExoticSummary>,
): SavedLoadout[] {
  if (!criteria.armor && !criteria.weapon) {
    return loadouts;
  }

  return loadouts.filter((loadout) => {
    const summary = summaries.get(loadout.id);
    if (!summary) return false;
    return matchesExoticFilter(summary, criteria);
  });
}
