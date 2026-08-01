import {
  ARMOR_STAT_NAMES,
  type ArmorStatName,
} from "@/data/rules/statBenefits";
import { ARMOR_STAT_HASH_TO_NAME } from "@/lib/inventory/instances/parseArmorStats";

export type ArmorStatValues = Partial<Record<ArmorStatName, number>>;

export type PlugStatSource = {
  plugCategoryIdentifier?: string | null;
  investmentStats?: ReadonlyArray<{
    statTypeHash: number;
    value: number;
    isConditionallyActive?: boolean;
  }> | null;
};

/**
 * Armor 3.0 rolled stats live on invisible plugs with category `armor_stats`
 * (DIM "base" / white bar). Sum those investments for the piece's base roll.
 *
 * Excludes equipped armor mods, masterwork, tuning, archetype labels, cosmetics.
 */
export function computeArmorBaseStatsFromPlugs(
  plugHashes: readonly number[] | null | undefined,
  resolvePlug: (hash: number) => PlugStatSource | null | undefined,
): ArmorStatValues | null {
  if (!plugHashes?.length) return null;

  const base: ArmorStatValues = {};
  let sawRollPlug = false;

  for (const hash of plugHashes) {
    const plug = resolvePlug(hash);
    if (!plug) continue;
    const cat = plug.plugCategoryIdentifier ?? "";
    if (!cat.includes("armor_stats")) continue;
    sawRollPlug = true;
    for (const stat of plug.investmentStats ?? []) {
      if (stat.isConditionallyActive) continue;
      if (stat.value === 0) continue;
      const name = ARMOR_STAT_HASH_TO_NAME[stat.statTypeHash];
      if (!name) continue;
      base[name] = (base[name] ?? 0) + stat.value;
    }
  }

  if (!sawRollPlug) return null;

  // Ensure all six keys exist when we found roll plugs (missing = 0).
  for (const name of ARMOR_STAT_NAMES) {
    if (typeof base[name] !== "number") base[name] = 0;
  }
  return base;
}
