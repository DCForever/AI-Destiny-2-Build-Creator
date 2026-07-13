import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { createSynergyRecord } from "@/lib/db/repositories/synergyRepository";
import {
  consolidateDuplicateDesignations,
  createInputFromSynergy,
  createUserSynergy,
  duplicateUserSynergy,
  enrichSynergiesWithUsage,
  getUserSynergy,
  listUserSynergies,
  listUserSynergiesConsolidated,
  mergeUserSynergies,
  reverseLookupSynergies,
  updateUserSynergy,
} from "@/lib/synergies/synergyService";

const ARCHETYPE_ITEM_TABLE = {
  "100": {
    hash: 100,
    redacted: false,
    displayProperties: { name: "Test Pulse", description: "", icon: null },
    itemType: 3,
    itemTypeDisplayName: "Pulse Rifle",
    defaultDamageTypeHash: 1,
    inventory: { tierType: 5 },
    equippingBlock: { ammoType: 1, equipmentSlotTypeHash: 1 },
    sockets: { socketEntries: [{ singleInitialItemHash: 200 }] },
  },
  "200": {
    hash: 200,
    redacted: false,
    displayProperties: { name: "Micro-Missile Frame", description: "", icon: null },
    itemTypeDisplayName: "Intrinsic",
    plug: { plugCategoryIdentifier: "intrinsics" },
  },
};

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    manifest: {
      getStatus: vi.fn(async () => ({ cachedVersion: "test-v" })),
      loadRawTable: vi.fn(async () => ARCHETYPE_ITEM_TABLE),
    },
    entityCache: {
      getStore: vi.fn(async (store: string) => {
        if (store === "origin-traits") {
          return [{ hash: 9001, name: "Cast No Shadows", searchName: "cast no shadows", description: "", icon: null }];
        }
        if (store === "set-bonuses") {
          return [
            {
              hash: 8001,
              name: "Eutechnology",
              searchName: "eutechnology",
              icon: null,
              perks: [
                { requiredCount: 2, name: "Gift of the Ley Lines", description: "" },
                { requiredCount: 4, name: "Techeun's Foresight", description: "" },
              ],
              itemHashes: [],
            },
          ];
        }
        if (store === "weapons") {
          return [
            {
              hash: 4206550094,
              name: "The Ringing Nail",
              searchName: "the ringing nail",
              description: "",
              icon: null,
              slot: "Kinetic",
              element: "Kinetic",
              ammo: "Primary",
              frame: "Adaptive Frame",
              itemTypeName: "Auto Rifle",
              originTraitHashes: [],
              perkColumns: [],
            },
            {
              hash: 100,
              name: "Outbreak Perfected",
              searchName: "outbreak perfected",
              description: "",
              icon: null,
              slot: "Kinetic",
              element: "Kinetic",
              ammo: "Primary",
              frame: "Micro-Missile Frame",
              itemTypeName: "Pulse Rifle",
              originTraitHashes: [],
              perkColumns: [],
            },
          ];
        }
        if (store === "exotic-weapons") {
          return [];
        }
        return [];
      }),
    },
  })),
}));

describe("synergyService", () => {
  it("creates synergy with origin trait link and auto-generated name", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn1", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      name: "Ignored Client Name",
      type: "melee",
      subType: "Base",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    expect(synergy.name).toBe("Melee: Base");
    expect(synergy.links).toHaveLength(1);
    expect(synergy.links[0]?.originTraitHash).toBe(9001);
  });

  it("creates DPS synergy without subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-dps", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      type: "dps",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    expect(synergy.name).toBe("DPS");
    expect(synergy.subType).toBeNull();
  });

  it("creates solo synergy with auto-generated name", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-solo", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      type: "solo",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    expect(synergy.name).toBe("Solo");
    expect(synergy.type).toBe("solo");
    expect(synergy.subType).toBeNull();
  });

  it("creates synergy with armor set bonus links", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn2", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Scorch",
      links: [
        {
          kind: "armor_set_bonus",
          displayName: "Eutechnology 2pc",
          armorSetName: "Eutechnology",
          bonusPieces: 2,
          bonusName: "Gift of the Ley Lines",
        },
      ],
    });

    expect(synergy.name).toBe("Verb: Scorch");
    expect(synergy.links[0]?.armorSetHash).toBe(8001);
  });

  it("allows multiple synergies on same target (reverse lookup)", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn3", 3, "Player");

    await createUserSynergy(db, user.id, {
      type: "melee",
      subType: "Base",
      links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
    });
    await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Scorch",
      links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
    });

    const matches = reverseLookupSynergies(db, user.id, {
      kind: "origin_trait",
      name: "Cast No Shadows",
    });
    expect(matches).toHaveLength(2);
  });

  it("returns both DPS and Verb synergies for same weapon itemHash", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-weapon-dual", 3, "Player");
    const itemHash = 4206550094;

    await createUserSynergy(db, user.id, {
      type: "dps",
      links: [{ kind: "weapon", displayName: "The Ringing Nail", itemHash }],
    });
    await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Scorch",
      links: [{ kind: "weapon", displayName: "The Ringing Nail", itemHash }],
    });

    const matches = reverseLookupSynergies(db, user.id, {
      kind: "weapon",
      itemHash,
    });
    expect(matches).toHaveLength(2);
    expect(matches.map((m) => m.type).sort()).toEqual(["dps", "verb"]);
  });

  it("rejects invalid armor set bonus", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn4", 3, "Player");

    await expect(
      createUserSynergy(db, user.id, {
        type: "dps",
        links: [
          {
            kind: "armor_set_bonus",
            displayName: "Bad",
            armorSetName: "Eutechnology",
            bonusPieces: 2,
            bonusName: "Nonexistent Bonus",
          },
        ],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_SYNERGY_LINK });
  });

  it("rejects melee without subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-sub", 3, "Player");

    await expect(
      createUserSynergy(db, user.id, {
        type: "melee",
        links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE });
  });

  it("creates weapon archetype synergy with manifest-backed subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-arch", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      type: "weapon_archetype",
      subType: "Micro-Missile Frame",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    expect(synergy.name).toBe("Weapon Archetype: Micro-Missile Frame");
    expect(synergy.subType).toBe("Micro-Missile Frame");
  });

  it("creates weapon archetype synergy with weapon type subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-arch-type", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      type: "weapon_archetype",
      subType: "Pulse Rifle",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    expect(synergy.name).toBe("Weapon Archetype: Pulse Rifle");
    expect(synergy.subType).toBe("Pulse Rifle");
  });

  it("rejects unknown weapon archetype subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-arch-bad", 3, "Player");

    await expect(
      createUserSynergy(db, user.id, {
        type: "weapon_archetype",
        subType: "Glaive Frame",
        links: [
          {
            kind: "origin_trait",
            displayName: "Cast No Shadows",
            originTraitName: "Cast No Shadows",
          },
        ],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE });
  });

  it("rejects non-keyword-like verb subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-verb-bad", 3, "Player");

    await expect(
      createUserSynergy(db, user.id, {
        type: "verb",
        subType: "not a verb!!!",
        links: [
          {
            kind: "origin_trait",
            displayName: "Cast No Shadows",
            originTraitName: "Cast No Shadows",
          },
        ],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE });
  });

  it("creates verb synergy with glossary subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-verb-sever", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Void Breach",
      links: [
        {
          kind: "weapon",
          displayName: "The Ringing Nail",
          itemHash: 4206550094,
        },
      ],
    });

    expect(synergy.name).toBe("Verb: Void Breach");
    expect(synergy.subType).toBe("Void Breach");
  });

  it("regenerates name on update", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn5", 3, "Player");
    const created = await createUserSynergy(db, user.id, {
      type: "melee",
      subType: "Base",
      links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
    });

    const updated = await updateUserSynergy(db, user.id, created.id, {
      name: "Should Be Ignored",
      links: [
        {
          kind: "armor_set_bonus",
          displayName: "Eutechnology 2pc",
          armorSetName: "Eutechnology",
          bonusPieces: 2,
          bonusName: "Gift of the Ley Lines",
        },
      ],
    });

    expect(updated?.name).toBe("Melee: Base");
    expect(updated?.links).toHaveLength(1);
    expect(updated?.links[0]?.kind).toBe("armor_set_bonus");
  });

  it("duplicate of same designation consolidates back to one library row", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-dup", 3, "Player");

    const source = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Scorch",
      description: "Original note",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    const payload = createInputFromSynergy(source);
    expect(payload.type).toBe("verb");
    expect(payload.subType).toBe("Scorch");
    expect(payload.description).toBe("Original note");
    expect(payload.links).toHaveLength(1);

    // One-row-per-designation: clone folds into oldest survivor.
    const clone = await duplicateUserSynergy(db, user.id, source.id);
    expect(clone).not.toBeNull();
    expect(clone!.id).toBe(source.id);
    expect(clone!.type).toBe(source.type);
    expect(clone!.subType).toBe(source.subType);
    expect(clone!.links).toHaveLength(1);
    expect(listUserSynergies(db, user.id)).toHaveLength(1);
  });

  it("returns null when duplicating a missing synergy", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-dup-miss", 3, "Player");
    expect(await duplicateUserSynergy(db, user.id, "no-such-id")).toBeNull();
  });

  it("merges same-designation synergies: unions links and deletes sources", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-merge", 3, "Player");

    // Bypass create consolidation so two same-designation rows exist for manual merge.
    const now = new Date().toISOString();
    const survivor = createSynergyRecord(db, user.id, {
      id: crypto.randomUUID(),
      name: "Verb: Scorch",
      type: "verb",
      subType: "Scorch",
      description: "Survivor note",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
      now,
    });
    const source = createSynergyRecord(db, user.id, {
      id: crypto.randomUUID(),
      name: "Verb: Scorch",
      type: "verb",
      subType: "Scorch",
      description: "Source note",
      links: [
        {
          kind: "weapon",
          displayName: "The Ringing Nail",
          itemHash: 4206550094,
        },
      ],
      now: new Date(Date.now() + 1000).toISOString(),
    });

    const result = await mergeUserSynergies(db, user.id, {
      survivorId: survivor.id,
      sourceIds: [source.id],
    });

    expect(result.deletedIds).toEqual([source.id]);
    expect(result.synergy.id).toBe(survivor.id);
    expect(result.synergy.links).toHaveLength(2);
    expect(result.linksAdded).toBe(1);
    expect(result.synergy.description).toContain("Survivor note");
    expect(result.synergy.description).toContain("Source note");
    expect(getUserSynergy(db, user.id, source.id)).toBeNull();
    expect(listUserSynergies(db, user.id)).toHaveLength(1);
  });

  it("auto-consolidates same designation on create and list", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-auto-merge", 3, "Player");

    const first = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Devour",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });
    const second = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Devour",
      links: [
        {
          kind: "weapon",
          displayName: "The Ringing Nail",
          itemHash: 4206550094,
        },
      ],
    });

    // Second create folds same designation into one row with unioned links.
    expect(listUserSynergies(db, user.id)).toHaveLength(1);
    expect(second.links).toHaveLength(2);
    expect(second.id).toBe(listUserSynergies(db, user.id)[0]!.id);
    // First id may have been deleted if timestamps tied; survivor is the list row.
    expect(
      getUserSynergy(db, user.id, first.id) ?? getUserSynergy(db, user.id, second.id),
    ).not.toBeNull();

    const listed = await listUserSynergiesConsolidated(db, user.id);
    expect(listed).toHaveLength(1);
    expect(listed[0]!.name).toBe("Verb: Devour");
    expect(listed[0]!.objectCount).toBe(2);
    expect(listed[0]!.buildCount).toBe(0);
  });

  it("consolidateDuplicateDesignations merges raw duplicates", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-consol", 3, "Player");
    const t0 = "2026-01-01T00:00:00.000Z";
    const t1 = "2026-02-01T00:00:00.000Z";
    createSynergyRecord(db, user.id, {
      id: "old-id",
      name: "Verb: Devour — A",
      type: "verb",
      subType: "Devour",
      description: "A",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
      now: t0,
    });
    createSynergyRecord(db, user.id, {
      id: "new-id",
      name: "Verb: Devour — B",
      type: "verb",
      subType: "Devour",
      description: "B",
      links: [
        {
          kind: "weapon",
          displayName: "The Ringing Nail",
          itemHash: 4206550094,
        },
      ],
      now: t1,
    });

    const result = await consolidateDuplicateDesignations(db, user.id);
    expect(result.deletedIds).toContain("new-id");
    expect(result.survivorIds).toContain("old-id");
    const rows = listUserSynergies(db, user.id);
    expect(rows).toHaveLength(1);
    expect(rows[0]!.id).toBe("old-id");
    expect(rows[0]!.links).toHaveLength(2);
    expect(rows[0]!.name).toBe("Verb: Devour");
  });

  it("enrichSynergiesWithUsage reports objectCount", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-usage", 3, "Player");
    const s = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Scorch",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });
    const enriched = enrichSynergiesWithUsage(db, user.id, [s]);
    expect(enriched[0]!.objectCount).toBe(1);
    expect(enriched[0]!.buildCount).toBe(0);
  });

  it("rejects merge across different type/subType", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn-merge-bad", 3, "Player");

    const a = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Scorch",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });
    const b = await createUserSynergy(db, user.id, {
      type: "verb",
      subType: "Jolt",
      links: [
        {
          kind: "weapon",
          displayName: "The Ringing Nail",
          itemHash: 4206550094,
        },
      ],
    });

    await expect(
      mergeUserSynergies(db, user.id, {
        survivorId: a.id,
        sourceIds: [b.id],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_SYNERGY_TYPE });
  });
});
