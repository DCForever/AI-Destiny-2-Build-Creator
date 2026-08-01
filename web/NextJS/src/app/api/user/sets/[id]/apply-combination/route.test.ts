import { describe, expect, it } from "vitest";

import { applyCombinationBodySchema } from "@/lib/sets/applyCombinationInPlace";

const pieces = [
  { slot: "helmet", itemHash: 1, instanceId: "a" },
  { slot: "arms", itemHash: 2, instanceId: "b" },
  { slot: "chest", itemHash: 3, instanceId: "c" },
  { slot: "legs", itemHash: 4, instanceId: "d" },
  { slot: "class_item", itemHash: 5, instanceId: "e" },
];

describe("POST /api/user/sets/[id]/apply-combination body schema", () => {
  it("accepts a valid pieces payload", () => {
    expect(applyCombinationBodySchema.safeParse({ pieces }).success).toBe(true);
  });

  it("accepts assumed mods and updateLinkedModSet", () => {
    const parsed = applyCombinationBodySchema.safeParse({
      pieces,
      assumedMods: [{ armorSlot: "helmet", itemHash: 900 }],
      updateLinkedModSet: true,
    });
    expect(parsed.success).toBe(true);
  });

  it("rejects an empty pieces array", () => {
    expect(applyCombinationBodySchema.safeParse({ pieces: [] }).success).toBe(false);
  });

  it("rejects an invalid slot", () => {
    const parsed = applyCombinationBodySchema.safeParse({
      pieces: [{ slot: "boots", itemHash: 1, instanceId: "a" }],
    });
    expect(parsed.success).toBe(false);
  });
});
