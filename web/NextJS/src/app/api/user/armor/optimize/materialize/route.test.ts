import { describe, expect, it } from "vitest";

import { materializeCombinationBodySchema } from "@/lib/sets/materializeCombination";

const validPieces = [
  { slot: "helmet", itemHash: 1, instanceId: "a" },
  { slot: "arms", itemHash: 2, instanceId: "b" },
  { slot: "chest", itemHash: 3, instanceId: "c" },
  { slot: "legs", itemHash: 4, instanceId: "d" },
  { slot: "class_item", itemHash: 5, instanceId: "e" },
];

const baseConstraints = { setBonusGoals: [], statPriorities: ["Melee"] };

describe("POST /api/user/armor/optimize/materialize body schema", () => {
  it("accepts a minimal valid body", () => {
    const parsed = materializeCombinationBodySchema.safeParse({
      pieces: validPieces,
      constraints: baseConstraints,
      armorSetName: "Kit",
    });
    expect(parsed.success).toBe(true);
  });

  it("rejects a missing set name", () => {
    const parsed = materializeCombinationBodySchema.safeParse({
      pieces: validPieces,
      constraints: baseConstraints,
    });
    expect(parsed.success).toBe(false);
  });

  it("rejects an invalid slot name", () => {
    const parsed = materializeCombinationBodySchema.safeParse({
      pieces: [{ slot: "boots", itemHash: 1, instanceId: "a" }],
      constraints: baseConstraints,
      armorSetName: "Kit",
    });
    expect(parsed.success).toBe(false);
  });

  it("accepts assumed mods and attach fields", () => {
    const parsed = materializeCombinationBodySchema.safeParse({
      pieces: validPieces,
      assumedMods: [{ armorSlot: "helmet", itemHash: 900 }],
      constraints: baseConstraints,
      armorSetName: "Kit",
      createModSet: true,
      attachNow: true,
      buildId: "b1",
      variantId: "v1",
    });
    expect(parsed.success).toBe(true);
  });
});
