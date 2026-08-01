import { describe, expect, it } from "vitest";

import { FIXTURE_SET_EUTECHNOLOGY } from "./__fixtures__/setLookupFixtures";
import { buildLegendaryArmorRows } from "./legendaryArmor";

describe("buildLegendaryArmorRows", () => {
  it("projects set member hashes with set bonus metadata", () => {
    const rows = buildLegendaryArmorRows([FIXTURE_SET_EUTECHNOLOGY], (hash) => {
      if (hash === 9001) {
        return {
          name: "Eutech Helm",
          searchName: "eutech helm",
          icon: null,
          slot: "Helmet",
          classType: "Warlock",
        };
      }
      if (hash === 9002) {
        return {
          name: "Eutech Gloves",
          searchName: "eutech gloves",
          icon: null,
          slot: "Gauntlets",
          classType: "Warlock",
        };
      }
      return null;
    });

    expect(rows).toHaveLength(2);
    expect(rows[0]).toMatchObject({
      hash: 9001,
      setBonusName: "Eutechnology",
      setBonusHash: 8001,
      setBonusIcon: null,
      setBonusPerks: [
        { requiredCount: 2, name: "Gift of the Ley Lines", description: "2pc" },
        { requiredCount: 4, name: "Techeun's Foresight", description: "4pc" },
      ],
      slot: "Helmet",
    });
  });

  it("skips hashes that cannot be projected", () => {
    const rows = buildLegendaryArmorRows([FIXTURE_SET_EUTECHNOLOGY], () => null);
    expect(rows).toHaveLength(0);
  });
});
