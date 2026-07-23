import { describe, expect, it } from "vitest";

import { assignAutoStatMods } from "./autoStatMods";
import { ARMOR_OPTIMIZER_SLOTS, type CandidatePiece } from "./types";

function kit(energyCapacity = 10): CandidatePiece[] {
  return ARMOR_OPTIMIZER_SLOTS.map((slot, i) => ({
    slot,
    itemHash: 100 + i,
    instanceId: `${slot}-${i}`,
    isExotic: false,
    statValues: {},
    energyCapacity,
    usedInSets: [],
  }));
}

function totalDelta(mods: ReturnType<typeof assignAutoStatMods>, stat: "Melee") {
  return mods.reduce((sum, mod) => sum + (mod.statDeltas?.[stat] ?? 0), 0);
}

describe("assignAutoStatMods", () => {
  it("returns no mods when thresholds are absent", () => {
    expect(assignAutoStatMods({ pieces: kit(), baseStats: {} })).toEqual([]);
  });

  it("assigns mods toward an unmet threshold", () => {
    const mods = assignAutoStatMods({
      pieces: kit(),
      baseStats: { Melee: 0 },
      thresholds: { Melee: 30 },
    });
    expect(mods.length).toBeGreaterThan(0);
    expect(totalDelta(mods, "Melee")).toBeGreaterThanOrEqual(30);
    for (const mod of mods) {
      expect(mod.energyCost).toBeGreaterThan(0);
      expect(ARMOR_OPTIMIZER_SLOTS).toContain(mod.armorSlot);
    }
  });

  it("adds nothing when the base already meets the threshold", () => {
    const mods = assignAutoStatMods({
      pieces: kit(),
      baseStats: { Melee: 50 },
      thresholds: { Melee: 30 },
    });
    expect(mods).toEqual([]);
  });

  it("never exceeds per-piece energy capacity", () => {
    const mods = assignAutoStatMods({
      pieces: kit(3),
      baseStats: { Melee: 0 },
      thresholds: { Melee: 200 },
    });
    const usedBySlot = new Map<string, number>();
    for (const mod of mods) {
      usedBySlot.set(mod.armorSlot, (usedBySlot.get(mod.armorSlot) ?? 0) + mod.energyCost);
    }
    for (const used of usedBySlot.values()) expect(used).toBeLessThanOrEqual(3);
  });

  it("prioritizes the higher-priority stat when energy is scarce", () => {
    const mods = assignAutoStatMods({
      pieces: [
        {
          slot: "helmet",
          itemHash: 1,
          instanceId: "h",
          isExotic: false,
          statValues: {},
          energyCapacity: 3,
          usedInSets: [],
        },
      ],
      baseStats: { Melee: 0, Grenade: 0 },
      thresholds: { Melee: 100, Grenade: 100 },
      priorities: ["Grenade", "Melee"],
    });
    expect(mods.every((mod) => (mod.statDeltas?.Grenade ?? 0) > 0)).toBe(true);
  });
});
