import { describe, expect, it } from "vitest";

import type { WeaponPerkColumn } from "@/lib/manifest/types/records";

import { resolveWeaponPerkOptions } from "./weaponPerkOptions";

const PERK_NAMES = new Map<number, string>([
  [10, "Arrowhead Brake"],
  [11, "Fluted Barrel"],
  [20, "Appended Mag"],
  [30, "Rampage"],
  [31, "Frenzy"],
]);

const COLUMNS: WeaponPerkColumn[] = [
  { column: 0, curated: [10], randomized: [10, 11] },
  { column: 1, curated: [20], randomized: [20] },
  { column: 2, curated: [30], randomized: [30, 31, 999] },
];

describe("resolveWeaponPerkOptions", () => {
  it("merges curated and randomized per column and de-duplicates", () => {
    const result = resolveWeaponPerkOptions(1234, { perkColumns: COLUMNS }, PERK_NAMES);
    expect(result.itemHash).toBe(1234);
    expect(result.columns).toHaveLength(3);
    expect(result.columns[0]?.options.map((o) => o.hash)).toEqual([10, 11]);
    expect(result.columns[1]?.options.map((o) => o.hash)).toEqual([20]);
  });

  it("resolves perk names and falls back to the hash string when unknown", () => {
    const result = resolveWeaponPerkOptions(1234, { perkColumns: COLUMNS }, PERK_NAMES);
    expect(result.columns[0]?.options[0]).toEqual({ hash: 10, name: "Arrowhead Brake" });
    const unknown = result.columns[2]?.options.find((o) => o.hash === 999);
    expect(unknown?.name).toBe("999");
  });

  it("returns empty columns for a missing/non-weapon item", () => {
    expect(resolveWeaponPerkOptions(1234, null, PERK_NAMES).columns).toEqual([]);
    expect(resolveWeaponPerkOptions(1234, { perkColumns: [] }, PERK_NAMES).columns).toEqual([]);
  });
});
