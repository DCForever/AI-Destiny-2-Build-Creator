import { describe, expect, it } from "vitest";

import {
  exoticArmorSlotLabel,
  groupAndSortExoticArmorSearchResults,
  normalizeExoticArmorSlot,
} from "./exoticArmorSearchGroups";

describe("normalizeExoticArmorSlot", () => {
  it("maps manifest and alias slot names", () => {
    expect(normalizeExoticArmorSlot("Helmet")).toBe("Helmet");
    expect(normalizeExoticArmorSlot("Gauntlets")).toBe("Gauntlets");
    expect(normalizeExoticArmorSlot("arms")).toBe("Gauntlets");
    expect(normalizeExoticArmorSlot("ClassItem")).toBe("ClassItem");
    expect(normalizeExoticArmorSlot("class_item")).toBe("ClassItem");
    expect(normalizeExoticArmorSlot(null)).toBe("Other");
  });
});

describe("groupAndSortExoticArmorSearchResults", () => {
  it("groups by fixed slot order and sorts names within a group", () => {
    const groups = groupAndSortExoticArmorSearchResults([
      { hash: 1, name: "Zulu Chest", slot: "Chest" },
      { hash: 2, name: "Alpha Helm", slot: "Helmet" },
      { hash: 3, name: "Beta Helm", slot: "Helmet" },
      { hash: 4, name: "Omega Legs", slot: "Legs" },
      { hash: 5, name: "Classy", slot: "ClassItem" },
      { hash: 6, name: "Grip", slot: "Gauntlets" },
    ]);

    expect(groups.map((g) => g.key)).toEqual([
      "Helmet",
      "Gauntlets",
      "Chest",
      "Legs",
      "ClassItem",
    ]);
    expect(groups[0]!.items.map((i) => i.name)).toEqual([
      "Alpha Helm",
      "Beta Helm",
    ]);
    expect(groups.map((g) => g.label)).toEqual([
      "Helmet",
      "Gauntlets",
      "Chest",
      "Legs",
      "Class item",
    ]);
  });

  it("puts unknown slots last", () => {
    const groups = groupAndSortExoticArmorSearchResults([
      { hash: 1, name: "Weird", slot: "UnknownSlot" },
      { hash: 2, name: "Helm", slot: "Helmet" },
    ]);
    expect(groups.map((g) => g.key)).toEqual(["Helmet", "Other"]);
  });
});

describe("exoticArmorSlotLabel", () => {
  it("labels class item", () => {
    expect(exoticArmorSlotLabel("ClassItem")).toBe("Class item");
  });
});
