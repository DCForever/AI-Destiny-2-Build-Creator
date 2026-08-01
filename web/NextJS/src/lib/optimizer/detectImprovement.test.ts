import { describe, expect, it } from "vitest";

import { detectImprovement } from "./detectImprovement";

describe("detectImprovement", () => {
  it("is true when the candidate ranks lexicographically above current", () => {
    const better = detectImprovement(
      { estimatedStats: { Melee: 50 }, reusePieceCount: 0 },
      { estimatedStats: { Melee: 60 }, reusePieceCount: 0 },
      ["Melee"],
      false,
    );
    expect(better).toBe(true);
  });

  it("is false when the candidate equals current", () => {
    const better = detectImprovement(
      { estimatedStats: { Melee: 60 }, reusePieceCount: 0 },
      { estimatedStats: { Melee: 60 }, reusePieceCount: 0 },
      ["Melee"],
      false,
    );
    expect(better).toBe(false);
  });

  it("is false when the candidate is worse on the priority stat", () => {
    const better = detectImprovement(
      { estimatedStats: { Melee: 70 }, reusePieceCount: 0 },
      { estimatedStats: { Melee: 60, Health: 100 }, reusePieceCount: 0 },
      ["Melee"],
      false,
    );
    expect(better).toBe(false);
  });

  it("breaks equal-stat ties on reuse only when preferReuse is set", () => {
    const current = { estimatedStats: { Melee: 60 }, reusePieceCount: 0 };
    const candidate = { estimatedStats: { Melee: 60 }, reusePieceCount: 3 };
    expect(detectImprovement(current, candidate, ["Melee"], false)).toBe(false);
    expect(detectImprovement(current, candidate, ["Melee"], true)).toBe(true);
  });
});
