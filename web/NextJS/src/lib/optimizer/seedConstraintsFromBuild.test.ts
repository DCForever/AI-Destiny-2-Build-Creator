import { describe, expect, it } from "vitest";

import { seedConstraintsFromBuild } from "./seedConstraintsFromBuild";

describe("seedConstraintsFromBuild", () => {
  it("seeds exotic and empty set-bonus goals", () => {
    const c = seedConstraintsFromBuild({ exoticArmorHash: 99, softStatTargets: null });
    expect(c.lockedExoticItemHash).toBe(99);
    expect(c.setBonusGoals).toEqual([]);
    expect(c.preferReuse).toBe(false);
  });

  it("orders priorities by soft-stat target descending", () => {
    const c = seedConstraintsFromBuild({
      exoticArmorHash: null,
      softStatTargets: { Melee: 120, Health: 80 },
    });
    expect(c.statThresholds?.Melee).toBe(120);
    expect(c.statPriorities?.[0]).toBe("Melee");
    expect(c.statPriorities?.includes("Health")).toBe(true);
  });
});
