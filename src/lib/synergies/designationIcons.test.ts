import { describe, expect, it } from "vitest";

import {
  designationIconKey,
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
