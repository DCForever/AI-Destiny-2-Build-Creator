import { describe, expect, it } from "vitest";

import { sumArmorSetStats } from "./sumArmorSetStats";

describe("sumArmorSetStats", () => {
  it("sums six stats across pieces", () => {
    const result = sumArmorSetStats([
      {
        instanceId: "a",
        statValues: {
          Health: 20,
          Melee: 10,
          Grenade: 10,
          Super: 10,
          Class: 10,
          Weapons: 12,
        },
      },
      {
        instanceId: "b",
        statValues: {
          Health: 15,
          Melee: 15,
          Grenade: 10,
          Super: 10,
          Class: 10,
          Weapons: 10,
        },
      },
    ]);
    expect(result.statValues.Health).toBe(35);
    expect(result.statValues.Weapons).toBe(22);
    expect(result.grandTotal).toBe(35 + 25 + 20 + 20 + 20 + 22);
    expect(result.piecesWithStats).toBe(2);
    expect(result.incomplete).toBe(false);
  });

  it("flags incomplete when pinned piece lacks stats", () => {
    const result = sumArmorSetStats([
      {
        instanceId: "a",
        statValues: {
          Health: 20,
          Melee: 10,
          Grenade: 10,
          Super: 10,
          Class: 10,
          Weapons: 10,
        },
      },
      { instanceId: "b" },
    ]);
    expect(result.incomplete).toBe(true);
    expect(result.piecesWithStats).toBe(1);
  });

  it("ignores wishlist pieces without instance", () => {
    const result = sumArmorSetStats([
      { instanceId: null },
      {
        instanceId: "a",
        statsIncomplete: true,
        statValues: { Health: 10, Melee: 10 },
      },
    ]);
    expect(result.piecesWithStats).toBe(1);
    expect(result.incomplete).toBe(true);
  });
});
