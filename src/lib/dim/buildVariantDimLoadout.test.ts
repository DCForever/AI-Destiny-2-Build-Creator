import { describe, expect, it } from "vitest";

import { buildVariantDimLoadout } from "@/lib/dim/buildVariantDimLoadout";
import { DIM_STAT_HASHES } from "@/lib/dim/dimLoadout";

describe("buildVariantDimLoadout", () => {
  it("maps combat pins to equipped with instance ids", () => {
    const loadout = buildVariantDimLoadout({
      buildName: "Solar Titan",
      className: "Titan",
      variantName: "Default",
      equipment: {
        primary: {
          slot: "primary",
          itemHash: 111,
          itemName: "Gun",
          source: "set",
          instanceId: "inst-1",
        },
        helmet: {
          slot: "helmet",
          itemHash: 222,
          itemName: "Helm",
          source: "set",
          instanceId: "inst-2",
        },
      },
      artifact: null,
      fashion: null,
      modHashes: [9001],
    });

    expect(loadout.classType).toBe(0);
    expect(loadout.name).toContain("Solar Titan");
    expect(loadout.equipped).toEqual([
      { hash: 111, id: "inst-1" },
      { hash: 222, id: "inst-2" },
    ]);
    expect(loadout.parameters?.mods).toEqual([9001]);
  });

  it("puts fashion in unequipped and omits empty fashion", () => {
    const withFashion = buildVariantDimLoadout({
      buildName: "B",
      className: "Hunter",
      equipment: {},
      artifact: null,
      fashion: {
        setId: "f1",
        slots: { ghost: { itemHash: 55, itemName: "Ghost" } },
      },
      modHashes: [],
    });
    expect(withFashion.unequipped).toEqual([{ hash: 55 }]);

    const empty = buildVariantDimLoadout({
      buildName: "B",
      className: "Hunter",
      equipment: {},
      artifact: null,
      fashion: { setId: "f1", slots: {} },
      modHashes: [],
    });
    expect(empty.unequipped).toEqual([]);
  });

  it("encodes artifact and subclass in notes", () => {
    const loadout = buildVariantDimLoadout({
      buildName: "B",
      className: "Warlock",
      subclass: { name: "Dawnblade", super: "Well of Radiance" },
      equipment: {},
      artifact: { hash: 99, name: "Seasonal", config: [1, 2] },
      fashion: null,
      modHashes: [],
    });
    expect(loadout.notes).toMatch(/Subclass: Dawnblade/);
    expect(loadout.notes).toMatch(/Artifact: Seasonal \(99\)/);
    expect(loadout.notes).toMatch(/unlocks=\[1,2\]/);
  });

  it("maps soft stat targets to DIM constraints", () => {
    const loadout = buildVariantDimLoadout({
      buildName: "B",
      className: "Titan",
      softStatTargets: { Weapons: 100, Health: 70 },
      equipment: {},
      artifact: null,
      fashion: null,
      modHashes: [],
    });
    expect(loadout.parameters?.statConstraints).toEqual([
      { statHash: DIM_STAT_HASHES.Weapons, minStat: 100 },
      { statHash: DIM_STAT_HASHES.Health, minStat: 70 },
    ]);
  });
});
