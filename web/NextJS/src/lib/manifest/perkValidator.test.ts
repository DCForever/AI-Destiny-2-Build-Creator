import { describe, expect, it } from "vitest";

import { createPerkValidator } from "./perkValidator";
import { normalizeName } from "./normalize";
import type { EntityCache } from "./types/services";
import type { ArtifactRecord, AspectRecord, WeaponRecord } from "./types/records";
import type { EntityStores, StoreName } from "./types/stores";

function baseRecord(
  hash: number,
  name: string,
): { hash: number; name: string; searchName: string; icon: null } {
  return { hash, name, searchName: normalizeName(name), icon: null };
}

const WEAPONS: WeaponRecord[] = [
  {
    ...baseRecord(410412271, "Fatebringer (Timelost)"),
    slot: "Energy",
    element: "Solar",
    ammo: "Primary",
    frame: "Scout Rifle",
    itemTypeName: "Scout Rifle",
    originTraitHashes: [],
    perkColumns: [
      { column: 0, curated: [101], randomized: [102, 103] },
      { column: 2, curated: [201], randomized: [202, 203] },
    ],
  },
  {
    ...baseRecord(1313529544, "The Messenger"),
    slot: "Energy",
    element: "Solar",
    ammo: "Primary",
    frame: "Pulse Rifle",
    itemTypeName: "Pulse Rifle",
    originTraitHashes: [],
    perkColumns: [
      { column: 0, curated: [301], randomized: [302] },
      { column: 1, curated: [], randomized: [401, 402] },
    ],
  },
  {
    ...baseRecord(1667470562, "Palindrome"),
    slot: "Energy",
    element: "Void",
    ammo: "Primary",
    frame: "Hand Cannon",
    itemTypeName: "Hand Cannon",
    originTraitHashes: [],
    perkColumns: [{ column: 0, curated: [501], randomized: [502] }],
  },
  {
    ...baseRecord(3187320019, "Eyasluna"),
    slot: "Energy",
    element: "Arc",
    ammo: "Primary",
    frame: "Hand Cannon",
    itemTypeName: "Hand Cannon",
    originTraitHashes: [],
    perkColumns: [{ column: 0, curated: [601], randomized: [602] }],
  },
];

const ARTIFACTS: ArtifactRecord[] = [
  {
    ...baseRecord(9001, "Avant-Garde"),
    description: "Season artifact.",
    perks: [
      {
        ...baseRecord(9101, "Anti-Barrier Scout Rifle"),
        description: "Scout barrier.",
        column: 0,
        row: 0,
      },
      {
        ...baseRecord(9102, "Overload Submachine Gun"),
        description: "SMG overload.",
        column: 1,
        row: 0,
      },
    ],
  },
  {
    ...baseRecord(9002, "Renegade"),
    description: "Another artifact.",
    perks: [
      {
        ...baseRecord(9201, "Unstoppable Hand Cannon"),
        description: "HC unstoppable.",
        column: 0,
        row: 1,
      },
    ],
  },
  {
    ...baseRecord(9003, "Explorer"),
    description: "Explorer artifact.",
    perks: [],
  },
  {
    ...baseRecord(9004, "Wayfinder"),
    description: "Wayfinder artifact.",
    perks: [
      {
        ...baseRecord(9401, "Arc Siphon"),
        description: "Arc siphon mod.",
        column: 2,
        row: 0,
      },
    ],
  },
];

const ASPECTS: AspectRecord[] = [
  {
    ...baseRecord(8001, "Duskfield Grenade"),
    description: "Stasis aspect.",
    classType: "Titan",
    element: "Stasis",
    fragmentCapacity: 2,
  },
  {
    ...baseRecord(8002, "Glacial Fortification"),
    description: "Stasis aspect.",
    classType: "Titan",
    element: "Stasis",
    fragmentCapacity: 3,
  },
  {
    ...baseRecord(8003, "Winter's Shroud"),
    description: "Stasis aspect.",
    classType: "Hunter",
    element: "Stasis",
    fragmentCapacity: 2,
  },
  {
    ...baseRecord(8004, "Bleak Watcher"),
    description: "Stasis aspect.",
    classType: "Warlock",
    element: "Stasis",
    fragmentCapacity: 3,
  },
];

function createFakeCache(stores: Partial<EntityStores>): EntityCache {
  return {
    getMeta: async () => null,
    rebuild: async () => {
      throw new Error("not implemented in tests");
    },
    getStore: async <TName extends StoreName>(name: TName) => {
      const store = stores[name];
      if (!store) {
        throw new Error(`missing fixture store: ${name}`);
      }
      return store as EntityStores[TName];
    },
  };
}

describe("StorePerkValidator", () => {
  const validator = createPerkValidator(
    createFakeCache({ weapons: WEAPONS, artifacts: ARTIFACTS, aspects: ASPECTS }),
  );

  it("accepts curated weapon perks with column and curated flag", async () => {
    const result = await validator.checkWeaponPerk(410412271, 101);

    expect(result).toEqual({ legal: true, column: 0, curated: true });
  });

  it("accepts randomized weapon perks with column and curated false", async () => {
    const result = await validator.checkWeaponPerk(410412271, 203);

    expect(result).toEqual({ legal: true, column: 2, curated: false });
  });

  it("rejects perks not in the weapon pool", async () => {
    const result = await validator.checkWeaponPerk(410412271, 9999);

    expect(result).toEqual({
      legal: false,
      reason:
        "perk hash 9999 is not available on Fatebringer (Timelost) (hash 410412271)",
    });
  });

  it("rejects unknown legendary weapon hashes", async () => {
    const result = await validator.checkWeaponPerk(3084923842, 101);

    expect(result).toEqual({
      legal: false,
      reason: "weapon hash 3084923842 not found in legendary weapon store",
    });
  });

  it("accepts artifact perks as curated in their column", async () => {
    const result = await validator.checkArtifactPerk(9001, 9102);

    expect(result).toEqual({ legal: true, column: 1, curated: true });
  });

  it("rejects perks that belong to a different artifact", async () => {
    const result = await validator.checkArtifactPerk(9001, 9201);

    expect(result).toEqual({
      legal: false,
      reason:
        "perk hash 9201 is not available on Avant-Garde (hash 9001)",
    });
  });

  it("rejects unknown artifact hashes", async () => {
    const result = await validator.checkArtifactPerk(7777, 9101);

    expect(result).toEqual({
      legal: false,
      reason: "artifact hash 7777 not found in artifact store",
    });
  });

  it("allows fragment counts under total aspect capacity", async () => {
    const result = await validator.checkFragmentCount([8001, 8002], 4);

    expect(result).toEqual({ legal: true, capacity: 5, requested: 4 });
  });

  it("allows fragment counts exactly at capacity", async () => {
    const result = await validator.checkFragmentCount([8001, 8002], 5);

    expect(result).toEqual({ legal: true, capacity: 5, requested: 5 });
  });

  it("rejects fragment counts over capacity", async () => {
    const result = await validator.checkFragmentCount([8001, 8002], 6);

    expect(result).toEqual({ legal: false, capacity: 5, requested: 6 });
  });

  it("returns zero capacity for an empty aspect list", async () => {
    const result = await validator.checkFragmentCount([], 0);

    expect(result).toEqual({ legal: true, capacity: 0, requested: 0 });
  });

  it("ignores unknown aspect hashes when summing capacity", async () => {
    const result = await validator.checkFragmentCount([8001, 9999], 2);

    expect(result).toEqual({ legal: true, capacity: 2, requested: 2 });
  });
});
