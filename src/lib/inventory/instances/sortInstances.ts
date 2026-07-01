import type { ArmorStatName } from "@/data/rules/statBenefits";

import { computeTotalArmorStats } from "./parseArmorStats";
import type { OwnedInstanceDetail } from "./types";

export type ArmorStatSortBy = "total" | ArmorStatName;

export function sortInstancesByPower(instances: OwnedInstanceDetail[]): OwnedInstanceDetail[] {
  return [...instances].sort((a, b) => b.power - a.power);
}

function statSortKey(instance: OwnedInstanceDetail, sortBy: ArmorStatSortBy): number {
  if (instance.statsIncomplete || !instance.statValues) return -1;
  if (sortBy === "total") return instance.totalStats ?? computeTotalArmorStats(instance.statValues);
  return instance.statValues[sortBy] ?? -1;
}

export function sortInstancesByStat(
  instances: OwnedInstanceDetail[],
  sortBy: ArmorStatSortBy,
): OwnedInstanceDetail[] {
  return [...instances].sort((a, b) => {
    const aKey = statSortKey(a, sortBy);
    const bKey = statSortKey(b, sortBy);
    if (aKey !== bKey) return bKey - aKey;

    const aTotal = a.totalStats ?? computeTotalArmorStats(a.statValues);
    const bTotal = b.totalStats ?? computeTotalArmorStats(b.statValues);
    if (aTotal !== bTotal) return bTotal - aTotal;

    if (a.power !== b.power) return b.power - a.power;
    return a.instanceId.localeCompare(b.instanceId);
  });
}

export function sortInstances(
  instances: OwnedInstanceDetail[],
  sortBy?: ArmorStatSortBy,
): OwnedInstanceDetail[] {
  if (sortBy) return sortInstancesByStat(instances, sortBy);
  return sortInstancesByPower(instances);
}
