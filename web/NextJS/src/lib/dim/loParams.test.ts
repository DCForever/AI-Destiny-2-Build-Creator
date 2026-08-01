import { describe, it, expect } from "vitest";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import { buildLoParams, renderLoParamsText } from "./loParams";

const minimalBuild: GeneratedBuild = {
  name: "Melee Titan",
  summary: "Punch everything.",
  subclass: {
    name: "Behemoth",
    super: "Glacial Quake",
    classAbility: "Barricade",
    movement: "Lift",
    melee: "Shiver Strike",
    grenade: "Duskfield",
    aspects: ["Diamond Lance"],
    fragments: ["Ember of Ashes"],
    rationale: "Stasis melee.",
  },
  statTargets: [
    { stat: "Health", target: 100, rationale: "Base." },
    { stat: "Melee", target: 200, rationale: "Max melee." },
    { stat: "Grenade", target: 50, rationale: "Low." },
    { stat: "Super", target: 100, rationale: "Base." },
    { stat: "Class", target: 100, rationale: "Base." },
    { stat: "Weapons", target: 100, rationale: "Base." },
  ],
  exoticArmor: {
    name: "Hallowfire Heart",
    rationale: "Sunspots.",
    alternatives: [],
  },
  armor: { archetype: "Brawler", setBonus: "Iron Lords", rationale: "Farm brawler." },
  weapons: [
    { slot: "Kinetic", name: "Shotgun", isExotic: false, perks: [], rationale: "" },
    { slot: "Energy", name: "Fusion", isExotic: false, perks: [], rationale: "" },
    { slot: "Power", name: "Rocket", isExotic: true, perks: [], rationale: "" },
  ],
  mods: {
    helmet: ["Ashes to Assets"],
    arms: ["Heavy Handed"],
    chest: [],
    legs: [],
    classItem: [],
    rationale: "",
  },
  artifact: {
    name: "Hunters Journal",
    perks: [{ name: "Anti-Barrier Hand Cannon" }],
    rationale: "Champion coverage.",
  },
  gameplayLoop: "Punch loop.",
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
      requestedName: "Hallowfire Heart",
      resolved: { hash: 6101, name: "Hallowfire Heart", icon: null },
      confidence: 1,
      status: "verified",
      alternatives: [],
    },
    statTargets: [
      { stat: "Health", target: 100, benefits: [], rationale: "" },
      {
        stat: "Melee",
        target: 200,
        benefits: ["+30% melee ability damage"],
        rationale: "",
      },
      { stat: "Grenade", target: 50, benefits: ["+5% grenade damage"], rationale: "" },
      { stat: "Super", target: 100, benefits: [], rationale: "" },
      { stat: "Class", target: 100, benefits: [], rationale: "" },
      { stat: "Weapons", target: 100, benefits: [], rationale: "" },
    ],
    mods: [
      {
        slot: "helmet",
        picks: [
          {
            requestedName: "Ashes to Assets",
            resolved: { hash: 8001, name: "Ashes to Assets", icon: null },
            confidence: 1,
            status: "verified",
            legality: { legal: true },
          },
        ],
      },
      {
        slot: "arms",
        picks: [
          {
            requestedName: "Heavy Handed",
            resolved: { hash: 8002, name: "Heavy Handed", icon: null },
            confidence: 1,
            status: "verified",
            legality: { legal: true },
          },
          {
            requestedName: "Missing Mod",
            resolved: null,
            confidence: 0,
            status: "unresolved",
            legality: null,
          },
        ],
      },
      { slot: "chest", picks: [] },
    ],
    artifact: {
      reference: {
        requestedName: "Hunters Journal",
        resolved: { hash: 9002, name: "Hunters Journal", icon: null },
        confidence: 1,
        status: "verified",
      },
      perks: [],
      rationale: "",
      allowedInActivity: true,
    },
    weapons: [],
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

describe("buildLoParams", () => {
  it("preserves stat order and builds notes for above-100 stats only", () => {
    const params = buildLoParams(makeSheet());

    expect(params.statPriorities.map((s) => s.stat)).toEqual([
      "Health",
      "Melee",
      "Grenade",
      "Super",
      "Class",
      "Weapons",
    ]);
    expect(params.notes).toContain("Melee 200: +30% melee ability damage");
    expect(params.notes).not.toContain("Grenade 50: +5% grenade damage");
    expect(params.notes).not.toContain("Health 100:");
  });

  it("excludes unresolved mods and resolves exotic armor name", () => {
    const params = buildLoParams(makeSheet());
    expect(params.modsPerSlot).toEqual([
      { slot: "helmet", mods: ["Ashes to Assets"] },
      { slot: "arms", mods: ["Heavy Handed"] },
      { slot: "chest", mods: [] },
    ]);
    expect(params.exoticArmorName).toBe("Hallowfire Heart");
  });

  it("returns null exoticArmorName when exotic is unresolved", () => {
    const params = buildLoParams(
      makeSheet({
        exoticArmor: {
          requestedName: "Unknown Exotic",
          resolved: null,
          confidence: 0,
          status: "unresolved",
          alternatives: [],
        },
      }),
    );
    expect(params.exoticArmorName).toBeNull();
  });

  it("includes artifact note when allowed and omits when null or disallowed", () => {
    const allowed = buildLoParams(makeSheet());
    expect(allowed.notes).toContain(
      "Artifact: Hunters Journal — save perks to the loadout in-game",
    );

    const noArtifact = buildLoParams(makeSheet({ artifact: null }));
    expect(noArtifact.notes).not.toContain("Artifact:");

    const disallowed = buildLoParams(
      makeSheet({
        artifact: {
          reference: {
            requestedName: "Hunters Journal",
            resolved: null,
            confidence: 0,
            status: "unresolved",
          },
          perks: [],
          rationale: "",
          allowedInActivity: false,
        },
      }),
    );
    expect(disallowed.notes).not.toContain("Artifact:");
  });

  it("includes farm note with set bonus", () => {
    const params = buildLoParams(makeSheet());
    expect(params.notes).toContain(
      "Farm Brawler archetype armor with the Iron Lords set bonus",
    );
    expect(params.setBonus).toBe("Iron Lords");
    expect(params.armorArchetype).toBe("Brawler");
  });
});

describe("renderLoParamsText", () => {
  it("renders deterministic plain-text sections", () => {
    const params = buildLoParams(makeSheet());
    const text = renderLoParamsText(params);

    expect(text).toBe(
      [
        "Exotic",
        "Hallowfire Heart",
        "",
        "Stat priorities",
        "Health: 100",
        "Melee: 200",
        "Grenade: 50",
        "Super: 100",
        "Class: 100",
        "Weapons: 100",
        "",
        "Mods",
        "helmet: Ashes to Assets",
        "arms: Heavy Handed",
        "chest: (none)",
        "",
        "Notes",
        "- Melee 200: +30% melee ability damage",
        "- Farm Brawler archetype armor with the Iron Lords set bonus",
        "- Artifact: Hunters Journal — save perks to the loadout in-game",
      ].join("\n"),
    );
    expect(text.endsWith("\n")).toBe(false);
    expect(text.split("\n").every((line) => line.trim() === line)).toBe(true);
  });
});
