import { describe, expect, it } from "vitest";

import { buildJsonSchema, generatedBuildSchema } from "./buildSchema";

function sampleBuild(): unknown {
  const statTargets = [
    { stat: "Health", target: 150, rationale: "Survivability in GMs" },
    { stat: "Melee", target: 200, rationale: "Core damage loop" },
    { stat: "Grenade", target: 60, rationale: "Deprioritized" },
    { stat: "Super", target: 100, rationale: "Baseline" },
    { stat: "Class", target: 120, rationale: "Overshield on cast" },
    { stat: "Weapons", target: 70, rationale: "Spare points" },
  ];
  return {
    name: "Consecration Engine",
    summary: "A Solar Titan melee loop that converts kills into more melees.",
    subclass: {
      name: "Sunbreaker",
      super: "Burning Maul",
      classAbility: "Rally Barricade",
      movement: "Catapult Lift",
      melee: "Hammer Strike",
      grenade: "Healing Grenade",
      aspects: ["Consecration", "Roaring Flames"],
      fragments: ["Ember of Torches", "Ember of Searing"],
      rationale: "Consecration slams scale with Roaring Flames.",
    },
    statTargets,
    exoticArmor: {
      name: "Synthoceps",
      rationale: "Biotic enhancements buff slam damage when surrounded.",
      alternatives: [{ name: "Pyrogale Gauntlets", rationale: "Single charged slam." }],
    },
    armor: { archetype: "Brawler", setBonus: "Shattered Throne", rationale: "Melee primary." },
    weapons: [
      { slot: "Kinetic", name: "Fatebringer", isExotic: false, perks: [{ name: "Explosive Payload" }], rationale: "Workhorse." },
      { slot: "Energy", name: "Sunshot", isExotic: true, perks: [], rationale: "Add clear and ignitions." },
      { slot: "Power", name: "The Hothead", isExotic: false, perks: [{ name: "Explosive Light" }], rationale: "Burst DPS." },
    ],
    mods: {
      helmet: ["Hands-On"],
      arms: ["Heavy Handed", "Momentum Transfer"],
      chest: ["Concussive Dampener"],
      legs: ["Recuperation"],
      classItem: ["Powerful Attraction"],
      rationale: "Orb economy feeds armor charge.",
    },
    artifact: {
      name: "Queensfoil Censer",
      perks: [{ name: "Authorized Mods: Melee" }],
      rationale: "Melee perk column synergy.",
    },
    gameplayLoop: "Slam, collect orbs, refresh Restoration, repeat. Save heavy for champions.",
    acquisitionNotes: "Farm the featured dungeon for Tier 5 Brawler pieces.",
  };
}

describe("generatedBuildSchema", () => {
  it("accepts a complete valid build", () => {
    const result = generatedBuildSchema.safeParse(sampleBuild());
    expect(result.success).toBe(true);
  });

  it("accepts a null artifact for PvP builds", () => {
    const build = sampleBuild() as Record<string, unknown>;
    build.artifact = null;
    expect(generatedBuildSchema.safeParse(build).success).toBe(true);
  });

  it("rejects builds missing weapons or with wrong slot count", () => {
    const build = sampleBuild() as Record<string, unknown>;
    build.weapons = (build.weapons as unknown[]).slice(0, 2);
    expect(generatedBuildSchema.safeParse(build).success).toBe(false);
  });

  it("rejects stat targets outside 0-200 or non-Armor-3.0 stat names", () => {
    const build = sampleBuild() as Record<string, unknown>;
    const targets = build.statTargets as { target: number }[];
    targets[0].target = 250;
    expect(generatedBuildSchema.safeParse(build).success).toBe(false);

    const build2 = sampleBuild() as Record<string, unknown>;
    const targets2 = build2.statTargets as { stat: string }[];
    targets2[0].stat = "Resilience";
    expect(generatedBuildSchema.safeParse(build2).success).toBe(false);
  });

  it("rejects more than 3 aspects", () => {
    const build = sampleBuild() as Record<string, unknown>;
    const subclass = build.subclass as { aspects: string[] };
    subclass.aspects = ["A", "B", "C", "D"];
    expect(generatedBuildSchema.safeParse(build).success).toBe(false);
  });

  it("rejects empty rationale strings", () => {
    const build = sampleBuild() as Record<string, unknown>;
    (build.exoticArmor as { rationale: string }).rationale = "  ";
    expect(generatedBuildSchema.safeParse(build).success).toBe(false);
  });
});

describe("buildJsonSchema", () => {
  it("produces an object JSON schema with required top-level fields", () => {
    const schema = buildJsonSchema();
    expect(schema.type).toBe("object");
    const required = schema.required as string[];
    expect(required).toEqual(
      expect.arrayContaining(["name", "subclass", "statTargets", "weapons", "artifact"]),
    );
  });
});
