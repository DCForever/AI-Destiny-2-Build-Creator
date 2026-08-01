import { describe, expect, it } from "vitest";

import { armorOptimizeBodySchema } from "@/lib/optimizer/optimizeArmorBody";

describe("POST /api/user/armor/optimize body schema", () => {
  it("accepts a minimal body with classType", () => {
    const parsed = armorOptimizeBodySchema.safeParse({ classType: "Titan" });
    expect(parsed.success).toBe(true);
  });

  it("accepts buildId without classType", () => {
    const parsed = armorOptimizeBodySchema.safeParse({ buildId: "build-1" });
    expect(parsed.success).toBe(true);
  });

  it("rejects when neither classType nor buildId is present", () => {
    const parsed = armorOptimizeBodySchema.safeParse({ preferReuse: true });
    expect(parsed.success).toBe(false);
  });

  it("accepts full constraint payload", () => {
    const parsed = armorOptimizeBodySchema.safeParse({
      classType: "Hunter",
      lockedExoticItemHash: 555,
      requireExotic: true,
      setBonusGoals: [{ setBonusKey: "TechSec", minPieces: 2 }],
      statPriorities: ["Melee", "Health"],
      statThresholds: { Melee: 100 },
      requireThresholds: true,
      preferReuse: true,
      maxResults: 25,
    });
    expect(parsed.success).toBe(true);
  });

  it("rejects maxResults above 50", () => {
    const parsed = armorOptimizeBodySchema.safeParse({ classType: "Titan", maxResults: 51 });
    expect(parsed.success).toBe(false);
  });

  it("rejects unknown stat names in priorities", () => {
    const parsed = armorOptimizeBodySchema.safeParse({
      classType: "Titan",
      statPriorities: ["Mobility"],
    });
    expect(parsed.success).toBe(false);
  });

  it("rejects invalid minPieces in set-bonus goals", () => {
    const parsed = armorOptimizeBodySchema.safeParse({
      classType: "Warlock",
      setBonusGoals: [{ setBonusKey: "TechSec", minPieces: 3 }],
    });
    expect(parsed.success).toBe(false);
  });
});
