import { describe, expect, it } from "vitest";

import type { BuildSubclass } from "@/components/build/types";

import { createBuildPayload } from "./createBuildPayload";

const DEFAULTS: BuildSubclass = {
  name: "Sunbreaker",
  super: "Hammer of Sol",
  classAbility: "Rally Barricade",
  movement: "Catapult Lift",
  melee: "Consecration",
  grenade: "Healing Grenade",
  aspects: ["Roaring Flames"],
  fragments: ["Ember of Torches"],
  rationale: "Curated build",
};

describe("createBuildPayload", () => {
  it("rejects free-form subclass by falling back to class default", () => {
    const payload = createBuildPayload({
      name: "",
      className: "Titan",
      subclassName: "Not A Real Subclass",
      pinnedSuper: null,
      exotic: null,
      synergyTypes: [{ type: "verb", subType: "Devour" }],
      subclassDefaults: DEFAULTS,
    });
    expect(payload.subclass.name).toBe("Sunbreaker");
  });

  it("pairs exotic hash and name from pick only", () => {
    const payload = createBuildPayload({
      name: "Test",
      className: "Titan",
      subclassName: "Sunbreaker",
      pinnedSuper: null,
      exotic: { hash: 123, name: "Synthoceps" },
      synergyTypes: [{ type: "melee", subType: "Base" }],
      subclassDefaults: DEFAULTS,
    });
    expect(payload.exoticArmorHash).toBe(123);
    expect(payload.exoticArmorName).toBe("Synthoceps");
  });

  it("sets pinned super only when provided (from pick)", () => {
    const withPin = createBuildPayload({
      name: "",
      className: "Warlock",
      subclassName: "Stormcaller",
      pinnedSuper: "Chaos Reach",
      exotic: null,
      synergyTypes: [{ type: "element", subType: "Arc" }],
      subclassDefaults: { ...DEFAULTS, name: "Stormcaller" },
    });
    expect(withPin.pinnedSuper).toBe("Chaos Reach");
    expect(withPin.subclass.super).toBe("Chaos Reach");

    const cleared = createBuildPayload({
      name: "",
      className: "Warlock",
      subclassName: "Stormcaller",
      pinnedSuper: null,
      exotic: null,
      synergyTypes: [{ type: "element", subType: "Arc" }],
      subclassDefaults: { ...DEFAULTS, name: "Stormcaller" },
    });
    expect(cleared.pinnedSuper).toBeNull();
  });
});
