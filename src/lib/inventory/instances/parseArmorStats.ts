import type { ArmorStatName } from "@/data/rules/statBenefits";
import { ARMOR_STAT_NAMES } from "@/data/rules/statBenefits";

export type BungieStatEntry = {
  statHash: number;
  value: number;
};

const STAT_HASH_TO_NAME: Record<number, ArmorStatName> = {
  392767087: "Health",
  4244567218: "Melee",
  1735777505: "Grenade",
  144602215: "Super",
  1943323491: "Class",
  2996146975: "Weapons",
};

export function parseArmorStatValues(
  stats: BungieStatEntry[] | undefined,
): Partial<Record<ArmorStatName, number>> | null {
  if (!stats?.length) return null;
  const result: Partial<Record<ArmorStatName, number>> = {};
  for (const entry of stats) {
    const name = STAT_HASH_TO_NAME[entry.statHash];
    if (!name) continue;
    result[name] = entry.value;
  }
  return Object.keys(result).length > 0 ? result : null;
}

export function isCompleteArmorStats(
  values: Partial<Record<ArmorStatName, number>> | null | undefined,
): boolean {
  if (!values) return false;
  return ARMOR_STAT_NAMES.every((name) => typeof values[name] === "number");
}

export function computeTotalArmorStats(
  values: Partial<Record<ArmorStatName, number>> | null | undefined,
): number {
  if (!values) return 0;
  return ARMOR_STAT_NAMES.reduce((sum, name) => sum + (values[name] ?? 0), 0);
}
