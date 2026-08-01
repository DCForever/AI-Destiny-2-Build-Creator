import { describe, expect, it } from "vitest";

import { pickFirstName, pickNames, subclassKitFromCatalogHits } from "./createSubclassKit";

describe("createSubclassKit", () => {
  it("picks first distinct catalog names", () => {
    expect(pickFirstName([{ name: "Needlestorm" }, { name: "Silkstrike" }])).toBe(
      "Needlestorm",
    );
    expect(pickNames([{ name: "A" }, { name: "A" }, { name: "B" }, { name: "C" }], 2)).toEqual([
      "A",
      "B",
    ]);
  });

  it("builds a Broodweaver kit from catalog hits without Sunbreaker leftovers", () => {
    const kit = subclassKitFromCatalogHits({
      subclassName: "Broodweaver",
      pinnedSuper: "Needlestorm",
      abilitiesByKind: {
        super: [{ name: "Needlestorm" }],
        classAbility: [{ name: "Healing Rift" }],
        movement: [{ name: "Strafe Glide" }],
        melee: [{ name: "Arcane Needle" }],
        grenade: [{ name: "Threadling Grenade" }],
      },
      aspects: [
        { name: "Drengr's Lash", classType: "Titan" },
        { name: "Weaver's Call", classType: "Warlock" },
        { name: "Mindspun Invocation", classType: "Warlock" },
        { name: "Empty Aspect Socket" },
      ],
      fragments: [
        { name: "Empty Fragment Socket" },
        { name: "Thread of Generation" },
        { name: "Thread of Mind" },
      ],
    });

    expect(kit.name).toBe("Broodweaver");
    expect(kit.super).toBe("Needlestorm");
    expect(kit.melee).toBe("Arcane Needle");
    expect(kit.aspects).toEqual(["Weaver's Call", "Mindspun Invocation"]);
    expect(kit.fragments).toEqual(["Thread of Generation", "Thread of Mind"]);
    expect(kit.aspects.join(" ")).not.toMatch(/Roaring|Sol Invictus|Drengr/);
    expect(kit.melee).not.toBe("Consecration");
  });
});
