import { describe, expect, it, vi } from "vitest";

import { searchSynergyLinkPickerItems } from "@/lib/synergies/synergyPickerLinks";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async (store: string) => {
        if (store === "origin-traits") {
          return [
            {
              hash: 9001,
              name: "Cast No Shadows",
              searchName: "cast no shadows",
              description: "Melee synergy trait.",
              icon: null,
            },
          ];
        }
        if (store === "weapon-perks") {
          return [
            {
              hash: 7001,
              name: "Incandescent",
              searchName: "incandescent",
              description: "Scorch on defeat.",
              icon: null,
            },
          ];
        }
        if (store === "set-bonuses") {
          return [
            {
              hash: 8001,
              name: "Eutechnology",
              searchName: "eutechnology",
              icon: null,
              perks: [{ requiredCount: 2, name: "Gift of the Ley Lines", description: "Void buff." }],
              itemHashes: [],
            },
          ];
        }
        return [];
      }),
    },
  })),
}));

describe("searchSynergyLinkPickerItems", () => {
  it("returns origin traits with description", async () => {
    const items = await searchSynergyLinkPickerItems("origin_trait", "cast", 10);
    expect(items[0]?.originTraitName).toBe("Cast No Shadows");
    expect(items[0]?.description).toContain("Melee");
  });

  it("returns weapon perks", async () => {
    const items = await searchSynergyLinkPickerItems("weapon_perk", "inca", 10);
    expect(items[0]?.perkHash).toBe(7001);
  });

  it("returns flattened armor set bonuses", async () => {
    const items = await searchSynergyLinkPickerItems("armor_set_bonus", "", 10);
    expect(items[0]?.bonusPieces).toBe(2);
    expect(items[0]?.bonusName).toBe("Gift of the Ley Lines");
  });

  it("matches armor set bonuses by perk name when set name does not match", async () => {
    const items = await searchSynergyLinkPickerItems("armor_set_bonus", "gift", 10);
    expect(items[0]?.bonusName).toBe("Gift of the Ley Lines");
    expect(items[0]?.armorSetName).toBe("Eutechnology");
  });
});
