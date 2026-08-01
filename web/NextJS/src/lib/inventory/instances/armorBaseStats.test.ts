import { describe, expect, it } from "vitest";

import { computeArmorBaseStatsFromPlugs } from "./armorBaseStats";

const GRENADE = 1735777505;
const SUPER = 144602215;
const HEALTH = 392767087;
const MELEE = 4244567218;

describe("computeArmorBaseStatsFromPlugs", () => {
  it("sums armor_stats plugs and ignores mods/mw/tuning", () => {
    const plugs = new Map([
      [
        1,
        {
          plugCategoryIdentifier: "armor_stats",
          investmentStats: [{ statTypeHash: GRENADE, value: 30 }],
        },
      ],
      [
        2,
        {
          plugCategoryIdentifier: "armor_stats",
          investmentStats: [{ statTypeHash: SUPER, value: 25 }],
        },
      ],
      [
        3,
        {
          plugCategoryIdentifier: "armor_stats",
          investmentStats: [{ statTypeHash: HEALTH, value: 20 }],
        },
      ],
      [
        4,
        {
          plugCategoryIdentifier: "enhancements.v2_general",
          investmentStats: [{ statTypeHash: GRENADE, value: 10 }],
        },
      ],
      [
        5,
        {
          plugCategoryIdentifier: "v460.plugs.armor.masterworks",
          investmentStats: [
            { statTypeHash: MELEE, value: 5, isConditionallyActive: true },
          ],
        },
      ],
      [
        6,
        {
          plugCategoryIdentifier:
            "core.gear_systems.armor_tiering.plugs.tuning.mods",
          investmentStats: [
            { statTypeHash: GRENADE, value: 5 },
            { statTypeHash: 1943323491, value: -5 },
          ],
        },
      ],
    ]);

    expect(
      computeArmorBaseStatsFromPlugs([1, 2, 3, 4, 5, 6], (h) => plugs.get(h)),
    ).toEqual({
      Health: 20,
      Melee: 0,
      Grenade: 30,
      Super: 25,
      Class: 0,
      Weapons: 0,
    });
  });

  it("returns null when no armor_stats plugs are present", () => {
    expect(
      computeArmorBaseStatsFromPlugs([1], () => ({
        plugCategoryIdentifier: "enhancements.v2_general",
        investmentStats: [{ statTypeHash: GRENADE, value: 10 }],
      })),
    ).toBeNull();
  });
});
