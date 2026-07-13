import { describe, expect, it } from "vitest";

import {
  designationIconKey,
  indexAbilityCategoryStatIcons,
  indexEntityIcons,
  indexInventoryItemIcons,
  lookupIconByName,
  resolveDesignationFromIndex,
} from "./designationIconShared";

describe("designationIconKey", () => {
  it("normalizes type and subtype", () => {
    expect(designationIconKey("verb", "Void Breach")).toBe("verb::void breach");
    expect(designationIconKey("Verb", "Champions")).toBe("verb::champion");
  });
});

describe("index + lookup", () => {
  it("indexes entity icons by name", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexEntityIcons(
      [
        { name: "Void Breach", icon: "/void_breach.png" },
        { name: "Rapid Fire Frame", icon: "/rff.png" },
      ],
      "weapon-perks",
      byName,
    );
    expect(lookupIconByName(byName, "void breach")?.icon).toBe(
      "/void_breach.png",
    );
    expect(lookupIconByName(byName, "Rapid Fire Frame")?.icon).toBe("/rff.png");
  });

  it("scans inventory items for missing verb icons", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    const itemTable = {
      "1": {
        hash: 1,
        redacted: false,
        displayProperties: {
          name: "Firesprite",
          description: "",
          icon: "/firesprite.png",
        },
      },
      "2": {
        hash: 2,
        redacted: false,
        displayProperties: {
          name: "Ionic Trace",
          description: "",
          icon: "/ionic.png",
        },
      },
    };
    indexInventoryItemIcons(itemTable, ["Firesprite", "Ionic Trace"], byName);
    expect(lookupIconByName(byName, "Firesprite")?.icon).toBe("/firesprite.png");
    expect(lookupIconByName(byName, "Ionic Trace")?.source).toBe(
      "inventory-item",
    );
  });
});

describe("resolveDesignationFromIndex", () => {
  it("resolves verb subtypes", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexEntityIcons(
      [{ name: "Void Breach", icon: "/vb.png" }],
      "inventory-item",
      byName,
    );
    const hit = resolveDesignationFromIndex("verb", "Void Breach", byName);
    expect(hit.icon).toBe("/vb.png");
    expect(hit.source).toBe("inventory-item");
  });

  it("returns null icon when unknown", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    const hit = resolveDesignationFromIndex("verb", "Not A Real Verb", byName);
    expect(hit.icon).toBeNull();
  });
});

describe("indexAbilityCategoryStatIcons", () => {
  it("registers Melee/Grenade/Super from DestinyStatDefinition", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexAbilityCategoryStatIcons(
      {
        "1": {
          hash: 1,
          index: 4,
          displayProperties: {
            name: "Melee",
            icon: "/stat_melee.png",
            hasIcon: true,
          },
        },
        "2": {
          hash: 2,
          index: 5,
          displayProperties: {
            name: "Grenade",
            icon: "/stat_grenade.png",
            hasIcon: true,
          },
        },
        "3": {
          hash: 3,
          index: 6,
          displayProperties: {
            name: "Super",
            icon: "/stat_super.png",
            hasIcon: true,
          },
        },
      },
      byName,
    );
    expect(lookupIconByName(byName, "Melee")?.icon).toBe("/stat_melee.png");
    expect(lookupIconByName(byName, "Grenade")?.icon).toBe("/stat_grenade.png");
    expect(lookupIconByName(byName, "Super")?.icon).toBe("/stat_super.png");
    expect(lookupIconByName(byName, "Melee")?.source).toBe("stat-category");
  });

  it("prefers lower index when duplicate Class stats share a name", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexAbilityCategoryStatIcons(
      {
        "10": {
          hash: 10,
          index: 10,
          displayProperties: {
            name: "Class",
            icon: "/class_wrong_melee_dupe.png",
            hasIcon: true,
          },
        },
        "7": {
          hash: 7,
          index: 7,
          displayProperties: {
            name: "Class",
            icon: "/class_canonical.png",
            hasIcon: true,
          },
        },
      },
      byName,
    );
    expect(lookupIconByName(byName, "Class")?.icon).toBe("/class_canonical.png");
  });

  it("overwrites stray ability-name hits for category labels", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexEntityIcons(
      [{ name: "Grenade", icon: "/wrong_pulse_grenade.png" }],
      "abilities",
      byName,
    );
    indexAbilityCategoryStatIcons(
      {
        "2": {
          hash: 2,
          index: 5,
          displayProperties: {
            name: "Grenade",
            icon: "/stat_grenade.png",
            hasIcon: true,
          },
        },
      },
      byName,
    );
    expect(lookupIconByName(byName, "Grenade")?.icon).toBe("/stat_grenade.png");
  });
});

