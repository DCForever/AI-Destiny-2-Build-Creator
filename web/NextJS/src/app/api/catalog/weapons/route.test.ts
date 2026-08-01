import { describe, expect, it, vi, beforeEach } from "vitest";

import { emptyFilterMessage } from "@/lib/catalog/emptyFilterResult";
import {
  combineWeaponAllowlists,
  resolveOriginTraitFilter,
  resolvePerkFilter,
} from "@/lib/catalog/perkTraitFilters";
import { loadPerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import type { PerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";

vi.mock("@/lib/manifest/perkWeaponIndex", () => ({
  loadPerkWeaponIndex: vi.fn(),
}));

vi.mock("@/lib/catalog/perkTraitFilters", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/catalog/perkTraitFilters")>();
  return {
    ...actual,
    resolvePerkFilter: vi.fn(),
    resolveOriginTraitFilter: vi.fn(),
    combineWeaponAllowlists: vi.fn(actual.combineWeaponAllowlists),
  };
});

describe("weapons catalog route helpers", () => {
  beforeEach(() => {
    vi.mocked(resolvePerkFilter).mockReset();
    vi.mocked(resolveOriginTraitFilter).mockReset();
    vi.mocked(loadPerkWeaponIndex).mockReset();
  });

  it("emptyFilterMessage covers perk filter", () => {
    expect(emptyFilterMessage({ perk: "Foo" })).toContain("Foo");
  });

  it("combineWeaponAllowlists intersects perk and trait hashes", () => {
    const combined = combineWeaponAllowlists(new Set([1, 2]), new Set([2, 3]));
    expect([...(combined ?? [])]).toEqual([2]);
  });

  it("resolvePerkFilter matches description keywords", async () => {
    const actual = await vi.importActual<typeof import("@/lib/catalog/perkTraitFilters")>(
      "@/lib/catalog/perkTraitFilters",
    );
    const perks = [
      {
        hash: 5101,
        name: "Adaptive Munitions",
        searchName: "adaptive munitions",
        description: "Melee final blows.",
        icon: null,
      },
    ];
    const index: PerkWeaponIndex = {
      manifestVersion: "t",
      builtAt: "t",
      byPerk: {
        "5101": [
          {
            weaponHash: 42,
            weaponName: "W",
            slot: "Kinetic",
            itemTypeName: "AR",
            frame: "F",
            column: 1,
            curated: true,
          },
        ],
      },
    };
    const result = actual.resolvePerkFilter("melee", perks, index);
    expect(result.ok).toBe(true);
    if (result.ok) expect([...result.weaponHashes]).toEqual([42]);
  });
});
