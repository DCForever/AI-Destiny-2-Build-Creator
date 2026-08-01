import { describe, expect, it } from "vitest";

import { RAW_TABLES } from "@/lib/manifest/__fixtures__/rawTables";

import {
  collectLegendaryWeaponArchetypeSubTypeNames,
  collectLegendaryWeaponFrameNames,
  collectLegendaryWeaponTypeNames,
  isLegendaryWeaponFramePlug,
  isWeaponArchetypeSubTypeName,
  isWeaponFrameName,
  isWeaponTypeName,
  legendaryWeaponFrameName,
  matchesWeaponArchetype,
  matchingWeaponArchetypeSubType,
} from "./weaponArchetypeSubType";

const ITEMS = RAW_TABLES.DestinyInventoryItemDefinition;

const pulseMicroMissile = {
  frame: "Micro-Missile Frame",
  itemTypeName: "Pulse Rifle",
};

describe("weaponArchetypeSubType", () => {
  it("identifies manifest weapon frame names", () => {
    expect(isWeaponFrameName("Micro-Missile Frame")).toBe(true);
    expect(isWeaponFrameName("Adaptive Frame")).toBe(true);
    expect(isWeaponFrameName("Pulse Rifle")).toBe(false);
    expect(isWeaponFrameName("Explosive Payload")).toBe(false);
    expect(isWeaponFrameName("Outlaw")).toBe(false);
    expect(isWeaponFrameName("Pulse Rifle: Micro-Missile Frame")).toBe(false);
  });

  it("identifies weapon type names", () => {
    expect(isWeaponTypeName("Pulse Rifle")).toBe(true);
    expect(isWeaponTypeName("Hand Cannon")).toBe(true);
    expect(isWeaponTypeName("Micro-Missile Frame")).toBe(false);
  });

  it("accepts weapon types and frames as archetype sub-type shapes", () => {
    expect(isWeaponArchetypeSubTypeName("Pulse Rifle")).toBe(true);
    expect(isWeaponArchetypeSubTypeName("Precision Frame")).toBe(true);
  });

  it("distinguishes intrinsic frames from trait plugs sharing frames category", () => {
    const intrinsic = ITEMS["1008"];
    const trait = ITEMS["1012"];
    expect(isLegendaryWeaponFramePlug(intrinsic as never)).toBe(true);
    expect(isLegendaryWeaponFramePlug(trait as never)).toBe(false);
  });

  it("collects unique legendary types and frames from manifest", () => {
    expect(collectLegendaryWeaponTypeNames(ITEMS)).toEqual(["Pulse Rifle"]);
    expect(collectLegendaryWeaponFrameNames(ITEMS)).toEqual(["Precision Frame"]);
    expect(collectLegendaryWeaponArchetypeSubTypeNames(ITEMS)).toEqual([
      "Precision Frame",
      "Pulse Rifle",
    ]);
  });

  it("resolves frame name for a legendary weapon item", () => {
    const weapon = ITEMS["1007"];
    expect(legendaryWeaponFrameName(weapon as never, ITEMS)).toBe("Precision Frame");
  });

  it("matches weapons by frame or weapon type", () => {
    expect(matchesWeaponArchetype(pulseMicroMissile, "Micro-Missile Frame")).toBe(true);
    expect(matchesWeaponArchetype(pulseMicroMissile, "Pulse Rifle")).toBe(true);
    expect(matchesWeaponArchetype(pulseMicroMissile, "Adaptive Frame")).toBe(false);
    expect(matchesWeaponArchetype(pulseMicroMissile, "Hand Cannon")).toBe(false);
  });

  it("returns the first matching archetype sub-type", () => {
    expect(
      matchingWeaponArchetypeSubType(pulseMicroMissile, [
        "Hand Cannon",
        "Pulse Rifle",
        "Micro-Missile Frame",
      ]),
    ).toBe("Pulse Rifle");
  });
});
