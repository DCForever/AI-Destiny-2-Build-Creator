import { describe, expect, it } from "vitest";

import {
  buildWeaponRollDetail,
  weaponRollDetailHasContent,
} from "@/lib/presentation/weaponRollDetail";

describe("buildWeaponRollDetail", () => {
  const names = new Map<number, string>([
    [100, "Barrel A"],
    [200, "Zen Moment"],
    [201, "Zen Moment Enhanced"],
    [300, "Adagio"],
  ]);

  it("maps selected plugs with primary names (never bare hash)", () => {
    const d = buildWeaponRollDetail({
      selectedPerkHashes: [200, 999],
      perkNames: names,
    });
    expect(d.selectedPlugs[0]?.primary).toBe("Zen Moment");
    expect(d.selectedPlugs[0]?.footer).toBe("#200");
    expect(d.selectedPlugs[1]?.primary).toBe("Unknown plug");
    expect(d.selectedPlugs[1]?.footer).toBe("#999");
  });

  it("builds can-roll columns from perk columns with curated flags", () => {
    const d = buildWeaponRollDetail({
      perkColumns: [
        { column: 0, curated: [100], randomized: [] },
        { column: 2, curated: [200], randomized: [201, 300] },
      ],
      perkNames: names,
    });
    expect(d.canRollColumns).toHaveLength(2);
    expect(d.canRollColumns[0]?.label).toBe("Barrel");
    expect(d.canRollColumns[1]?.label).toBe("Trait 1");
    const traitPlugs = d.canRollColumns[1]?.plugs ?? [];
    expect(traitPlugs.map((p) => p.primary)).toEqual([
      "Zen Moment",
      "Zen Moment Enhanced",
      "Adagio",
    ]);
    expect(traitPlugs.find((p) => p.hash === 200)?.curated).toBe(true);
    expect(traitPlugs.find((p) => p.hash === 300)?.curated).toBe(false);
  });

  it("omits craft when unknown; keeps flags when known", () => {
    expect(buildWeaponRollDetail({}).craft).toBeNull();
    expect(
      buildWeaponRollDetail({ craft: { isCrafted: true } }).craft,
    ).toEqual({ isCrafted: true });
    expect(
      buildWeaponRollDetail({ craft: {} }).craft,
    ).toBeNull();
  });

  it("weaponRollDetailHasContent", () => {
    expect(weaponRollDetailHasContent(buildWeaponRollDetail({}))).toBe(false);
    expect(
      weaponRollDetailHasContent(
        buildWeaponRollDetail({ selectedPerkHashes: [1], perkNames: names }),
      ),
    ).toBe(true);
  });
});
