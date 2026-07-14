import { describe, expect, it } from "vitest";

import {
  evaluateExoticAbilityMatch,
  evaluateExoticLimits,
  evaluateModEnergy,
  evaluateSubclassKit,
  evaluateSynergyRequirement,
  mergeConstraintEvaluations,
} from "./destinyBuildConstraints";

describe("evaluateExoticLimits", () => {
  it("allows one exotic weapon and one exotic armor", () => {
    const r = evaluateExoticLimits({
      exoticWeaponHashes: [100],
      exoticArmorHashes: [200],
    });
    expect(r.hardBlocks).toEqual([]);
  });

  it("blocks two exotic weapons", () => {
    const r = evaluateExoticLimits({
      exoticWeaponHashes: [1, 2],
      exoticArmorHashes: [],
    });
    expect(r.hardBlocks).toHaveLength(1);
    expect(r.hardBlocks[0]!.code).toBe("TOO_MANY_EXOTICS");
    expect(r.hardBlocks[0]!.message).toMatch(/exotic weapon/i);
  });

  it("blocks two exotic armor pieces", () => {
    const r = evaluateExoticLimits({
      exoticWeaponHashes: [],
      exoticArmorHashes: [10, 20],
    });
    expect(r.hardBlocks[0]!.message).toMatch(/exotic armor/i);
  });

  it("dedupes the same exotic hash", () => {
    const r = evaluateExoticLimits({
      exoticWeaponHashes: [5, 5],
      exoticArmorHashes: [9, 9, 9],
    });
    expect(r.hardBlocks).toEqual([]);
  });

  it("ignores zero/invalid hashes", () => {
    const r = evaluateExoticLimits({
      exoticWeaponHashes: [0, -1, 3],
      exoticArmorHashes: [4],
    });
    expect(r.hardBlocks).toEqual([]);
  });
});

describe("evaluateSynergyRequirement", () => {
  it("blocks empty synergy list", () => {
    expect(evaluateSynergyRequirement([]).hardBlocks[0]!.code).toBe("NO_SYNERGY");
  });

  it("allows non-empty", () => {
    expect(evaluateSynergyRequirement([{ type: "verb" }]).hardBlocks).toEqual([]);
  });
});

describe("mergeConstraintEvaluations", () => {
  it("concatenates blocks", () => {
    const r = mergeConstraintEvaluations(
      evaluateSynergyRequirement([]),
      evaluateExoticLimits({ exoticWeaponHashes: [1, 2], exoticArmorHashes: [] }),
    );
    expect(r.hardBlocks).toHaveLength(2);
  });
});

describe("evaluateSubclassKit", () => {
  it("blocks more than 2 aspects", () => {
    const r = evaluateSubclassKit({
      aspectCount: 3,
      fragmentCount: 0,
      fragmentCapacity: 0,
    });
    expect(r.hardBlocks[0]!.code).toBe("ILLEGAL_SUBCLASS_KIT");
    expect(r.hardBlocks[0]!.message).toMatch(/aspects/i);
  });

  it("blocks fragments over capacity", () => {
    const r = evaluateSubclassKit({
      aspectCount: 2,
      fragmentCount: 5,
      fragmentCapacity: 4,
    });
    expect(r.hardBlocks.some((b) => b.message.includes("fragments"))).toBe(true);
  });

  it("allows fragments at capacity", () => {
    const r = evaluateSubclassKit({
      aspectCount: 2,
      fragmentCount: 4,
      fragmentCapacity: 4,
    });
    expect(r.hardBlocks).toEqual([]);
  });

  it("skips fragment check when capacity not resolved", () => {
    const r = evaluateSubclassKit({
      aspectCount: 2,
      fragmentCount: 99,
      fragmentCapacity: 0,
      capacityResolved: false,
    });
    expect(r.hardBlocks).toEqual([]);
  });
});

describe("evaluateModEnergy", () => {
  it("blocks over-capacity pieces", () => {
    const r = evaluateModEnergy([
      { slot: "Helmet", energyUsed: 12, energyCapacity: 10 },
    ]);
    expect(r.hardBlocks[0]!.code).toBe("MOD_ENERGY_EXCEEDED");
  });

  it("allows under capacity", () => {
    expect(
      evaluateModEnergy([{ slot: "Arms", energyUsed: 10, energyCapacity: 10 }])
        .hardBlocks,
    ).toEqual([]);
  });
});

describe("evaluateExoticAbilityMatch", () => {
  it("blocks mismatched super", () => {
    const r = evaluateExoticAbilityMatch({
      required: { super: "Thundercrash" },
      kit: { super: "Hammer of Sol" },
      pinnedSuper: null,
    });
    expect(r.hardBlocks[0]!.code).toBe("EXOTIC_ABILITY_MISMATCH");
  });

  it("accepts pinned super over kit super", () => {
    const r = evaluateExoticAbilityMatch({
      required: { super: "Thundercrash" },
      kit: { super: "Hammer of Sol" },
      pinnedSuper: "Thundercrash",
    });
    expect(r.hardBlocks).toEqual([]);
  });

  it("no-ops when no requirements", () => {
    expect(
      evaluateExoticAbilityMatch({
        required: {},
        kit: { super: "X" },
      }).hardBlocks,
    ).toEqual([]);
  });
});
