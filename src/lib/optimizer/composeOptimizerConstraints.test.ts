import { describe, expect, it } from "vitest";

import { composeOptimizerConstraints } from "./composeOptimizerConstraints";
import { armorSetOptimizerConstraintsSchema } from "./types";

describe("composeOptimizerConstraints", () => {
  it("seeds exotic and soft targets like seedConstraintsFromBuild", () => {
    const c = composeOptimizerConstraints({
      seed: {
        exoticArmorHash: 42,
        softStatTargets: { Melee: 100, Grenade: 70 },
      },
    });
    expect(c.lockedExoticItemHash).toBe(42);
    expect(c.statThresholds?.Melee).toBe(100);
    expect(c.statThresholds?.Grenade).toBe(70);
    expect(c.setBonusGoals).toEqual([]);
    expect(c.includeModEstimates).toBe(true);
    expect(c.preferReuse).toBe(false);
    expect(armorSetOptimizerConstraintsSchema.safeParse(c).success).toBe(true);
  });

  it("merges user set-bonus goals and toggles", () => {
    const c = composeOptimizerConstraints({
      seed: { exoticArmorHash: null },
      setBonusGoals: [
        { setBonusKey: "two-piece", minPieces: 2 },
        { setBonusKey: "two-piece", minPieces: 4 },
        { setBonusKey: "lucerne", minPieces: 2 },
      ],
      preferReuse: true,
      includeModEstimates: false,
    });
    expect(c.setBonusGoals).toEqual([
      { setBonusKey: "two-piece", minPieces: 4 },
      { setBonusKey: "lucerne", minPieces: 2 },
    ]);
    expect(c.preferReuse).toBe(true);
    expect(c.includeModEstimates).toBe(false);
    expect(armorSetOptimizerConstraintsSchema.safeParse(c).success).toBe(true);
  });
});
