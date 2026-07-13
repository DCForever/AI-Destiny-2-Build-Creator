import { describe, expect, it } from "vitest";

import {
  linkDedupeKey,
  mergeSynergyDescriptions,
  sameSynergyDesignation,
  unionSynergyLinks,
} from "./mergeSynergies";

describe("unionSynergyLinks", () => {
  it("unions and dedupes by coverage key, survivor order first", () => {
    const merged = unionSynergyLinks([
      [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitHash: 9001,
          originTraitName: "Cast No Shadows",
        },
      ],
      [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitHash: 9001,
          originTraitName: "Cast No Shadows",
        },
        {
          kind: "weapon",
          displayName: "Sunshot",
          itemHash: 42,
        },
      ],
    ]);
    expect(merged).toHaveLength(2);
    expect(merged[0]?.kind).toBe("origin_trait");
    expect(merged[1]?.kind).toBe("weapon");
    expect(merged[1]?.itemHash).toBe(42);
  });
});

describe("mergeSynergyDescriptions", () => {
  it("joins unique descriptions and skips empties", () => {
    expect(mergeSynergyDescriptions(["First note", "", "First note", "Second"])).toBe(
      "First note\n\nSecond",
    );
  });
});

describe("sameSynergyDesignation", () => {
  it("treats verb aliases as the same designation", () => {
    expect(
      sameSynergyDesignation(
        { type: "verb", subType: "Firesprite" },
        { type: "verb", subType: "Solar Firesprite" },
      ),
    ).toBe(true);
    expect(
      sameSynergyDesignation(
        { type: "verb", subType: "Scorch" },
        { type: "verb", subType: "Jolt" },
      ),
    ).toBe(false);
    expect(
      sameSynergyDesignation(
        { type: "melee", subType: "Base" },
        { type: "verb", subType: "Base" },
      ),
    ).toBe(false);
  });
});

describe("linkDedupeKey", () => {
  it("keys weapons by hash", () => {
    expect(linkDedupeKey({ kind: "weapon", displayName: "X", itemHash: 1 })).toBe(
      "weapon:1",
    );
  });
});
