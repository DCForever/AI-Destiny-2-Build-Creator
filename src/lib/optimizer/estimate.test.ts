import { describe, expect, it } from "vitest";

import { applyModDeltas, estimateCombinationStats } from "./estimate";
import { ARMOR_OPTIMIZER_SLOTS, type AssumedMod, type CandidatePiece } from "./types";

function kit(): CandidatePiece[] {
  return ARMOR_OPTIMIZER_SLOTS.map((slot, i) => ({
    slot,
    itemHash: 100 + i,
    instanceId: `${slot}-${i}`,
    isExotic: false,
    statValues: { Melee: 4 },
    energyCapacity: 10,
    usedInSets: [],
  }));
}

describe("applyModDeltas", () => {
  it("adds assumed-mod stat deltas onto the base totals", () => {
    const mods: AssumedMod[] = [
      { armorSlot: "helmet", itemHash: 1, energyCost: 3, statDeltas: { Melee: 10 } },
    ];
    expect(applyModDeltas({ Melee: 20 }, mods)).toEqual({ Melee: 30 });
  });
});

describe("estimateCombinationStats", () => {
  it("returns base stats with no mods when estimates are disabled", () => {
    const result = estimateCombinationStats({
      kit: kit(),
      thresholds: { Melee: 100 },
      includeModEstimates: false,
    });
    expect(result.assumedMods).toEqual([]);
    expect(result.estimatedStats.Melee).toBe(20);
  });

  it("boosts estimates with assumed mods toward the threshold when enabled", () => {
    const result = estimateCombinationStats({
      kit: kit(),
      thresholds: { Melee: 60 },
      includeModEstimates: true,
    });
    expect(result.assumedMods.length).toBeGreaterThan(0);
    expect(result.estimatedStats.Melee ?? 0).toBeGreaterThanOrEqual(60);
    expect(result.baseStats.Melee).toBe(20);
  });
});
