import { describe, expect, it } from "vitest";

import {
  compareCombinations,
  estimateKitStats,
  isEstimateIncomplete,
  meetsSoftThresholds,
  sumPrioritizedStats,
} from "./score";
import { ARMOR_OPTIMIZER_SLOTS, type CandidatePiece } from "./types";

function kit(perPiece: Partial<Record<string, number>>[]): CandidatePiece[] {
  return ARMOR_OPTIMIZER_SLOTS.map((slot, i) => ({
    slot,
    itemHash: 100 + i,
    instanceId: `${slot}`,
    isExotic: false,
    statValues: perPiece[i] ?? {},
    energyCapacity: 10,
    usedInSets: [],
  }));
}

describe("score", () => {
  it("sums each stat across pieces", () => {
    const pieces = kit([{ Melee: 10 }, { Melee: 5, Health: 8 }, {}, {}, {}]);
    const stats = estimateKitStats(pieces);
    expect(stats.Melee).toBe(15);
    expect(stats.Health).toBe(8);
  });

  it("sums prioritized stats only when priorities provided", () => {
    const stats = { Melee: 30, Health: 20, Super: 10 };
    expect(sumPrioritizedStats(stats, ["Melee", "Health"])).toBe(50);
    expect(sumPrioritizedStats(stats, [])).toBe(60);
  });

  it("orders lexicographically by priority stats", () => {
    const a = { estimatedStats: { Melee: 30, Health: 10 }, reusePieceCount: 0 };
    const b = { estimatedStats: { Melee: 20, Health: 99 }, reusePieceCount: 0 };
    expect(compareCombinations(a, b, ["Melee", "Health"], false)).toBeLessThan(0);
  });

  it("breaks priority ties by total stats", () => {
    const a = { estimatedStats: { Melee: 20, Health: 40 }, reusePieceCount: 0 };
    const b = { estimatedStats: { Melee: 20, Health: 10 }, reusePieceCount: 0 };
    expect(compareCombinations(a, b, ["Melee"], false)).toBeLessThan(0);
  });

  it("only uses reuse as a tie-break when preferReuse is set", () => {
    const a = { estimatedStats: { Melee: 20 }, reusePieceCount: 0 };
    const b = { estimatedStats: { Melee: 20 }, reusePieceCount: 3 };
    expect(compareCombinations(a, b, ["Melee"], false)).toBe(0);
    expect(compareCombinations(a, b, ["Melee"], true)).toBeGreaterThan(0);
  });

  it("evaluates soft thresholds", () => {
    expect(meetsSoftThresholds({ Melee: 100 }, { Melee: 100 })).toBe(true);
    expect(meetsSoftThresholds({ Melee: 90 }, { Melee: 100 })).toBe(false);
    expect(meetsSoftThresholds({ Melee: 90 }, undefined)).toBe(true);
  });

  it("marks estimate incomplete when a piece lacks all six stats", () => {
    const complete = kit([
      { Health: 1, Melee: 1, Grenade: 1, Super: 1, Class: 1, Weapons: 1 },
      { Health: 1, Melee: 1, Grenade: 1, Super: 1, Class: 1, Weapons: 1 },
      { Health: 1, Melee: 1, Grenade: 1, Super: 1, Class: 1, Weapons: 1 },
      { Health: 1, Melee: 1, Grenade: 1, Super: 1, Class: 1, Weapons: 1 },
      { Health: 1, Melee: 1, Grenade: 1, Super: 1, Class: 1, Weapons: 1 },
    ]);
    expect(isEstimateIncomplete(complete)).toBe(false);
    expect(isEstimateIncomplete(kit([{ Melee: 5 }]))).toBe(true);
  });
});
