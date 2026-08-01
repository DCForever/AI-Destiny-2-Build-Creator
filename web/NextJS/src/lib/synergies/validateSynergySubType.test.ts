import { describe, expect, it } from "vitest";

import { validateSynergySubType } from "@/lib/synergies/validateSynergySubType";

describe("validateSynergySubType", () => {
  it("requires subType for verb", () => {
    expect(validateSynergySubType("verb", null).ok).toBe(false);
    expect(validateSynergySubType("verb", "Scorch").ok).toBe(true);
  });

  it("rejects unknown verb subType", () => {
    // Lowercase / non-keyword forms (Title Case open keywords may still pass isKeywordLike)
    expect(validateSynergySubType("verb", "foo").ok).toBe(false);
    expect(validateSynergySubType("verb", "not a verb!!!").ok).toBe(false);
  });

  it("accepts Destinypedia verb staples", () => {
    for (const name of ["Sever", "Void Breach", "Exhaust", "Ionic Trace", "Stasis Shard"]) {
      expect(validateSynergySubType("verb", name).ok).toBe(true);
    }
  });

  it("normalizes legacy Suppress alias to Suppression", () => {
    const result = validateSynergySubType("verb", "Suppress");
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.subType).toBe("Suppression");
    }
  });

  it("rejects Base on verb", () => {
    expect(validateSynergySubType("verb", "Base").ok).toBe(false);
  });

  it("allows Base on melee", () => {
    expect(validateSynergySubType("melee", "Base").ok).toBe(true);
  });

  it("allows null subType on dps", () => {
    expect(validateSynergySubType("dps", null).ok).toBe(true);
  });

  it("rejects subType on dps", () => {
    expect(validateSynergySubType("dps", "Extra").ok).toBe(false);
  });

  it.each(["solo", "damage_resist", "general_weapon", "team"] as const)(
    "allows null subType on %s",
    (type) => {
      expect(validateSynergySubType(type, null).ok).toBe(true);
    },
  );

  it.each(["solo", "damage_resist", "general_weapon", "team"] as const)(
    "rejects subType on %s",
    (type) => {
      expect(validateSynergySubType(type, "Extra").ok).toBe(false);
    },
  );

  it("requires Kinetic-capable element subType", () => {
    expect(validateSynergySubType("element", "Kinetic").ok).toBe(true);
    expect(validateSynergySubType("element", "Base").ok).toBe(false);
  });

  it("accepts non-Base subType for weapon_archetype (vocabulary enforced in service)", () => {
    expect(validateSynergySubType("weapon_archetype", "Micro-Missile Frame").ok).toBe(true);
    expect(validateSynergySubType("weapon_archetype", "Pulse Rifle").ok).toBe(true);
    expect(validateSynergySubType("weapon_archetype", "Base").ok).toBe(false);
  });
});
