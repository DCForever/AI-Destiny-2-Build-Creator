import { describe, it, expect } from "vitest";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import { buildDimLoadout } from "./dimLoadout";

const minimalBuild: GeneratedBuild = {
  name: "Solar Warlock",
  summary: "Burn everything with Sunbracers.",
  subclass: {
    name: "Dawnblade",
    super: "Well of Radiance",
    classAbility: "Healing Rift",
    movement: "Glide",
    melee: "Celestial Fire",
    grenade: "Fusion",
    aspects: ["Touch of Flame"],
    fragments: ["Ember of Ashes"],
    rationale: "Solar loop.",
  },
  statTargets: [
    { stat: "Melee", target: 150, rationale: "High melee." },
    { stat: "Health", target: 80, rationale: "Low." },
    { stat: "Grenade", target: 200, rationale: "Max grenade." },
    { stat: "Super", target: 100, rationale: "Mid." },
    { stat: "Class", target: 100, rationale: "Mid." },
    { stat: "Weapons", target: 50, rationale: "Low." },
  ],
  exoticArmor: { name: "Sunbracers", rationale: "Grenades.", alternatives: [] },
  armor: { archetype: "Recovery", rationale: "" },
  weapons: [
    { slot: "Kinetic", name: "Hawkmoon", isExotic: true, perks: [], rationale: "" },
    { slot: "Energy", name: "Fusion Rifle", isExotic: false, perks: [], rationale: "" },
    { slot: "Power", name: "Rocket Launcher", isExotic: false, perks: [], rationale: "" },
  ],
  mods: {
    helmet: ["Ashes to Assets"],
    arms: ["Heavy Handed"],
    chest: [],
    legs: [],
    classItem: [],
    rationale: "",
  },
  artifact: null,
  gameplayLoop: "Throw grenades.",
  acquisitionNotes: "Farm.",
};

function makeSheet(overrides: Partial<ResolvedBuildSheet> = {}): ResolvedBuildSheet {
  return {
    build: minimalBuild,
    activity: "Grandmaster",
    subclass: { aspects: [], fragments: [], abilities: [], fragmentCheck: null, rationale: "" },
    exoticArmor: {
      requestedName: "Sunbracers",
      resolved: { hash: 7001, name: "Sunbracers", icon: null },
      confidence: 1,
      status: "verified",
      alternatives: [],
    },
    statTargets: [
      { stat: "Melee", target: 150, benefits: [], rationale: "" },
      { stat: "Health", target: 80, benefits: [], rationale: "" },
      { stat: "Grenade", target: 200, benefits: [], rationale: "" },
      { stat: "Super", target: 100, benefits: [], rationale: "" },
      { stat: "Class", target: 100, benefits: [], rationale: "" },
      { stat: "Weapons", target: 50, benefits: [], rationale: "" },
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
    ],
    weapons: [
      {
        slot: "Kinetic",
        reference: {
          requestedName: "Hawkmoon",
          resolved: { hash: 1001, name: "Hawkmoon", icon: null },
          confidence: 1,
          status: "verified",
        },
        isExotic: true,
        frame: "Lightweight Frame",
        element: "Kinetic",
        ammo: "Primary",
        championCounter: null,
        perks: [],
        rationale: "",
      },
      {
        slot: "Energy",
        reference: {
          requestedName: "Unknown Fusion",
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
        rationale: "",
      },
    ],
    artifact: null,
    championCoverage: {
      weaponSources: [],
      subclassSources: [],
      covered: { Barrier: false, Overload: false, Unstoppable: false },
    },
    validation: { verified: 0, fuzzy: 0, unresolved: 0, illegalPerks: 0, slotMismatches: 0, remediations: 0 },
    ...overrides,
  };
}

describe("buildDimLoadout", () => {
  it("produces a valid DimLoadout document shape", () => {
    const sheet = makeSheet();
    const doc = buildDimLoadout(sheet, "Warlock");

    expect(typeof doc.id).toBe("string");
    expect(doc.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
    );
    expect(doc.name).toBe("Solar Warlock");
    expect(doc.notes).toBe("Burn everything with Sunbracers.");
    expect(doc.classType).toBe(2);
    expect(doc.unequipped).toEqual([]);
  });

  it("maps classType correctly for all three classes", () => {
    const sheet = makeSheet();
    expect(buildDimLoadout(sheet, "Titan").classType).toBe(0);
    expect(buildDimLoadout(sheet, "Hunter").classType).toBe(1);
    expect(buildDimLoadout(sheet, "Warlock").classType).toBe(2);
  });

  it("includes resolved weapon and exotic armor hashes in equipped; skips unresolved", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    const hashes = doc.equipped.map((i) => i.hash);
    expect(hashes).toContain(1001); // Hawkmoon (resolved)
    expect(hashes).toContain(7001); // Sunbracers (resolved)
    expect(hashes).not.toContain(undefined);
    // unresolved Energy weapon should not appear
    expect(hashes.length).toBe(2);
  });

  it("equipped items have no instance id (hash-only)", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    for (const item of doc.equipped) {
      expect(item.id).toBeUndefined();
    }
  });

  it("skips unresolved mods; includes resolved mod hashes", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    expect(doc.parameters?.mods).toEqual([8001, 8002]);
  });

  it("allows duplicate mod hashes", () => {
    const sheet = makeSheet();
    sheet.mods[0].picks[0] = {
      requestedName: "Ashes to Assets",
      resolved: { hash: 8001, name: "Ashes to Assets", icon: null },
      confidence: 1,
      status: "verified",
      legality: { legal: true },
    };
    const dupSheet = makeSheet({
      mods: [
        { slot: "helmet", picks: [sheet.mods[0].picks[0]] },
        { slot: "arms", picks: [sheet.mods[0].picks[0]] },
      ],
    });
    const doc = buildDimLoadout(dupSheet, "Warlock");
    expect(doc.parameters?.mods).toEqual([8001, 8001]);
  });

  it("sets exoticArmorHash from resolved exotic", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    expect(doc.parameters?.exoticArmorHash).toBe(7001);
  });

  it("omits exoticArmorHash when exotic is unresolved", () => {
    const sheet = makeSheet({
      exoticArmor: {
        requestedName: "Sunbracers",
        resolved: null,
        confidence: 0,
        status: "unresolved",
        alternatives: [],
      },
    });
    const doc = buildDimLoadout(sheet, "Warlock");
    expect(doc.parameters?.exoticArmorHash).toBeUndefined();
  });

  it("sorts statConstraints by descending target value", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    const constraints = doc.parameters?.statConstraints ?? [];
    const targets = constraints.map((c) => c.minStat);
    expect(targets).toEqual([...targets].sort((a, b) => (b ?? 0) - (a ?? 0)));
  });

  it("maps stat names to correct hashes", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    const byHash = Object.fromEntries(
      (doc.parameters?.statConstraints ?? []).map((c) => [c.statHash, c.minStat]),
    );
    expect(byHash[4244567218]).toBe(150); // Melee
    expect(byHash[392767087]).toBe(80);   // Health
    expect(byHash[1735777505]).toBe(200); // Grenade
    expect(byHash[144602215]).toBe(100);  // Super
    expect(byHash[1943323491]).toBe(100); // Class
    expect(byHash[2996146975]).toBe(50);  // Weapons
  });

  it("truncates name to 120 chars and notes to 1024 chars", () => {
    const longName = "A".repeat(200);
    const longSummary = "B".repeat(2000);
    const sheet = makeSheet({
      build: { ...minimalBuild, name: longName, summary: longSummary },
    });
    const doc = buildDimLoadout(sheet, "Titan");
    expect(doc.name.length).toBe(120);
    expect(doc.notes?.length).toBe(1024);
  });

  it("sets autoStatMods and includeRuntimeStatBenefits to true", () => {
    const doc = buildDimLoadout(makeSheet(), "Warlock");
    expect(doc.parameters?.autoStatMods).toBe(true);
    expect(doc.parameters?.includeRuntimeStatBenefits).toBe(true);
  });
});
