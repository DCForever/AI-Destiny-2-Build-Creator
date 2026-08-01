import { describe, expect, it } from "vitest";

import { collectGapCandidates } from "./collectGapCandidates";
import type { GapCandidateStores } from "./collectGapCandidates";

const stores: GapCandidateStores = {
  weapons: [
    {
      hash: 10,
      name: "Multimach",
      searchName: "multimach",
      icon: null,
      slot: "Kinetic",
      element: "Kinetic",
      ammo: "Primary",
      frame: "Adaptive Frame",
      itemTypeName: "Submachine Gun",
      originTraitHashes: [99],
      perkColumns: [],
    },
  ],
  exoticWeapons: [
    {
      hash: 20,
      name: "Sunshot",
      searchName: "sunshot",
      icon: null,
      slot: "Energy",
      element: "Solar",
      ammo: "Primary",
      frame: "Adaptive Frame",
      intrinsic: { name: "Sunburn", description: "" },
      catalyst: null,
      flavorText: "",
    },
  ],
  weaponPerks: [
    {
      hash: 30,
      name: "Kill Clip",
      searchName: "kill clip",
      icon: null,
      description: "",
    },
  ],
  originTraits: [
    {
      hash: 99,
      name: "Wild Card",
      searchName: "wild card",
      icon: null,
      description: "",
    },
  ],
  setBonuses: [
    {
      hash: 40,
      name: "Solstice",
      searchName: "solstice",
      icon: null,
      itemHashes: [],
      perks: [
        { requiredCount: 2, name: "Solar Siphon", description: "" },
        { requiredCount: 4, name: "Flame Fuel", description: "" },
      ],
    },
  ],
};

describe("collectGapCandidates", () => {
  it("tags owned weapons and includes manifest weapons for both sources", () => {
    const candidates = collectGapCandidates({
      stores,
      ownedWeaponHashes: [20],
      kinds: ["weapon", "origin_trait", "armor_set_bonus"],
    });

    const sunshot = candidates.find((c) => c.itemHash === 20);
    expect(sunshot?.sources.sort()).toEqual(["manifest", "owned"]);

    const multimach = candidates.find((c) => c.itemHash === 10);
    expect(multimach?.sources).toEqual(["manifest"]);

    expect(candidates.some((c) => c.kind === "origin_trait")).toBe(true);
    expect(
      candidates.filter((c) => c.kind === "armor_set_bonus"),
    ).toHaveLength(2);
  });

  it("does not include weapon perks unless requested", () => {
    const without = collectGapCandidates({
      stores,
      kinds: ["weapon"],
    });
    expect(without.some((c) => c.kind === "weapon_perk")).toBe(false);

    const withPerks = collectGapCandidates({
      stores,
      kinds: ["weapon_perk"],
    });
    expect(withPerks.some((c) => c.perkHash === 30)).toBe(true);
  });
});
