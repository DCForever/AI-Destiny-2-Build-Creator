import { describe, expect, it } from "vitest";

import {
  designationIconKey,
  indexAbilityKindCategoryIcons,
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

describe("indexAbilityKindCategoryIcons", () => {
  it("registers Melee/Grenade/Super from ability kind when no exact name", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexAbilityKindCategoryIcons(
      [
        { kind: "grenade", icon: "/pulse_grenade.png", hash: 20 },
        { kind: "grenade", icon: "/other.png", hash: 5 },
        { kind: "melee", icon: "/fist.png", hash: 3 },
        { kind: "super", icon: null, hash: 1 },
        { kind: "super", icon: "/golden.png", hash: 9 },
      ],
      byName,
    );
    expect(lookupIconByName(byName, "Grenade")?.icon).toBe("/other.png");
    expect(lookupIconByName(byName, "Melee")?.icon).toBe("/fist.png");
    expect(lookupIconByName(byName, "Super")?.icon).toBe("/golden.png");
    expect(lookupIconByName(byName, "Grenade")?.source).toBe("ability-kind");
  });

  it("does not override an existing exact name icon", () => {
    const byName = new Map<string, { icon: string; source: string }>();
    indexEntityIcons(
      [{ name: "Grenade", icon: "/generic_grenade.png" }],
      "abilities",
      byName,
    );
    indexAbilityKindCategoryIcons(
      [{ kind: "grenade", icon: "/pulse.png", hash: 1 }],
      byName,
    );
    expect(lookupIconByName(byName, "Grenade")?.icon).toBe(
      "/generic_grenade.png",
    );
  });
});

