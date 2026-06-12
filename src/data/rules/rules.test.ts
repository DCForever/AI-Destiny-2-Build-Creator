import { describe, expect, it } from "vitest";

import { isArtifactAllowed } from "./activityRules";
import { ARMOR_ARCHETYPES, findArchetypeByName, findArchetypesForStat } from "./armorArchetypes";
import { getChampionCounterForFrame, SUBCLASS_VERB_COUNTERS } from "./championCounters";
import { computeBenefitsAt } from "./statBenefits";

describe("getChampionCounterForFrame", () => {
  it("maps base weapon-type families", () => {
    expect(getChampionCounterForFrame("Adaptive Frame", "Scout Rifle")).toBe("Barrier");
    expect(getChampionCounterForFrame("Aggressive Frame", "Shotgun")).toBe("Unstoppable");
    expect(getChampionCounterForFrame("Lightweight Frame", "Bow")).toBe("Overload");
    expect(getChampionCounterForFrame("High-Impact Frame", "Pulse Rifle")).toBe("Unstoppable");
    expect(getChampionCounterForFrame("Rapid-Fire Frame", "Sniper Rifle")).toBe("Overload");
    expect(getChampionCounterForFrame("Precision Frame", "Hand Cannon")).toBe("Barrier");
  });

  it("applies frame-specific overrides before the base map", () => {
    // Wave GL would be Overload-ish by no base family; the override says Unstoppable.
    expect(getChampionCounterForFrame("Wave Frame", "Grenade Launcher")).toBe("Unstoppable");
    // Caster Sword overrides to Barrier.
    expect(getChampionCounterForFrame("Caster Frame", "Sword")).toBe("Barrier");
    // Support AR is Overload despite no base family for "support".
    expect(getChampionCounterForFrame("Support Frame", "Auto Rifle")).toBe("Overload");
    // Adaptive Burst LFR stays Barrier via override (not the adaptive base rule).
    expect(getChampionCounterForFrame("Adaptive Burst", "Linear Fusion Rifle")).toBe("Barrier");
    // Heavy Burst differs by weapon type only via overrides.
    expect(getChampionCounterForFrame("Heavy Burst", "Hand Cannon")).toBe("Unstoppable");
    expect(getChampionCounterForFrame("Spread Shot Frame", "Hand Cannon")).toBe("Overload");
  });

  it("override weapon type must match for type-specific rules", () => {
    // "Wave Frame" on a Sword is Unstoppable via the sword override.
    expect(getChampionCounterForFrame("Wave Frame", "Sword")).toBe("Unstoppable");
    // Aggressive Burst on SMG and Pulse both Unstoppable.
    expect(getChampionCounterForFrame("Aggressive Burst", "Submachine Gun")).toBe("Unstoppable");
    expect(getChampionCounterForFrame("Aggressive Burst", "Pulse Rifle")).toBe("Unstoppable");
  });

  it("returns null for unknown frames and blank input", () => {
    expect(getChampionCounterForFrame("Märchen Frame", "Auto Rifle")).toBeNull();
    expect(getChampionCounterForFrame("", "Auto Rifle")).toBeNull();
  });

  it("encodes the 9.7.0 verb corrections", () => {
    expect(SUBCLASS_VERB_COUNTERS["shatter"]).toBe("Unstoppable");
    expect(SUBCLASS_VERB_COUNTERS["jolt"]).toBe("Overload");
    expect(SUBCLASS_VERB_COUNTERS["radiant"]).toBeUndefined();
    expect(SUBCLASS_VERB_COUNTERS["volatile rounds"]).toBeUndefined();
  });
});

describe("computeBenefitsAt", () => {
  it("interpolates enhanced benefits linearly from 101 to 200", () => {
    const at200 = computeBenefitsAt("Melee", 200);
    expect(at200).toContain("+30% melee ability damage");

    const at150 = computeBenefitsAt("Grenade", 150);
    expect(at150).toContain("+33% grenade ability damage");

    const at120 = computeBenefitsAt("Class", 120);
    expect(at120).toContain("8 HP overshield on casting your class ability (PvE)");
  });

  it("omits enhanced benefits at or below 100", () => {
    const at100 = computeBenefitsAt("Super", 100);
    expect(at100.join(" ")).not.toContain("Super ability damage");

    const at60 = computeBenefitsAt("Grenade", 60);
    expect(at60.join(" ")).not.toContain("grenade ability damage");
  });

  it("scales base benefits across 0-100", () => {
    const at50 = computeBenefitsAt("Health", 50);
    expect(at50).toContain("+35 HP healing when picking up an Orb of Power");
    expect(at50).toContain("+5% flinch resistance");
  });

  it("includes weapons boss-damage split at 200", () => {
    const at200 = computeBenefitsAt("Weapons", 200);
    expect(at200).toContain("+15% damage vs bosses (primary and special, PvE)");
    expect(at200).toContain("+10% damage vs bosses (heavy, PvE)");
    expect(at200).toContain("+6% weapon damage vs Guardians (PvP)");
  });
});

describe("armor archetypes", () => {
  it("has all 12 archetypes, six of them new in 9.7.0", () => {
    expect(ARMOR_ARCHETYPES).toHaveLength(12);
    expect(ARMOR_ARCHETYPES.filter((a) => a.addedIn970)).toHaveLength(6);
  });

  it("finds archetypes by name case-insensitively", () => {
    expect(findArchetypeByName("powerhouse")?.primary).toBe("Weapons");
    expect(findArchetypeByName("Nonexistent")).toBeNull();
    expect(findArchetypeByName(" ")).toBeNull();
  });

  it("finds archetypes serving a stat", () => {
    const grenadeOptions = findArchetypesForStat("Grenade").map((a) => a.name);
    expect(grenadeOptions).toEqual(
      expect.arrayContaining(["Grenadier", "Gunner", "Siegebreaker", "Demolitionist"]),
    );
  });
});

describe("isArtifactAllowed", () => {
  it("disables artifacts in Trials and Competitive only", () => {
    expect(isArtifactAllowed("Trials of Osiris")).toBe(false);
    expect(isArtifactAllowed("competitive crucible")).toBe(false);
    expect(isArtifactAllowed("Grandmaster Nightfall")).toBe(true);
    expect(isArtifactAllowed("Raid: The Desert Perpetual")).toBe(true);
  });
});
