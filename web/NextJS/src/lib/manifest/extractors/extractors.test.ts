/**
 * Unit tests for: exoticArmor, exoticWeapons, weapons, weaponPerks, originTraits, artifacts.
 */

import { describe, it, expect } from "vitest";
import { RAW_TABLES } from "../__fixtures__/rawTables";
import type { RawTableName } from "../types/services";
import { exoticArmorExtractor } from "./exoticArmor";
import { exoticWeaponsExtractor } from "./exoticWeapons";
import { weaponsExtractor } from "./weapons";
import { weaponPerksExtractor } from "./weaponPerks";
import { originTraitsExtractor } from "./originTraits";
import { artifactsExtractor } from "./artifacts";

function makeLoader() {
  return async (table: RawTableName) => RAW_TABLES[table];
}

// ─── Exotic Armor ─────────────────────────────────────────────────────────

describe("exoticArmorExtractor", () => {
  it("returns exactly 1 record", async () => {
    const records = await exoticArmorExtractor.extract(makeLoader());
    expect(records).toHaveLength(1);
  });

  it("projects core fields for Celestial Nighthawk", async () => {
    const [rec] = await exoticArmorExtractor.extract(makeLoader());
    expect(rec.hash).toBe(1001);
    expect(rec.name).toBe("Celestial Nighthawk");
    expect(rec.searchName).toBe("celestial nighthawk");
    expect(rec.classType).toBe("Hunter");
    expect(rec.slot).toBe("Helmet");
    expect(rec.icon).toBe("/nighthawk.png");
    expect(rec.flavorText).toBe("It's a space monocle.");
  });

  it("resolves intrinsic perk", async () => {
    const [rec] = await exoticArmorExtractor.extract(makeLoader());
    expect(rec.intrinsic.name).toBe("Hawkeye Hack");
    expect(rec.intrinsic.description).toContain("Golden Gun");
  });

  it("resolves archetype", async () => {
    const [rec] = await exoticArmorExtractor.extract(makeLoader());
    expect(rec.archetype).toBe("Celestial Archetype");
  });
});

// ─── Exotic Weapons ───────────────────────────────────────────────────────

describe("exoticWeaponsExtractor", () => {
  it("returns exactly 1 record", async () => {
    const records = await exoticWeaponsExtractor.extract(makeLoader());
    expect(records).toHaveLength(1);
  });

  it("projects core fields for Gjallarhorn", async () => {
    const [rec] = await exoticWeaponsExtractor.extract(makeLoader());
    expect(rec.hash).toBe(1004);
    expect(rec.name).toBe("Gjallarhorn");
    expect(rec.slot).toBe("Power");
    expect(rec.element).toBe("Solar");
    expect(rec.ammo).toBe("Heavy");
    expect(rec.flavorText).toBe("Light the way.");
  });

  it("resolves intrinsic frame (Wolfpack Rounds)", async () => {
    const [rec] = await exoticWeaponsExtractor.extract(makeLoader());
    expect(rec.frame).toBe("Wolfpack Rounds");
    expect(rec.intrinsic.name).toBe("Wolfpack Rounds");
    expect(rec.intrinsic.description).toContain("cluster missiles");
  });

  it("resolves catalyst", async () => {
    const [rec] = await exoticWeaponsExtractor.extract(makeLoader());
    expect(rec.catalyst).not.toBeNull();
    expect(rec.catalyst?.name).toBe("Gjallarhorn Catalyst");
  });
});

// ─── Legendary Weapons ────────────────────────────────────────────────────

describe("weaponsExtractor", () => {
  it("returns exactly 1 record", async () => {
    const records = await weaponsExtractor.extract(makeLoader());
    expect(records).toHaveLength(1);
  });

  it("projects core fields for Chattering Bone", async () => {
    const [rec] = await weaponsExtractor.extract(makeLoader());
    expect(rec.hash).toBe(1007);
    expect(rec.name).toBe("Chattering Bone");
    expect(rec.slot).toBe("Kinetic");
    expect(rec.element).toBe("Stasis");
    expect(rec.ammo).toBe("Primary");
    expect(rec.frame).toBe("Precision Frame");
    expect(rec.itemTypeName).toBe("Pulse Rifle");
  });

  it("extracts origin trait hashes", async () => {
    const [rec] = await weaponsExtractor.extract(makeLoader());
    expect(rec.originTraitHashes).toContain(1009);
    expect(rec.originTraitHashes).toHaveLength(1);
  });

  it("extracts 2 perk columns", async () => {
    const [rec] = await weaponsExtractor.extract(makeLoader());
    expect(rec.perkColumns).toHaveLength(2);
  });

  it("column 0 is barrels (curated-only)", async () => {
    const [rec] = await weaponsExtractor.extract(makeLoader());
    const col0 = rec.perkColumns.find((c) => c.column === 0);
    expect(col0?.curated).toEqual(expect.arrayContaining([1010, 1011]));
    expect(col0?.randomized).toHaveLength(0);
  });

  it("column 1 has curated and randomized traits", async () => {
    const [rec] = await weaponsExtractor.extract(makeLoader());
    const col1 = rec.perkColumns.find((c) => c.column === 1);
    expect(col1?.curated).toContain(1012);
    expect(col1?.randomized).toEqual(expect.arrayContaining([1012, 1013]));
  });
});

// ─── Weapon Perks ─────────────────────────────────────────────────────────

describe("weaponPerksExtractor", () => {
  it("returns legendary barrels/traits plus exotic intrinsic", async () => {
    const records = await weaponPerksExtractor.extract(makeLoader());
    // 4 legendary (2 barrels + 2 traits) + Gjallarhorn Wolfpack Rounds intrinsic
    expect(records).toHaveLength(5);
  });

  it("includes barrel perks", async () => {
    const records = await weaponPerksExtractor.extract(makeLoader());
    const hashes = records.map((r) => r.hash);
    expect(hashes).toContain(1010);
    expect(hashes).toContain(1011);
  });

  it("includes trait perks", async () => {
    const records = await weaponPerksExtractor.extract(makeLoader());
    const hashes = records.map((r) => r.hash);
    expect(hashes).toContain(1012);
    expect(hashes).toContain(1013);
  });

  it("perk record has name + description", async () => {
    const records = await weaponPerksExtractor.extract(makeLoader());
    const killClip = records.find((r) => r.hash === 1012);
    expect(killClip?.name).toBe("Kill Clip");
    expect(killClip?.searchName).toBe("kill clip");
    expect(killClip?.description).toBeTruthy();
    expect(killClip?.source).toBe("legendary");
  });

  it("marks exotic intrinsic plugs as exotic source", async () => {
    const records = await weaponPerksExtractor.extract(makeLoader());
    const wolfpack = records.find((r) => r.hash === 1005);
    expect(wolfpack?.name).toBe("Wolfpack Rounds");
    expect(wolfpack?.source).toBe("exotic");
  });
});

// ─── Origin Traits ────────────────────────────────────────────────────────

describe("originTraitsExtractor", () => {
  it("returns exactly 1 origin trait", async () => {
    const records = await originTraitsExtractor.extract(makeLoader());
    expect(records).toHaveLength(1);
  });

  it("projects Tex Balanced Stock", async () => {
    const [rec] = await originTraitsExtractor.extract(makeLoader());
    expect(rec.hash).toBe(1009);
    expect(rec.name).toBe("Tex Balanced Stock");
    expect(rec.description).toContain("stability");
  });
});

// ─── Artifacts ────────────────────────────────────────────────────────────

describe("artifactsExtractor", () => {
  it("returns exactly 1 artifact", async () => {
    const records = await artifactsExtractor.extract(makeLoader());
    expect(records).toHaveLength(1);
  });

  it("projects Disc of Pestilence", async () => {
    const [rec] = await artifactsExtractor.extract(makeLoader());
    expect(rec.hash).toBe(6001);
    expect(rec.name).toBe("Disc of Pestilence");
    expect(rec.icon).toBe("/artifact.png");
  });

  it("has 3 perks across 2 columns", async () => {
    const [rec] = await artifactsExtractor.extract(makeLoader());
    expect(rec.perks).toHaveLength(3);
  });

  it("perk column and row indices are correct", async () => {
    const [rec] = await artifactsExtractor.extract(makeLoader());
    const col0 = rec.perks.filter((p) => p.column === 0);
    const col1 = rec.perks.filter((p) => p.column === 1);
    expect(col0).toHaveLength(2);
    expect(col1).toHaveLength(1);
    expect(col0[0].row).toBe(0);
    expect(col0[1].row).toBe(1);
    expect(col1[0].row).toBe(0);
  });

  it("fills perk description from sandbox perk when inventory description is blank", async () => {
    const [rec] = await artifactsExtractor.extract(makeLoader());
    const volatile = rec.perks.find((p) => p.name === "Volatile Flow");
    expect(volatile?.description).toContain("Volatile Rounds");
  });

  it("keeps inventory description when present", async () => {
    const [rec] = await artifactsExtractor.extract(makeLoader());
    const overload = rec.perks.find((p) => p.name === "Overload Auto Rifles");
    expect(overload?.description).toContain("Overload champions");
  });

  it("labels each perk with its parent artifact name", async () => {
    const [rec] = await artifactsExtractor.extract(makeLoader());
    expect(rec.perks.every((p) => p.artifactName === "Disc of Pestilence")).toBe(
      true,
    );
  });
});
