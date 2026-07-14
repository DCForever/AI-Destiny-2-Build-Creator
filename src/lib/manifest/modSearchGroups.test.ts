import { describe, expect, it } from "vitest";

import {
  classifyModFunction,
  dedupeModVariantsByNameAndSlot,
  groupAndSortModSearchResults,
  modSlotCategoryLabel,
} from "./modSearchGroups";

describe("classifyModFunction", () => {
  it("classifies ammo finders", () => {
    expect(classifyModFunction("Heavy Ammo Finder", "")).toBe("ammo");
    expect(
      classifyModFunction(
        "Heavy Ammo Finder",
        "Primary ammo weapon final blows help you find ammo more quickly.",
      ),
    ).toBe("ammo");
  });

  it("classifies armor charge / surge", () => {
    expect(
      classifyModFunction(
        "Kinetic Weapon Surge",
        "Collecting an Orb of Power causes you to gain 1 temporary Armor Charge.",
      ),
    ).toBe("armorCharge");
  });

  it("classifies weapons loaders", () => {
    expect(classifyModFunction("Strand Loader", "")).toBe("weapons");
  });

  it("classifies siphon", () => {
    expect(classifyModFunction("Solar Siphon", "")).toBe("siphon");
  });

  it("classifies deprecated", () => {
    expect(
      classifyModFunction(
        "Class Mod",
        "This mod has been deprecated and no longer functions.",
      ),
    ).toBe("deprecated");
  });
});

describe("groupAndSortModSearchResults", () => {
  const sample = [
    {
      hash: 1,
      name: "Zulu Loader",
      description: "Faster reload",
      slotCategory: "arms",
      energyCost: 2,
    },
    {
      hash: 2,
      name: "Alpha Loader",
      description: "Faster reload",
      slotCategory: "arms",
      energyCost: 1,
    },
    {
      hash: 3,
      name: "Heavy Ammo Finder",
      description: "Find heavy ammo",
      slotCategory: "helmet",
      energyCost: 1,
    },
    {
      hash: 4,
      name: "Chest Resistance",
      description: "Damage resistance",
      slotCategory: "chest",
      energyCost: 1,
    },
    {
      hash: 5,
      name: "Empty Mod Socket",
      description: "No mod currently selected.",
      slotCategory: "legs",
      energyCost: null,
    },
  ];

  it("groups by function and hides deprecated by default", () => {
    const groups = groupAndSortModSearchResults(sample);
    expect(groups.map((g) => g.key)).toEqual(["ammo", "weapons", "defense"]);
    expect(groups.every((g) => g.key !== "deprecated")).toBe(true);
  });

  it("sorts within group by energy then name", () => {
    const groups = groupAndSortModSearchResults(sample);
    const weapons = groups.find((g) => g.key === "weapons")!;
    expect(weapons.items.map((i) => i.name)).toEqual([
      "Alpha Loader",
      "Zulu Loader",
    ]);
  });

  it("keeps only piece-legal mods when target armor slot is set", () => {
    const groups = groupAndSortModSearchResults(
      [
        {
          hash: 10,
          name: "Arms Resist",
          description: "Damage resistance",
          slotCategory: "arms",
          energyCost: 1,
        },
        {
          hash: 11,
          name: "Helmet Resist",
          description: "Damage resistance",
          slotCategory: "helmet",
          energyCost: 1,
        },
        {
          hash: 12,
          name: "General Resist",
          description: "Damage resistance",
          slotCategory: "general",
          energyCost: 2,
        },
      ],
      { targetArmorSlot: "helmet" },
    );
    const defense = groups.find((g) => g.key === "defense")!;
    // Arms-only excluded; helmet + general remain (energy then name)
    expect(defense.items.map((i) => i.name)).toEqual([
      "Helmet Resist",
      "General Resist",
    ]);
  });

  it("can still show illegal mods when onlyLegalForSlot is false", () => {
    const groups = groupAndSortModSearchResults(
      [
        {
          hash: 10,
          name: "Arms Resist",
          description: "Damage resistance",
          slotCategory: "arms",
          energyCost: 1,
        },
        {
          hash: 11,
          name: "Helmet Resist",
          description: "Damage resistance",
          slotCategory: "helmet",
          energyCost: 1,
        },
      ],
      { targetArmorSlot: "helmet", onlyLegalForSlot: false },
    );
    const defense = groups.find((g) => g.key === "defense")!;
    expect(defense.items.map((i) => i.name)).toEqual([
      "Helmet Resist",
      "Arms Resist",
    ]);
  });
});

describe("modSlotCategoryLabel", () => {
  it("labels categories", () => {
    expect(modSlotCategoryLabel("general")).toBe("Any armor");
    expect(modSlotCategoryLabel("classItem")).toBe("Class item");
  });
});

describe("dedupeModVariantsByNameAndSlot", () => {
  it("keeps higher energy cost for same name and slot", () => {
    const kept = dedupeModVariantsByNameAndSlot([
      {
        hash: 1,
        name: "Focusing Strike",
        slotCategory: "arms",
        energyCost: 1,
      },
      {
        hash: 2,
        name: "Focusing Strike",
        slotCategory: "arms",
        energyCost: 2,
      },
      {
        hash: 3,
        name: "Heavy Ammo Finder",
        slotCategory: "helmet",
        energyCost: 1,
      },
      {
        hash: 4,
        name: "Heavy Ammo Finder",
        slotCategory: "helmet",
        energyCost: 3,
      },
    ]);
    expect(kept).toHaveLength(2);
    expect(kept.find((m) => m.name === "Focusing Strike")?.energyCost).toBe(2);
    expect(kept.find((m) => m.name === "Heavy Ammo Finder")?.energyCost).toBe(3);
  });

  it("keeps same name on different armor slots", () => {
    const kept = dedupeModVariantsByNameAndSlot([
      { hash: 1, name: "Something", slotCategory: "helmet", energyCost: 1 },
      { hash: 2, name: "Something", slotCategory: "arms", energyCost: 1 },
    ]);
    expect(kept).toHaveLength(2);
  });
});
