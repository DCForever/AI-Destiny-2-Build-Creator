import { describe, expect, it } from "vitest";

import { addPickedName, ignoreFreeTextList, removePickedName } from "./pickOnlyList";
import { clearIncompatibleSubclassSelections } from "./subclassScope";

describe("subclass pick-only invariants", () => {
  it("does not apply free-typed list text as identity", () => {
    const current = ["Roaring Flames"];
    expect(ignoreFreeTextList("Roaring Flames, Fake Aspect", current)).toEqual(current);
  });

  it("only adds/removes via explicit pick helpers", () => {
    const added = addPickedName([], "Sol Invictus");
    expect(added).toEqual(["Sol Invictus"]);
    expect(removePickedName(added, "Sol Invictus")).toEqual([]);
  });

  it("clears incompatible abilities when valid set changes", () => {
    const cleaned = clearIncompatibleSubclassSelections(
      {
        name: "Striker",
        super: "Hammer of Sol",
        classAbility: "Rally Barricade",
        movement: "Catapult Lift",
        melee: "Consecration",
        grenade: "Healing Grenade",
        aspects: ["Roaring Flames"],
        fragments: ["Ember of Torches"],
        rationale: "keep me",
      },
      {
        abilities: new Set(["Fists of Havoc", "Towering Barricade"]),
        aspects: new Set(["Knockout"]),
        fragments: new Set(["Spark of Instinct"]),
      },
    );
    expect(cleaned.super).toBe("");
    expect(cleaned.aspects).toEqual([]);
    expect(cleaned.fragments).toEqual([]);
    expect(cleaned.rationale).toBe("keep me");
  });
});
