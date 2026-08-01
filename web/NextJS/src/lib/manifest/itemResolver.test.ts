import { describe, expect, it } from "vitest";

import { createItemResolver } from "./itemResolver";
import { normalizeName } from "./normalize";
import type { EntityCache } from "./types/services";
import type {
  ArtifactRecord,
  ExoticArmorRecord,
  ExoticWeaponRecord,
  WeaponRecord,
} from "./types/records";
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

const EXOTIC_WEAPONS: ExoticWeaponRecord[] = [
  {
    ...baseRecord(3084923842, "Le Monarque"),
    slot: "Kinetic",
    element: "Void",
    ammo: "Primary",
    frame: "Combat Bow",
    intrinsic: { name: "Poison Arrows", description: "Poison on full draw." },
    catalyst: null,
    flavorText: "Queen's bow.",
  },
  {
    ...baseRecord(157469160, "Izanagi's Burden"),
    slot: "Kinetic",
    element: "Kinetic",
    ammo: "Special",
    frame: "Sniper Rifle",
    intrinsic: { name: "Honed Edge", description: "Hold reload to consume mag." },
    catalyst: null,
    flavorText: "Black Armory.",
  },
  {
    ...baseRecord(347366834, "Thorn"),
    slot: "Kinetic",
    element: "Kinetic",
    ammo: "Primary",
    frame: "Hand Cannon",
    intrinsic: { name: "Mark of Devourer", description: "DoT rounds." },
    catalyst: null,
    flavorText: "Rose's shadow.",
  },
  {
    ...baseRecord(127, "Witherhoard"),
    slot: "Kinetic",
    element: "Kinetic",
    ammo: "Special",
    frame: "Grenade Launcher",
    intrinsic: { name: "Prime and Detonate", description: "Blight pools." },
    catalyst: null,
    flavorText: "Taken slime.",
  },
];

const EXOTIC_ARMOR: ExoticArmorRecord[] = [
  {
    ...baseRecord(3341713435, "Heart of Inmost Light"),
    classType: "Titan",
    slot: "Chest",
    intrinsic: { name: "Inmost Light", description: "Ability loop." },
    archetype: null,
    flavorText: "Inner fire.",
  },
  {
    ...baseRecord(2273643087, "Ophidia Spathe"),
    classType: "Hunter",
    slot: "Gauntlets",
    intrinsic: { name: "Knife Trick", description: "Extra knives." },
    archetype: null,
    flavorText: "Blades.",
  },
  {
    ...baseRecord(2276473669, "Nezarec's Sin"),
    classType: "Warlock",
    slot: "Helmet",
    intrinsic: { name: "Sin", description: "Void kills grant buffs." },
    archetype: null,
    flavorText: "Whisper.",
  },
  {
    ...baseRecord(235591051, "Starfire Protocol"),
    classType: "Warlock",
    slot: "Chest",
    intrinsic: { name: "Fusion Grenade", description: "Rifts on fusion kills." },
    archetype: null,
    flavorText: "Sunfire.",
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

const ASPECTS = [
  {
    ...baseRecord(8001, "Duskfield Grenade"),
    description: "Stasis aspect.",
    classType: "Titan" as const,
    element: "Stasis" as const,
    fragmentCapacity: 2,
  },
  {
    ...baseRecord(8002, "Glacial Fortification"),
    description: "Stasis aspect.",
    classType: "Titan" as const,
    element: "Stasis" as const,
    fragmentCapacity: 3,
  },
  {
    ...baseRecord(8003, "Winter's Shroud"),
    description: "Stasis aspect.",
    classType: "Hunter" as const,
    element: "Stasis" as const,
    fragmentCapacity: 2,
  },
  {
    ...baseRecord(8004, "Bleak Watcher"),
    description: "Stasis aspect.",
    classType: "Warlock" as const,
    element: "Stasis" as const,
    fragmentCapacity: 3,
  },
];

const FIXTURE_STORES: Partial<EntityStores> = {
  weapons: WEAPONS,
  "exotic-weapons": EXOTIC_WEAPONS,
  "exotic-armor": EXOTIC_ARMOR,
  artifacts: ARTIFACTS,
  aspects: ASPECTS,
};

function createFakeCache(stores: Partial<EntityStores> = FIXTURE_STORES): EntityCache {
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

describe("StoreItemResolver", () => {
  const resolver = createItemResolver(createFakeCache());

  it("resolves an exact normalized weapon name with confidence 1", async () => {
    const result = await resolver.resolve("weapons", "Fatebringer (Timelost)");

    expect(result).not.toBeNull();
    expect(result?.record.hash).toBe(410412271);
    expect(result?.confidence).toBe(1);
  });

  it("matches apostrophe and diacritic input variants via normalization", async () => {
    const exotic = await resolver.resolve("exotic-weapons", "Izanagi's Burden");
    expect(exotic?.record.hash).toBe(157469160);
    expect(exotic?.confidence).toBe(1);

    const noApostrophe = await resolver.resolve(
      "exotic-weapons",
      "izanagis burden",
    );
    expect(noApostrophe?.record.hash).toBe(157469160);
    expect(noApostrophe?.confidence).toBe(1);

    const diacritic = await resolver.resolve("exotic-weapons", "Le Monárque");
    expect(diacritic?.record.hash).toBe(3084923842);
    expect(diacritic?.confidence).toBe(1);
  });

  it("fuzzy-resolves typos with confidence below 1", async () => {
    const result = await resolver.resolve("weapons", "fatebrniger");

    expect(result).not.toBeNull();
    expect(result?.record.name).toBe("Fatebringer (Timelost)");
    expect(result?.confidence).toBeLessThan(1);
    expect(result?.confidence).toBeGreaterThan(0);
  });

  it("returns null when nothing clears the fuzzy threshold", async () => {
    const result = await resolver.resolve("weapons", "zzzznotaweaponzzzz");

    expect(result).toBeNull();
  });

  it("returns null for blank input", async () => {
    expect(await resolver.resolve("weapons", "")).toBeNull();
    expect(await resolver.resolve("weapons", "   ")).toBeNull();
  });

  it("ranks exact search hits first", async () => {
    const results = await resolver.search("weapons", "Palindrome", 5);

    expect(results[0]?.record.name).toBe("Palindrome");
    expect(results[0]?.confidence).toBe(1);
  });

  it("respects the search result limit", async () => {
    const results = await resolver.search("weapons", "e", 2);

    expect(results).toHaveLength(2);
  });

  it("returns an empty array for blank search queries", async () => {
    expect(await resolver.search("weapons", "")).toEqual([]);
    expect(await resolver.search("weapons", "  ")).toEqual([]);
  });

  it("searches exotic armor by display name", async () => {
    const result = await resolver.resolve(
      "exotic-armor",
      "Heart of Inmost Light",
    );

    expect(result?.record.hash).toBe(3341713435);
    expect(result?.confidence).toBe(1);
  });

  it("searches exotic weapons by intrinsic description", async () => {
    const results = await resolver.search("exotic-weapons", "poison", 5);
    expect(results[0]?.record.name).toBe("Le Monarque");
  });

  it("searches exotic weapons by blight pools description", async () => {
    const results = await resolver.search("exotic-weapons", "blight", 5);
    expect(results.some((r) => r.record.name === "Witherhoard")).toBe(true);
  });
});
