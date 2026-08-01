import { describe, expect, it } from "vitest";

import {
  filterOutLinkedPickerItems,
  filterOutLinkedWeapons,
} from "./filterLinkedPickerResults";
import type { SynergyPickerItem } from "./synergyPickerLinks";

describe("filterOutLinkedPickerResults", () => {
  it("removes weapons already in draft links", () => {
    const options = [
      { hash: 1, name: "Lodestar" },
      { hash: 2, name: "Other" },
    ];
    const draft = [
      {
        kind: "weapon",
        displayName: "Lodestar",
        itemHash: 1,
      },
    ];
    expect(filterOutLinkedWeapons(options, draft).map((o) => o.hash)).toEqual([
      2,
    ]);
  });

  it("removes origin traits and perks already linked", () => {
    const options: SynergyPickerItem[] = [
      {
        kind: "origin_trait",
        name: "Cast No Shadows",
        description: "",
        originTraitHash: 99,
        originTraitName: "Cast No Shadows",
      },
      {
        kind: "weapon_perk",
        name: "Arc Alignment",
        description: "Jolt",
        hash: 2174503023,
        perkHash: 2174503023,
      },
      {
        kind: "weapon_perk",
        name: "Voltshot",
        description: "",
        hash: 1,
        perkHash: 1,
      },
    ];
    const draft = [
      {
        kind: "origin_trait",
        displayName: "Cast No Shadows",
        originTraitHash: 99,
        originTraitName: "Cast No Shadows",
      },
      {
        kind: "weapon_perk",
        displayName: "Arc Alignment",
        perkHash: 2174503023,
      },
    ];
    const remaining = filterOutLinkedPickerItems(options, draft);
    expect(remaining.map((r) => r.name)).toEqual(["Voltshot"]);
  });

  it("restores options when draft link is removed", () => {
    const options: SynergyPickerItem[] = [
      {
        kind: "exotic_armor",
        name: "Synthoceps",
        description: "",
        hash: 42,
      },
    ];
    const withLink = filterOutLinkedPickerItems(options, [
      { kind: "exotic_armor", displayName: "Synthoceps", itemHash: 42 },
    ]);
    expect(withLink).toHaveLength(0);
    expect(filterOutLinkedPickerItems(options, [])).toHaveLength(1);
  });
});
