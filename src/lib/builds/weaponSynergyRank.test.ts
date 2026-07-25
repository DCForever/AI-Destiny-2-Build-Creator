import { describe, expect, it } from "vitest";

import { rankWeaponsBySynergyMatch } from "./weaponSynergyRank";

describe("rankWeaponsBySynergyMatch", () => {
  it("puts matching hashes first and marks them", () => {
    const items = [
      { hash: 1, name: "A" },
      { hash: 2, name: "B" },
      { hash: 3, name: "C" },
    ];
    const ranked = rankWeaponsBySynergyMatch(items, new Set([3, 1]));
    expect(ranked.map((r) => r.hash)).toEqual([1, 3, 2]);
    expect(ranked.filter((r) => r.synergyMatch).map((r) => r.hash).sort()).toEqual([1, 3]);
  });

  it("preserves order when no matches", () => {
    const items = [
      { hash: 9, name: "X" },
      { hash: 8, name: "Y" },
    ];
    expect(rankWeaponsBySynergyMatch(items, new Set()).map((r) => r.hash)).toEqual([9, 8]);
  });
});
