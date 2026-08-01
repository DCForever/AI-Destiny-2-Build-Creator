import {
  ARMOR_STAT_NAMES,
  type ArmorStatName,
} from "@/data/rules/statBenefits";
import type { ModRecord } from "@/lib/manifest/types/records";

export type ArmorStatValues = Partial<Record<ArmorStatName, number>>;

export type ModStatLookup = Pick<ModRecord, "hash" | "statModifiers">;

/**
 * Derive base armor roll stats by removing equipped catalog armor-mod
 * investment deltas from live Bungie ItemStats (component 304).
 *
 * Only plugs present in the mods store contribute (enhancements.* / tuning).
 * Intrinsic/archetype/masterwork plugs are left in the base number.
 * Unknown plug hashes are ignored (their contribution remains in the result).
 */
export function stripArmorModStats(
  liveStats: Partial<Record<string, number>> | null | undefined,
  plugHashes: readonly number[] | null | undefined,
  modByHash: ReadonlyMap<number, ModStatLookup>,
): ArmorStatValues | null {
  if (!liveStats) return null;

  const base: ArmorStatValues = {};
  for (const name of ARMOR_STAT_NAMES) {
    const v = liveStats[name];
    if (typeof v === "number") base[name] = v;
  }
  if (Object.keys(base).length === 0) return null;

  if (!plugHashes?.length) return base;

  for (const hash of plugHashes) {
    const mod = modByHash.get(hash);
    const deltas = mod?.statModifiers;
    if (!deltas) continue;
    for (const name of ARMOR_STAT_NAMES) {
      const delta = deltas[name];
      if (typeof delta !== "number" || delta === 0) continue;
      if (typeof base[name] !== "number") continue;
      base[name] = Math.max(0, (base[name] as number) - delta);
    }
  }

  return base;
}
