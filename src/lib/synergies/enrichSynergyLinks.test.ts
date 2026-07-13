import { beforeEach, describe, expect, it, vi } from "vitest";

import { enrichSynergyLinks } from "./enrichSynergyLinks";

const getStore = vi.fn();

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore },
  })),
}));

describe("enrichSynergyLinks", () => {
  beforeEach(() => {
    getStore.mockReset();
    getStore.mockImplementation(async (store: string) => {
      if (store === "weapons") {
        return [
          {
            hash: 100,
            name: "Test Gun",
            icon: "/gun.png",
            itemTypeName: "Auto Rifle",
            frame: "Adaptive Frame",
          },
        ];
      }
      if (store === "exotic-weapons") {
        return [
          {
            hash: 101,
            name: "Sunshot",
            icon: "/sunshot.png",
            intrinsic: {
              name: "Sunburn",
              description: "Targets explode and Scorch nearby foes.",
            },
            catalyst: {
              name: "Catalyst",
              description: "Faster reload while Amplified.",
            },
          },
        ];
      }
      if (store === "weapon-perks") {
        return [
          {
            hash: 200,
            name: "Slideways",
            description: "Sliding reloads this weapon.",
          },
        ];
      }
      if (store === "origin-traits") {
        return [
          {
            hash: 9001,
            name: "Cast No Shadows",
            description: "Grants invisibility after a kill.",
          },
        ];
      }
      if (store === "set-bonuses") {
        return [
          {
            hash: 8001,
            name: "Eutechnology",
            perks: [
              {
                requiredCount: 2,
                name: "Gift of the Ley Lines",
                description: "Orbs of Power grant ability energy.",
              },
            ],
          },
        ];
      }
      return [];
    });
  });

  it("attaches descriptions for each link kind", async () => {
    const enriched = await enrichSynergyLinks([
      {
        id: "1",
        synergyId: "s",
        kind: "weapon",
        displayName: "Test Gun",
        itemHash: 100,
        perkHash: null,
        parentItemHash: null,
        originTraitName: null,
        originTraitHash: null,
        armorSetName: null,
        bonusPieces: null,
        bonusName: null,
        armorSetHash: null,
      },
      {
        id: "2",
        synergyId: "s",
        kind: "weapon_perk",
        displayName: "Slideways",
        itemHash: null,
        perkHash: 200,
        parentItemHash: null,
        originTraitName: null,
        originTraitHash: null,
        armorSetName: null,
        bonusPieces: null,
        bonusName: null,
        armorSetHash: null,
      },
      {
        id: "3",
        synergyId: "s",
        kind: "origin_trait",
        displayName: "Cast No Shadows",
        itemHash: null,
        perkHash: null,
        parentItemHash: null,
        originTraitName: "Cast No Shadows",
        originTraitHash: 9001,
        armorSetName: null,
        bonusPieces: null,
        bonusName: null,
        armorSetHash: null,
      },
      {
        id: "4",
        synergyId: "s",
        kind: "armor_set_bonus",
        displayName: "Eutechnology 2pc",
        itemHash: null,
        perkHash: null,
        parentItemHash: null,
        originTraitName: null,
        originTraitHash: null,
        armorSetName: "Eutechnology",
        bonusPieces: 2,
        bonusName: "Gift of the Ley Lines",
        armorSetHash: 8001,
      },
    ]);

    expect(enriched[0]?.description).toBe("Auto Rifle · Adaptive Frame");
    expect(enriched[0]?.icon).toBe("/gun.png");
    expect(enriched[1]?.description).toBe("Sliding reloads this weapon.");
    expect(enriched[2]?.description).toBe("Grants invisibility after a kill.");
    expect(enriched[3]?.description).toBe("Orbs of Power grant ability energy.");

    const exoticOnly = await enrichSynergyLinks([
      {
        id: "5",
        synergyId: "s",
        kind: "weapon",
        displayName: "Sunshot",
        itemHash: 101,
        perkHash: null,
        parentItemHash: null,
        originTraitName: null,
        originTraitHash: null,
        armorSetName: null,
        bonusPieces: null,
        bonusName: null,
        armorSetHash: null,
      },
    ]);
    expect(exoticOnly[0]?.description).toBe(
      "Targets explode and Scorch nearby foes.",
    );
    expect(exoticOnly[0]?.icon).toBe("/sunshot.png");
  });

  it("returns empty description when catalog miss", async () => {
    const enriched = await enrichSynergyLinks([
      {
        id: "1",
        synergyId: "s",
        kind: "weapon",
        displayName: "Missing",
        itemHash: 999,
        perkHash: null,
        parentItemHash: null,
        originTraitName: null,
        originTraitHash: null,
        armorSetName: null,
        bonusPieces: null,
        bonusName: null,
        armorSetHash: null,
      },
    ]);
    expect(enriched[0]?.description).toBe("");
  });
});
