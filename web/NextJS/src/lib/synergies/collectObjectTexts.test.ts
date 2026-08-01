import { describe, expect, it } from "vitest";

import { collectObjectTexts } from "./collectObjectTexts";

describe("collectObjectTexts", () => {
  it("only includes the allowed object kinds and exotic intrinsic/catalyst text", () => {
    const rows = collectObjectTexts({
      originTraits: [
        {
          hash: 1,
          name: "Wild Card",
          searchName: "wild card",
          icon: null,
          description: "Grants Radiant on multi-kills.",
        },
      ],
      setBonuses: [
        {
          hash: 2,
          name: "Solstice",
          searchName: "solstice",
          icon: null,
          itemHashes: [],
          perks: [
            {
              requiredCount: 2,
              name: "Solar Siphon",
              description: "Orbs create Firesprites.",
            },
          ],
        },
      ],
      weaponPerks: [
        {
          hash: 3,
          name: "Slideways",
          searchName: "slideways",
          icon: null,
          description: "Sliding increases reload speed.",
        },
        {
          hash: 30,
          name: "Fluted Barrel",
          searchName: "fluted barrel",
          icon: null,
          description: "Ultra-light barrel. Increases handling.",
        },
        {
          hash: 31,
          name: "Tactical Mag",
          searchName: "tactical mag",
          icon: null,
          description: "This weapon has a larger magazine.",
        },
      ],
      weapons: [
        {
          hash: 100,
          name: "Test Gun",
          searchName: "test gun",
          icon: null,
          slot: "Kinetic",
          element: "Kinetic",
          ammo: "Primary",
          frame: "Adaptive Frame",
          itemTypeName: "Auto Rifle",
          originTraitHashes: [],
          perkColumns: [
            { column: 0, curated: [30], randomized: [] },
            { column: 1, curated: [31], randomized: [] },
            { column: 2, curated: [3], randomized: [] },
          ],
        },
      ],
      aspects: [
        {
          hash: 4,
          name: "Knockout",
          searchName: "knockout",
          icon: null,
          description: "Melee grants Amplified.",
          classType: "Titan",
          element: "Arc",
          fragmentCapacity: 2,
        },
      ],
      fragments: [
        {
          hash: 5,
          name: "Echo of Persistence",
          searchName: "echo",
          icon: null,
          description: "Void buffs last longer.",
          element: "Void",
          statModifiers: {},
        },
      ],
      exoticArmor: [
        {
          hash: 6,
          name: "Synthoceps",
          searchName: "synthoceps",
          icon: null,
          classType: "Titan",
          slot: "Gauntlets",
          intrinsic: {
            name: "Biotic Enhancements",
            description: "Improved melee while surrounded.",
          },
          archetype: null,
          flavorText: "Ignore this flavor for keywords.",
        },
      ],
      exoticWeapons: [
        {
          hash: 7,
          name: "Sunshot",
          searchName: "sunshot",
          icon: null,
          slot: "Energy",
          element: "Solar",
          ammo: "Primary",
          frame: "Adaptive Frame",
          intrinsic: {
            name: "Sunburn",
            description: "Targets explode and Scorch nearby foes.",
          },
          catalyst: {
            name: "Sunshot Catalyst",
            description: "Faster reload while Amplified.",
          },
          flavorText: "Flavor should not be scanned.",
        },
      ],
      artifacts: [
        {
          hash: 8,
          name: "Disc of the Star",
          searchName: "disc",
          icon: null,
          description: "Seasonal artifact.",
          perks: [
            {
              hash: 9,
              name: "Anti-Barrier Pulse",
              searchName: "anti-barrier",
              icon: null,
              description: "Pulse rifles stun Barrier champions.",
              column: 0,
              row: 0,
            },
          ],
        },
      ],
    });

    const stores = new Set(rows.map((r) => r.store));
    expect([...stores].sort()).toEqual(
      [
        "artifacts",
        "aspects",
        "exotic-armor",
        "exotic-weapons",
        "fragments",
        "origin-traits",
        "set-bonuses",
        "weapon-perks",
      ].sort(),
    );
    expect(rows.some((r) => r.name === "Anti-Barrier Pulse")).toBe(true);
    expect(rows.some((r) => r.name === "Slideways")).toBe(true);
    expect(rows.some((r) => r.name === "Fluted Barrel")).toBe(false);
    expect(rows.some((r) => r.name === "Tactical Mag")).toBe(false);

    const sunshot = rows.find((r) => r.hash === 7);
    expect(sunshot?.description).toContain("Scorch");
    expect(sunshot?.description).toContain("Amplified");
    expect(sunshot?.description).not.toContain("Flavor should not");

    const synth = rows.find((r) => r.hash === 6);
    // Intrinsic *names* are not scanned — only description bodies
    expect(synth?.description).toContain("Improved melee while surrounded");
    expect(synth?.description).not.toContain("Biotic Enhancements");
    expect(synth?.description).not.toContain("Ignore this flavor");

    const sunshotRow = rows.find((r) => r.hash === 7);
    expect(sunshotRow?.description).not.toContain("Sunburn");
    expect(sunshotRow?.description).not.toContain("Sunshot Catalyst");
  });
});
