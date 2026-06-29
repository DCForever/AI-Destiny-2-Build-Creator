import { describe, expect, it } from "vitest";

import { suggestSynergies } from "./suggestSynergies";

describe("suggestSynergies", () => {
  it("suggests synergies by type and build tag overlap", () => {
    const available = [
      {
        id: "syn-1",
        userId: 1,
        name: "Melee Combo",
        type: "melee" as const,
        description: "",
        createdAt: "",
        updatedAt: "",
        links: [{ id: "l1", synergyId: "syn-1", kind: "origin_trait", displayName: "Cast No Shadows", itemHash: null, perkHash: null, parentItemHash: null, originTraitName: "Cast No Shadows", originTraitHash: null, armorSetName: null, bonusPieces: null, bonusName: null, armorSetHash: null }],
      },
      {
        id: "syn-2",
        userId: 1,
        name: "Void Grenade",
        type: "grenade" as const,
        description: "",
        createdAt: "",
        updatedAt: "",
        links: [],
      },
    ];

    const results = suggestSynergies({
      build: { subclass: { name: "Sentinel", melee: "Shield" }, tagIds: ["melee"] },
      designatedSynergyIds: [],
      available,
    });

    expect(results[0]?.synergyId).toBe("syn-1");
  });
});
