import { describe, expect, it } from "vitest";

import { stripArmorModStats } from "./stripArmorModStats";

function modMap(
  entries: Array<{ hash: number; statModifiers?: Record<string, number> }>,
) {
  return new Map(entries.map((e) => [e.hash, e]));
}

describe("stripArmorModStats", () => {
  it("returns null when live stats are missing", () => {
    expect(stripArmorModStats(null, [1], modMap([]))).toBeNull();
    expect(stripArmorModStats(undefined, [1], modMap([]))).toBeNull();
  });

  it("returns live stats unchanged when no plugs or no matching mods", () => {
    const live = { Melee: 30, Health: 20 };
    expect(stripArmorModStats(live, [], modMap([{ hash: 1, statModifiers: { Melee: 10 } }]))).toEqual(
      live,
    );
    expect(
      stripArmorModStats(live, [999], modMap([{ hash: 1, statModifiers: { Melee: 10 } }])),
    ).toEqual(live);
  });

  it("subtracts equipped major/minor stat mods", () => {
    const live = {
      Health: 25,
      Melee: 30,
      Grenade: 10,
      Super: 8,
      Class: 12,
      Weapons: 15,
    };
    const mods = modMap([
      { hash: 1030, statModifiers: { Melee: 10 } },
      { hash: 1031, statModifiers: { Health: 5 } },
    ]);
    expect(stripArmorModStats(live, [1030, 1031, 42], mods)).toEqual({
      Health: 20,
      Melee: 20,
      Grenade: 10,
      Super: 8,
      Class: 12,
      Weapons: 15,
    });
  });

  it("clamps at zero when mod delta exceeds live value", () => {
    expect(
      stripArmorModStats(
        { Melee: 5 },
        [1],
        modMap([{ hash: 1, statModifiers: { Melee: 10 } }]),
      ),
    ).toEqual({ Melee: 0 });
  });

  it("treats missing statModifiers on old cache rows as empty", () => {
    const live = { Melee: 30 };
    expect(
      stripArmorModStats(live, [1], modMap([{ hash: 1 }])),
    ).toEqual(live);
  });
});
