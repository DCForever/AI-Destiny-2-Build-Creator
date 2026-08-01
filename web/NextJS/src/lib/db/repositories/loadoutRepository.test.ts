import { describe, it, expect } from "vitest";

import { createTestDb } from "../client";
import { ensureUser } from "./userRepository";
import { createLoadout, listLoadouts, getLoadout } from "./loadoutRepository";
import type { SavedLoadout } from "../types";

const sampleLoadout = (): SavedLoadout => ({
  id: "loadout-1",
  name: "Test Build",
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  manifestVersion: "1.0",
  source: "generator",
  generatedBuild: {
    name: "Test",
    summary: "Test build summary",
    subclass: {
      name: "Sunbreaker",
      super: "Hammer",
      classAbility: "Barricade",
      movement: "Lift",
      melee: "Hammer",
      grenade: "Fire",
      aspects: ["Roaring Flames"],
      fragments: ["Ember of Ashes"],
      rationale: "Test",
    },
    statTargets: [
      { stat: "Health", target: 100, rationale: "Base survivability." },
      { stat: "Melee", target: 100, rationale: "Melee focus." },
      { stat: "Grenade", target: 100, rationale: "Grenade focus." },
      { stat: "Super", target: 100, rationale: "Super focus." },
      { stat: "Class", target: 100, rationale: "Class focus." },
      { stat: "Weapons", target: 100, rationale: "Weapons focus." },
    ],
    exoticArmor: { name: "Hallowfire Heart", rationale: "r", alternatives: [] },
    weapons: [],
    mods: { helmet: [], arms: [], chest: [], legs: [], classItem: [], rationale: "r" },
    armor: { archetype: "Grenadier", rationale: "r" },
    artifact: null,
    gameplayLoop: "Loop",
    acquisitionNotes: "Notes",
  },
  resolvedSheet: {
    build: {
      name: "Test",
      summary: "Test",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      statTargets: [],
      exoticArmor: { name: "H", rationale: "", alternatives: [] },
      weapons: [],
      mods: { helmet: [], arms: [], chest: [], legs: [], classItem: [], rationale: "" },
      armor: { archetype: "Grenadier", rationale: "" },
      artifact: null,
      gameplayLoop: "",
      acquisitionNotes: "",
    },
    activity: "Patrol",
    subclass: { aspects: [], fragments: [], abilities: [], fragmentCheck: null, rationale: "" },
    exoticArmor: { requestedName: "H", resolved: null, confidence: 0, status: "unresolved", alternatives: [] },
    weapons: [],
    statTargets: [],
    mods: [],
    artifact: null,
    championCoverage: { weaponSources: [], subclassSources: [], covered: { Barrier: false, Overload: false, Unstoppable: false } },
    validation: { verified: 0, fuzzy: 0, unresolved: 0, illegalPerks: 0, slotMismatches: 0, remediations: 0 },
  },
});

describe("loadoutRepository", () => {
  it("creates and lists loadouts for a user", () => {
    const db = createTestDb();
    const user = ensureUser(db, "member-1", 3, "Player");
    createLoadout(db, user.id, sampleLoadout());

    const list = listLoadouts(db, user.id);
    expect(list).toHaveLength(1);
    expect(getLoadout(db, user.id, "loadout-1")?.name).toBe("Test Build");
    expect(getLoadout(db, user.id + 1, "loadout-1")).toBeNull();
  });
});
