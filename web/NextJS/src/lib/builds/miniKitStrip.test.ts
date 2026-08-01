import { describe, expect, it } from "vitest";

import {
  buildMiniKitStripModel,
  miniKitStripHasAnyFill,
  MINI_KIT_ABILITY_SLOTS,
} from "@/lib/builds/miniKitStrip";

describe("buildMiniKitStripModel", () => {
  it("always returns five ability slots", () => {
    const model = buildMiniKitStripModel({ subclass: { name: "Sunbreaker" } });
    expect(model.abilities).toHaveLength(5);
    expect(model.abilities.map((a) => a.key)).toEqual(
      MINI_KIT_ABILITY_SLOTS.map((s) => s.key),
    );
    expect(model.abilities.every((a) => a.entity === null)).toBe(true);
    expect(miniKitStripHasAnyFill(model)).toBe(false);
  });

  it("fills abilities from presentation and pinned super", () => {
    const model = buildMiniKitStripModel({
      pinnedSuper: "Hammer of Sol",
      subclass: {
        name: "Sunbreaker",
        melee: "Hammer Strike",
        grenade: "Thermite Grenade",
        aspects: ["Roaring Flames"],
        fragments: ["Ember of Ashes", "Ember of Singeing"],
      },
      presentation: {
        melee: {
          name: "Hammer Strike",
          icon: "/melee.png",
          description: "Solar melee",
          element: "Solar",
        },
      },
    });
    expect(model.abilities.find((a) => a.key === "super")?.entity?.name).toBe(
      "Hammer of Sol",
    );
    expect(model.abilities.find((a) => a.key === "melee")?.entity?.icon).toBe(
      "/melee.png",
    );
    expect(model.aspects.map((a) => a.name)).toEqual(["Roaring Flames"]);
    expect(model.fragments).toHaveLength(2);
    expect(miniKitStripHasAnyFill(model)).toBe(true);
  });
});
