import { describe, expect, it } from "vitest";

import { validateSynergySubType } from "@/lib/synergies/validateSynergySubType";

describe("validateSynergySubType", () => {
  it("requires subType for verb", () => {
    expect(validateSynergySubType("verb", null).ok).toBe(false);
    expect(validateSynergySubType("verb", "Scorch").ok).toBe(true);
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
