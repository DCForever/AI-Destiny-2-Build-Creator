import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import {
  createUserBuild,
  updateUserVariant,
} from "@/lib/builds/buildService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async () => []),
    },
  })),
}));

describe("buildService", () => {
  it("creates build with default variant and synergy", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b1", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);

    const build = await createUserBuild(db, user.id, {
      name: "Solar Titan",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      exoticArmorName: "Hallowfire Heart",
      synergyIds: [synergies[0]!.id],
      tagIds: ["solar", "pve"],
    });

    expect(build?.variants).toHaveLength(1);
    expect(build?.synergies).toHaveLength(1);
  });

  it("rejects save with no equipment slots", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b2", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createSetRecord(db, user.id, { id: "set-w", name: "Weapons", type: "weapon", tagIds: [], now });
    await upsertSetItem(db, "set-w", "weapon", {
      slot: "primary",
      itemHash: 500,
      itemName: "Gun",
    });

    const build = await createUserBuild(db, user.id, {
      name: "Empty",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      synergyIds: [synergies[0]!.id],
    });

    await expect(
      updateUserVariant(db, user.id, build!.id, build!.variants[0]!.id, {
        attachments: [{ setId: "set-w", mode: "live" }],
      }),
    ).resolves.toBeTruthy();

    const emptySet = crypto.randomUUID();
    createSetRecord(db, user.id, { id: emptySet, name: "Empty Set", type: "mod", tagIds: [], now });

    await expect(
      updateUserVariant(db, user.id, build!.id, build!.variants[0]!.id, {
        attachments: [{ setId: emptySet, mode: "live" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.VARIANT_EMPTY });
  });

  it("blocks pair armor mismatch", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "b3", 3, "Player");
    const synergies = seedDefaultSynergies(db, user.id);
    const now = new Date().toISOString();

    createSetRecord(db, user.id, { id: "pair-bad", name: "Pair", type: "pair", tagIds: [], now });
    await upsertSetItem(db, "pair-bad", "pair", {
      slot: "exotic_armor",
      itemHash: 999,
      itemName: "Wrong Armor",
    });

    const build = await createUserBuild(db, user.id, {
      name: "Pair Test",
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", classAbility: "", movement: "", melee: "", grenade: "", aspects: [], fragments: [], rationale: "" },
      exoticArmorHash: 100,
      synergyIds: [synergies[0]!.id],
    });

    await expect(
      updateUserVariant(db, user.id, build!.id, build!.variants[0]!.id, {
        attachments: [{ setId: "pair-bad", mode: "live" }],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.PAIR_ARMOR_MISMATCH });
  });
});
