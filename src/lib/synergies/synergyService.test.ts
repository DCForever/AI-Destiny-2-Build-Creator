import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import {
  createUserSynergy,
  reverseLookupSynergies,
  updateUserSynergy,
} from "@/lib/synergies/synergyService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
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
            },
          ];
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

    expect(synergy.name).toBe("Melee: Base — Cast No Shadows");
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

    expect(synergy.name).toBe("DPS — Cast No Shadows");
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

    expect(synergy.name).toBe("Solo — Cast No Shadows");
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

    expect(synergy.name).toBe("Verb: Scorch — Eutechnology 2pc");
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

    expect(updated?.name).toBe("Melee: Base — Eutechnology 2pc");
    expect(updated?.links).toHaveLength(1);
    expect(updated?.links[0]?.kind).toBe("armor_set_bonus");
  });
});
