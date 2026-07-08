import { describe, expect, it } from "vitest";

import {
  clearIncompatibleSubclassSelections,
  resolveSubclassScope,
  type SubclassFormValue,
} from "./subclassScope";

const ARC_VALUE: SubclassFormValue = {
  name: "Stormcaller",
  super: "Stormtrance",
  classAbility: "Healing Rift",
  movement: "Burst Glide",
  melee: "Chain Lightning",
  grenade: "Arcbolt Grenade",
  aspects: ["Electrostatic Mind", "Heat Rises"],
  fragments: ["Spark of Ions", "Ember of Torches"],
  rationale: "Arc setup",
};

describe("resolveSubclassScope", () => {
  it("resolves Stormcaller to Warlock Arc", () => {
    expect(resolveSubclassScope("Stormcaller")).toEqual({
      classType: "Warlock",
      element: "Arc",
    });
  });

  it("resolves Prismatic Warlock to Warlock Prismatic only", () => {
    expect(resolveSubclassScope("Prismatic Warlock")).toEqual({
      classType: "Warlock",
      element: "Prismatic",
    });
  });

  it("returns null for unknown subclasses", () => {
    expect(resolveSubclassScope("Unknown")).toBeNull();
  });
});

describe("clearIncompatibleSubclassSelections", () => {
  it("clears incompatible names and keeps compatible names", () => {
    const next = clearIncompatibleSubclassSelections(ARC_VALUE, {
      abilities: new Set(["Healing Rift", "Burst Glide"]),
      aspects: new Set(["Heat Rises"]),
      fragments: new Set(["Ember of Torches"]),
    });

    expect(next).toEqual({
      ...ARC_VALUE,
      super: "",
      classAbility: "Healing Rift",
      movement: "Burst Glide",
      melee: "",
      grenade: "",
      aspects: ["Heat Rises"],
      fragments: ["Ember of Torches"],
    });
  });
});
