import { describe, it, expect } from "vitest";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import { buildWishlist } from "./wishlist";

const minimalBuild: GeneratedBuild = {
  name: "Arc Soul Warlock",
  summary: "Jolt everything.\nThen explode it.",
  subclass: {
    name: "Stormcaller",
    super: "Stormtrance",
    classAbility: "Rift",
    movement: "Glide",
    melee: "Claws",
    grenade: "Pulse",
    aspects: ["Lightning Surge"],
    fragments: ["Spark of Shock"],
    rationale: "Arc synergy.",
  },
  statTargets: [
    { stat: "Health", target: 100, rationale: "Base." },
    { stat: "Melee", target: 50, rationale: "Low." },
    { stat: "Grenade", target: 100, rationale: "Base." },
    { stat: "Super", target: 100, rationale: "Base." },
    { stat: "Class", target: 100, rationale: "Base." },
    { stat: "Weapons", target: 100, rationale: "Base." },
  ],
  exoticArmor: {
    name: "Ophidian Aspect",
    rationale: "Handling.",
    alternatives: [],
  },
  armor: { archetype: "Gunner", setBonus: "Shattered Throne", rationale: "Farm." },
  weapons: [
    { slot: "Kinetic", name: "Fatebringer", isExotic: false, perks: [], rationale: "" },
    { slot: "Energy", name: "Ikelos SMG", isExotic: false, perks: [], rationale: "" },
    { slot: "Power", name: "Gjallarhorn", isExotic: true, perks: [], rationale: "" },
  ],
  mods: {
    helmet: [],
    arms: [],
    chest: [],
    legs: [],
    classItem: [],
    rationale: "",
  },
  artifact: null,
  gameplayLoop: "Loop.",
  acquisitionNotes: "Farm.",
};

function makeSheet(overrides: Partial<ResolvedBuildSheet> = {}): ResolvedBuildSheet {
  return {
    build: minimalBuild,
    activity: "Grandmaster Nightfall",
    subclass: {
      aspects: [],
      fragments: [],
      abilities: [],
      fragmentCheck: null,
      rationale: "",
    },
    exoticArmor: {
      requestedName: "Ophidian Aspect",
      resolved: { hash: 6001, name: "Ophidian Aspect", icon: null },
      confidence: 1,
      status: "verified",
      alternatives: [],
    },
    weapons: [],
    statTargets: [],
    mods: [],
    artifact: null,
    championCoverage: {
      weaponSources: [],
      subclassSources: [],
      covered: { Barrier: false, Overload: false, Unstoppable: false },
    },
    validation: {
      verified: 0,
      fuzzy: 0,
      unresolved: 0,
      illegalPerks: 0,
      slotMismatches: 0,
      remediations: 0,
    },
    ...overrides,
  };
}

describe("buildWishlist", () => {
  const sheet = makeSheet({
    weapons: [
      {
        slot: "Kinetic",
        reference: {
          requestedName: "Fatebringer",
          resolved: { hash: 4001, name: "Fatebringer", icon: null },
          confidence: 1,
          status: "verified",
        },
        isExotic: false,
        frame: "Adaptive Frame",
        element: "Kinetic",
        ammo: "Primary",
        championCounter: null,
        perks: [
          {
            requestedName: "Firefly",
            resolved: { hash: 5001, name: "Firefly", icon: null },
            confidence: 1,
            status: "verified",
            legality: { legal: true },
          },
          {
            requestedName: "Rampage",
            resolved: { hash: 5002, name: "Rampage", icon: null },
            confidence: 1,
            status: "verified",
            legality: { legal: false, reason: "not in perk pool" },
          },
          {
            requestedName: "Explosive Payload",
            resolved: null,
            confidence: 0,
            status: "unresolved",
            legality: null,
          },
        ],
        rationale: "Precision\nexplosions carry the build.",
      },
      {
        slot: "Energy",
        reference: {
          requestedName: "Ikelos SMG",
          resolved: null,
          confidence: 0,
          status: "unresolved",
        },
        isExotic: false,
        frame: null,
        element: null,
        ammo: null,
        championCounter: null,
        perks: [],
        rationale: "Should be skipped.",
      },
      {
        slot: "Power",
        reference: {
          requestedName: "Gjallarhorn",
          resolved: { hash: 7002, name: "Gjallarhorn", icon: null },
          confidence: 1,
          status: "verified",
        },
        isExotic: true,
        frame: "Aggressive Frame",
        element: "Solar",
        ammo: "Heavy",
        championCounter: null,
        perks: [],
        rationale: "Wolfpack rounds for boss DPS.",
      },
    ],
  });

  it("emits header, perk lines, item-only exotic, and skipped entries", () => {
    const result = buildWishlist(sheet);

    expect(result.text).toContain(
      "title:Arc Soul Warlock (Destiny 2 Build Creator)",
    );
    expect(result.text).toContain("description:Jolt everything. Then explode it.");
    expect(result.text).toContain(
      "dimwishlist:item=4001&perks=5001#notes:Precision explosions carry the build.",
    );
    expect(result.text).toContain(
      "dimwishlist:item=7002#notes:Wolfpack rounds for boss DPS.",
    );
    expect(result.text).not.toContain("dimwishlist:item=" + "Ikelos");
    expect(result.lineCount).toBe(2);
    expect(result.skipped).toEqual([
      "Rampage on Fatebringer: not in perk pool",
      'Perk "Explosive Payload" unresolved on Fatebringer',
      'Weapon "Ikelos SMG" unresolved',
    ]);
  });

  it("strips newlines from weapon notes", () => {
    const result = buildWishlist(sheet);
    expect(result.text).toContain("#notes:Precision explosions carry the build.");
    expect(result.text).not.toContain("Precision\nexplosions");
  });
});
