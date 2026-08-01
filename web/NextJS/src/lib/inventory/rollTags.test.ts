import { describe, expect, it } from "vitest";

import type { WeaponRecord } from "@/lib/manifest/types/records";

import { computeRollTags } from "./rollTags";

function weapon(overrides: Partial<WeaponRecord> = {}): WeaponRecord {
  return {
    hash: 100,
    name: "Test Weapon",
    searchName: "test weapon",
    icon: null,
    slot: "Kinetic",
    element: "Kinetic",
    ammo: "Primary",
    frame: "Adaptive Frame",
    itemTypeName: "Hand Cannon",
    originTraitHashes: [],
    perkColumns: [],
    ...overrides,
  };
}

describe("computeRollTags", () => {
  const perkMap = new Map<number, string>([
    [1, "Pugilist"],
    [2, "Swashbuckler"],
    [3, "Demolitionist"],
    [4, "Adrenaline Junkie"],
    [5, "Anti-Barrier Rounds"],
    [6, "Firefly"],
  ]);

  it("tags MeleeBuildCandidate for Hand Cannon with Pugilist + Swashbuckler", () => {
    const tags = computeRollTags([1, 2], perkMap, weapon());
    expect(tags).toContain("MeleeBuildCandidate");
  });

  it("does not tag MeleeBuildCandidate without both perks", () => {
    const tags = computeRollTags([1, 6], perkMap, weapon());
    expect(tags).not.toContain("MeleeBuildCandidate");
  });

  it("tags OrbitBuild for Demolitionist + Adrenaline Junkie", () => {
    const tags = computeRollTags([3, 4], perkMap, weapon({ itemTypeName: "Auto Rifle" }));
    expect(tags).toContain("OrbitBuild");
  });

  it("tags Crafted when isCrafted option is set", () => {
    const tags = computeRollTags([], perkMap, null, { isCrafted: true });
    expect(tags).toEqual(["Crafted"]);
  });

  it("tags champion counter from weapon frame", () => {
    const tags = computeRollTags([], perkMap, weapon({ frame: "Adaptive Frame", itemTypeName: "Scout Rifle" }));
    expect(tags).toContain("ChampionBarrier");
  });

  it("tags champion counter from perk name", () => {
    const tags = computeRollTags([5], perkMap);
    expect(tags).toContain("ChampionBarrier");
  });
});
