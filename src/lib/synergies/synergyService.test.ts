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
        return [];
      }),
    },
  })),
}));

describe("synergyService", () => {
  it("creates synergy with origin trait link", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn1", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      name: "Melee — Cast No Shadows",
      type: "melee",
      links: [
        {
          kind: "origin_trait",
          displayName: "Cast No Shadows",
          originTraitName: "Cast No Shadows",
        },
      ],
    });

    expect(synergy.links).toHaveLength(1);
    expect(synergy.links[0]?.originTraitHash).toBe(9001);
  });

  it("creates synergy with armor set bonus links", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn2", 3, "Player");

    const synergy = await createUserSynergy(db, user.id, {
      name: "Void — Eutechnology",
      type: "verb",
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

    expect(synergy.links[0]?.armorSetHash).toBe(8001);
  });

  it("allows multiple synergies on same target (reverse lookup)", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn3", 3, "Player");

    await createUserSynergy(db, user.id, {
      name: "Melee",
      type: "melee",
      links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
    });
    await createUserSynergy(db, user.id, {
      name: "Verb",
      type: "verb",
      links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
    });

    const matches = reverseLookupSynergies(db, user.id, {
      kind: "origin_trait",
      name: "Cast No Shadows",
    });
    expect(matches).toHaveLength(2);
  });

  it("rejects invalid armor set bonus", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn4", 3, "Player");

    await expect(
      createUserSynergy(db, user.id, {
        name: "Bad",
        type: "damage",
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

  it("replaces links on update", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "syn5", 3, "Player");
    const created = await createUserSynergy(db, user.id, {
      name: "Melee",
      type: "melee",
      links: [{ kind: "origin_trait", displayName: "Cast No Shadows", originTraitName: "Cast No Shadows" }],
    });

    const updated = await updateUserSynergy(db, user.id, created.id, {
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

    expect(updated?.links).toHaveLength(1);
    expect(updated?.links[0]?.kind).toBe("armor_set_bonus");
  });
});
