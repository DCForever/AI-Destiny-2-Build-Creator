import {
  ARMOR_STAT_NAMES,
  type ArmorStatName,
} from "@/data/rules/statBenefits";
import {
  computeTotalArmorStats,
  isCompleteArmorStats,
} from "@/lib/inventory/instances/parseArmorStats";

export type ArmorStatSlice = {
  statValues?: Partial<Record<string, number>> | null;
  statsIncomplete?: boolean | null;
  instanceId?: string | null;
};

export type ArmorSetStatTotals = {
  statValues: Partial<Record<ArmorStatName, number>>;
  grandTotal: number;
  incomplete: boolean;
  piecesWithStats: number;
};

/**
 * Sum EoF six armor stats across set pieces that have instance rolls.
 */
export function sumArmorSetStats(items: ArmorStatSlice[]): ArmorSetStatTotals {
  const statValues: Partial<Record<ArmorStatName, number>> = {};
  let piecesWithStats = 0;
  let incomplete = false;

  for (const item of items) {
    const vals = item.statValues;
    if (!vals) {
      if (item.instanceId) incomplete = true;
      continue;
    }
    const hasAny = ARMOR_STAT_NAMES.some((n) => typeof vals[n] === "number");
    if (!hasAny) {
      if (item.instanceId) incomplete = true;
      continue;
    }
    piecesWithStats += 1;
    if (item.statsIncomplete || !isCompleteArmorStats(vals)) {
      incomplete = true;
    }
    for (const name of ARMOR_STAT_NAMES) {
      const v = vals[name];
      if (typeof v !== "number") continue;
      statValues[name] = (statValues[name] ?? 0) + v;
    }
  }

  return {
    statValues,
    grandTotal: computeTotalArmorStats(statValues),
    incomplete,
    piecesWithStats,
  };
}
