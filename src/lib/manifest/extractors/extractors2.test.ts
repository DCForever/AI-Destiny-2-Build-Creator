/**
 * Unit tests for: aspects, fragments, abilities, mods, setBonuses, stats.
 */

import { describe, it, expect } from "vitest";
import { RAW_TABLES } from "../__fixtures__/rawTables";
import type { RawTableName } from "../types/services";
import { aspectsExtractor } from "./aspects";
import { fragmentsExtractor } from "./fragments";
import { abilitiesExtractor } from "./abilities";
import { modsExtractor } from "./mods";
import { setBonusesExtractor } from "./setBonuses";
import { statsExtractor } from "./stats";

function makeLoader() {
  return async (table: RawTableName) => RAW_TABLES[table];
}

// ─── Aspects ──────────────────────────────────────────────────────────────

describe("aspectsExtractor", () => {
  it("returns exactly 2 aspects", async () => {
    const records = await aspectsExtractor.extract(makeLoader());
    expect(records).toHaveLength(2);
  });

  it("Touch of Thunder: Hunter, Arc, fragmentCapacity 4", async () => {
    const records = await aspectsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1014);
    expect(rec?.name).toBe("Touch of Thunder");
    expect(rec?.classType).toBe("Hunter");
    expect(rec?.element).toBe("Arc");
    expect(rec?.fragmentCapacity).toBe(4);
  });

  it("Consecration: Titan, Solar, fragmentCapacity 2", async () => {
    const records = await aspectsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1015);
    expect(rec?.name).toBe("Consecration");
    expect(rec?.classType).toBe("Titan");
    expect(rec?.element).toBe("Solar");
    expect(rec?.fragmentCapacity).toBe(2);
  });
});

// ─── Fragments ────────────────────────────────────────────────────────────

describe("fragmentsExtractor", () => {
  it("returns exactly 2 fragments", async () => {
    const records = await fragmentsExtractor.extract(makeLoader());
    expect(records).toHaveLength(2);
  });

  it("Spark of Brilliance: Arc, no stat modifiers", async () => {
    const records = await fragmentsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1016);
    expect(rec?.element).toBe("Arc");
    expect(rec?.statModifiers).toEqual({});
  });

  it("Echo of Undermining: Void, Strength -10", async () => {
    const records = await fragmentsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1017);
    expect(rec?.element).toBe("Void");
    expect(rec?.statModifiers).toEqual({ Strength: -10 });
  });
});

// ─── Abilities ────────────────────────────────────────────────────────────

describe("abilitiesExtractor", () => {
  it("returns exactly 6 abilities (kinds + Phoenix Dive)", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    expect(records).toHaveLength(6);
  });

  it("Chaos Reach: super, Warlock, Arc, Stormcaller, Jolt", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1018);
    expect(rec?.kind).toBe("super");
    expect(rec?.classType).toBe("Warlock");
    expect(rec?.element).toBe("Arc");
    expect(rec?.subclassAffinities).toContain("Stormcaller");
    expect(rec?.verbs).toContain("Jolt");
  });

  it("Phoenix Dive: classAbility, Warlock, Dawnblade + Prismatic Warlock, Cure", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1026);
    expect(rec?.kind).toBe("classAbility");
    expect(rec?.classType).toBe("Warlock");
    expect(rec?.subclassAffinities).toEqual(
      expect.arrayContaining(["Dawnblade", "Prismatic Warlock"]),
    );
    expect(rec?.verbs).toContain("Cure");
  });

  it("Pulse Grenade: grenade, classType null (shared), Arc", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1019);
    expect(rec?.kind).toBe("grenade");
    expect(rec?.classType).toBeNull();
    expect(rec?.element).toBe("Arc");
  });

  it("Storm Fist: melee, Titan, Arc", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1020);
    expect(rec?.kind).toBe("melee");
    expect(rec?.classType).toBe("Titan");
  });

  it("Gambler's Dodge: classAbility, Hunter", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1021);
    expect(rec?.kind).toBe("classAbility");
    expect(rec?.classType).toBe("Hunter");
  });

  it("Burst Glide: movement, Warlock", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1022);
    expect(rec?.kind).toBe("movement");
    expect(rec?.classType).toBe("Warlock");
  });
});

// ─── Mods ─────────────────────────────────────────────────────────────────

describe("modsExtractor", () => {
  it("returns unique mods (dedupes cheap artifact variants)", async () => {
    const records = await modsExtractor.extract(makeLoader());
    // 1028 (1 energy) + 1029 (2 energy) Focusing Strike → keep one
    expect(records).toHaveLength(5);
    const focusing = records.filter((r) => r.name === "Focusing Strike");
    expect(focusing).toHaveLength(1);
    expect(focusing[0]?.energyCost).toBe(2);
    expect(focusing[0]?.hash).toBe(1029);
  });

  it("Charged Up: helmet slot, energyCost 1", async () => {
    const records = await modsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1023);
    expect(rec?.slotCategory).toBe("helmet");
    expect(rec?.energyCost).toBe(1);
  });

  it("Special Ammo Finder: general slot, energyCost 0", async () => {
    const records = await modsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1024);
    expect(rec?.slotCategory).toBe("general");
    expect(rec?.energyCost).toBe(0);
  });

  it("Harmonic Tuning: tuning slot, energyCost null", async () => {
    const records = await modsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1025);
    expect(rec?.slotCategory).toBe("tuning");
    expect(rec?.energyCost).toBeNull();
  });

  it("fills blank display description from tooltip when no sandbox effect", async () => {
    const records = await modsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1027);
    expect(rec?.description).toMatch(/find ammo more quickly/i);
    expect(rec?.slotCategory).toBe("helmet");
    expect(rec?.energyCost).toBe(1);
  });

  it("prefers sandbox perk effect over stacking-only tooltip", async () => {
    const records = await modsExtractor.extract(makeLoader());
    // 1029 wins dedupe (higher energy) over cheap 1028; both share sandbox effect
    const rec = records.find((r) => r.name === "Focusing Strike");
    expect(rec?.hash).toBe(1029);
    expect(rec?.description).toMatch(/class ability energy/i);
    expect(rec?.description).toMatch(/powered melee/i);
    expect(rec?.description).not.toMatch(/multiple copies/i);
  });
});

// ─── Set Bonuses ──────────────────────────────────────────────────────────

describe("setBonusesExtractor", () => {
  it("returns exactly 1 set bonus", async () => {
    const records = await setBonusesExtractor.extract(makeLoader());
    expect(records).toHaveLength(1);
  });

  it("projects Hive Mind", async () => {
    const [rec] = await setBonusesExtractor.extract(makeLoader());
    expect(rec.hash).toBe(9001);
    expect(rec.name).toBe("Hive Mind");
    expect(rec.searchName).toBe("hive mind");
    expect(rec.itemHashes).toContain(1007);
  });

  it("has 1 perk with requiredCount 2", async () => {
    const [rec] = await setBonusesExtractor.extract(makeLoader());
    expect(rec.perks).toHaveLength(1);
    expect(rec.perks[0].requiredCount).toBe(2);
    expect(rec.perks[0].name).toBe("Hive Mind");
    expect(rec.perks[0].description).toContain("2-piece");
  });
});

// ─── Stats ────────────────────────────────────────────────────────────────

describe("statsExtractor", () => {
  it("returns 7 stats (6 armor + Aspect Energy Capacity)", async () => {
    const records = await statsExtractor.extract(makeLoader());
    expect(records).toHaveLength(7);
  });

  it("includes all six Armor 3.0 stats", async () => {
    const records = await statsExtractor.extract(makeLoader());
    const names = records.map((r) => r.name);
    expect(names).toContain("Mobility");
    expect(names).toContain("Resilience");
    expect(names).toContain("Recovery");
    expect(names).toContain("Discipline");
    expect(names).toContain("Intellect");
    expect(names).toContain("Strength");
  });

  it("includes Aspect Energy Capacity (hash 2223994109)", async () => {
    const records = await statsExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 2223994109);
    expect(rec?.name).toBe("Aspect Energy Capacity");
  });
});
