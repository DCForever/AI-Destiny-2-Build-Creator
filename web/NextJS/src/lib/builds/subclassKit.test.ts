import { describe, expect, it } from "vitest";

import {
  buildSubclassAfterTreeChange,
  effectiveSubclass,
  emptyLegalBaselineForTree,
  isSubclassTreeChange,
  kitFromLegacySubclass,
  resolveVariantKit,
  treeNameFromSubclass,
} from "@/lib/builds/subclassKit";

const fullLegacy = {
  name: "Sunbreaker",
  super: "Hammer of Sol",
  classAbility: "Rally Barricade",
  movement: "Strafe Lift",
  melee: "Hammer Strike",
  grenade: "Thermite Grenade",
  aspects: ["Roaring Flames", "Consecration"],
  fragments: ["Ember of Ashes"],
  rationale: "",
};

describe("subclassKit helpers", () => {
  it("detects tree name changes only", () => {
    expect(isSubclassTreeChange(fullLegacy, { ...fullLegacy, super: "Other" })).toBe(
      false,
    );
    expect(
      isSubclassTreeChange(fullLegacy, { ...fullLegacy, name: "Striker" }),
    ).toBe(true);
  });

  it("prefers variant kit over build legacy kit", () => {
    const variantKit = {
      ...kitFromLegacySubclass(fullLegacy),
      super: "Burning Maul",
    };
    const resolved = resolveVariantKit(fullLegacy, variantKit);
    expect(resolved.super).toBe("Burning Maul");
    expect(resolveVariantKit(fullLegacy, null).super).toBe("Hammer of Sol");
  });

  it("merges tree name with variant kit and pinned super", () => {
    const kit = kitFromLegacySubclass(fullLegacy);
    const effective = effectiveSubclass(fullLegacy, kit, "Pinned Super");
    expect(effective.name).toBe("Sunbreaker");
    expect(effective.super).toBe("Pinned Super");
    expect(effective.aspects).toEqual(fullLegacy.aspects);
  });

  it("wipes kit fields after tree change baseline", () => {
    const next = buildSubclassAfterTreeChange({ name: "Striker", rationale: "x" });
    expect(next.name).toBe("Striker");
    expect(next.aspects).toEqual([]);
    expect(next.super).toBe("");
    expect(emptyLegalBaselineForTree("Striker").fragments).toEqual([]);
  });

  it("reads tree name safely", () => {
    expect(treeNameFromSubclass(null)).toBe("");
    expect(treeNameFromSubclass({ name: "  Dawnblade " })).toBe("Dawnblade");
  });
});
