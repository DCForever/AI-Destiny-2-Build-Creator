import { describe, expect, it } from "vitest";

import { RAW_TABLES } from "../__fixtures__/rawTables";
import type { RawTableName } from "../types/services";
import { abilitiesExtractor } from "./abilities";
import {
  deriveAbilityVerbs,
  deriveSubclassAffinities,
} from "./abilityEnrichment";

function makeLoader() {
  return async (table: RawTableName) => RAW_TABLES[table];
}

describe("deriveSubclassAffinities", () => {
  it("warlock.arc.supers → Stormcaller (not bare Prismatic)", () => {
    const affinities = deriveSubclassAffinities({
      hash: 1018,
      plugCategoryIdentifier: "warlock.arc.supers",
      classType: "Warlock",
      element: "Arc",
    });
    expect(affinities).toContain("Stormcaller");
    expect(affinities).not.toContain("Prismatic");
    expect(affinities.some((a) => a === "Prismatic Warlock")).toBe(false);
  });

  it("Phoenix Dive override adds Dawnblade + Prismatic Warlock", () => {
    const affinities = deriveSubclassAffinities({
      hash: 1026,
      plugCategoryIdentifier: "warlock.solar.class_abilities",
      classType: "Warlock",
      element: "Solar",
    });
    expect(affinities).toEqual(
      expect.arrayContaining(["Dawnblade", "Prismatic Warlock"]),
    );
    expect(affinities).not.toContain("Prismatic");
  });

  it("shared Arc grenade: dedicated Arc subclasses only (no auto Prismatic)", () => {
    const affinities = deriveSubclassAffinities({
      hash: 1019,
      plugCategoryIdentifier: "shared.grenades",
      classType: null,
      element: "Arc",
    });
    expect(affinities).toEqual(
      expect.arrayContaining(["Striker", "Arcstrider", "Stormcaller"]),
    );
    expect(affinities.some((a) => a.startsWith("Prismatic"))).toBe(false);
  });

  it("membership affinities can prove Prismatic without element auto-tag", () => {
    const affinities = deriveSubclassAffinities({
      hash: 999,
      plugCategoryIdentifier: "shared.grenades",
      classType: null,
      element: "Arc",
      membershipAffinities: ["Prismatic Warlock"],
    });
    expect(affinities).toContain("Prismatic Warlock");
  });
});

describe("deriveAbilityVerbs", () => {
  it("Chaos Reach override supplies Jolt", () => {
    expect(
      deriveAbilityVerbs({
        hash: 1018,
        description: "Unleash a long-range Arc beam.",
      }),
    ).toContain("Jolt");
  });

  it("Phoenix Dive override supplies Cure", () => {
    expect(
      deriveAbilityVerbs({
        hash: 1026,
        description: "Dive to the ground and create a burst of Solar Light.",
      }),
    ).toContain("Cure");
  });

  it("word-boundary match finds Cure in description", () => {
    expect(
      deriveAbilityVerbs({
        hash: 1,
        description: "Grants Cure to nearby allies.",
      }),
    ).toContain("Cure");
  });

  it("does not false-positive on casual non-boundary mentions", () => {
    // "jolted" should not match \bJolt\b; no override for hash 2
    expect(
      deriveAbilityVerbs({
        hash: 2,
        description: "You feel jolted by the news of victory.",
      }),
    ).not.toContain("Jolt");
  });

  it("empty when no match and no override", () => {
    expect(
      deriveAbilityVerbs({
        hash: 3,
        description: "A simple ability with no keywords.",
      }),
    ).toEqual([]);
  });

  it("resolves Suppress alias to Suppression", () => {
    expect(
      deriveAbilityVerbs({
        hash: 4,
        description: "Suppress targets on hit.",
      }),
    ).toContain("Suppression");
  });
});

describe("abilitiesExtractor enrichment", () => {
  it("returns 6 abilities including Phoenix Dive", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    expect(records).toHaveLength(6);
  });

  it("Chaos Reach: Stormcaller + Arc + Jolt", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1018);
    expect(rec?.subclassAffinities).toContain("Stormcaller");
    expect(rec?.element).toBe("Arc");
    expect(rec?.verbs).toContain("Jolt");
    expect(Array.isArray(rec?.subclassAffinities)).toBe(true);
    expect(Array.isArray(rec?.verbs)).toBe(true);
  });

  it("Phoenix Dive: Warlock + Dawnblade + Prismatic Warlock + Cure", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1026);
    expect(rec?.classType).toBe("Warlock");
    expect(rec?.subclassAffinities).toEqual(
      expect.arrayContaining(["Dawnblade", "Prismatic Warlock"]),
    );
    expect(rec?.verbs).toContain("Cure");
  });

  it("Pulse Grenade shared affinities exclude Prismatic by default", async () => {
    const records = await abilitiesExtractor.extract(makeLoader());
    const rec = records.find((r) => r.hash === 1019);
    expect(rec?.subclassAffinities).toEqual(
      expect.arrayContaining(["Striker", "Arcstrider", "Stormcaller"]),
    );
    expect(rec?.subclassAffinities.some((a) => a.startsWith("Prismatic"))).toBe(
      false,
    );
  });
});
