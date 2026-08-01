import { describe, expect, it, vi } from "vitest";

import { prepareAttachments } from "@/lib/builds/attachmentService";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { createBuildRecord } from "@/lib/db/repositories/buildRepository";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { createVariantRecord } from "@/lib/db/repositories/variantRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore: vi.fn(async () => []) },
  })),
}));

function seedBuild(db: ReturnType<typeof createTestDb>, userId: number, buildId: string, variantId: string) {
  const now = new Date().toISOString();
  createBuildRecord(db, userId, {
    id: buildId,
    name: "B",
    className: "Titan",
    subclass: { name: "Sunbreaker" },
    exoticArmorHash: null,
    exoticArmorName: null,
    exoticWeaponHash: null,
    exoticWeaponName: null,
    pinnedSuper: null,
    tagIds: [],
    synergyTypes: [{ type: "melee", subType: "Base" }],
    now,
  });
  createVariantRecord(db, {
    id: variantId,
    buildId,
    name: "Default",
    isDefault: true,
    now,
  });
  return now;
}

describe("prepareAttachments occupancy (DBR-CMP-008–009)", () => {
  it("allows attaching an empty weapon set scaffold", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "occ1", 3, "Player");
    const now = seedBuild(db, user.id, "b1", "v1");
    createSetRecord(db, user.id, {
      id: "w-empty",
      name: "Empty Weapons",
      type: "weapon",
      tagIds: [],
      now,
    });

    await expect(
      prepareAttachments(
        db,
        user.id,
        "v1",
        [{ setId: "w-empty", mode: "live" }],
        now,
      ),
    ).resolves.toHaveLength(1);
  });

  it("rejects attaching a one-item weapon set", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "occ2", 3, "Player");
    const now = seedBuild(db, user.id, "b1", "v1");
    createSetRecord(db, user.id, {
      id: "w-one",
      name: "One Gun",
      type: "weapon",
      tagIds: [],
      now,
    });
    await upsertSetItem(db, "w-one", "weapon", {
      slot: "primary",
      itemHash: 1001,
      itemName: "Scout",
    });

    await expect(
      prepareAttachments(
        db,
        user.id,
        "v1",
        [{ setId: "w-one", mode: "live" }],
        now,
      ),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.SET_MIN_ITEMS });
  });

  it("rejects attaching a one-piece mod set", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "occ3", 3, "Player");
    const now = seedBuild(db, user.id, "b1", "v1");
    createSetRecord(db, user.id, {
      id: "m-one",
      name: "Helmet Only",
      type: "mod",
      tagIds: [],
      now,
    });
    await upsertSetItem(db, "m-one", "mod", {
      slot: "helmet",
      itemHash: 2001,
      itemName: "Mod A",
    });

    try {
      await prepareAttachments(
        db,
        user.id,
        "v1",
        [{ setId: "m-one", mode: "live" }],
        now,
      );
      expect.unreachable();
    } catch (e) {
      expect(e).toBeInstanceOf(ApiError);
      expect((e as ApiError).code).toBe(API_ERROR_CODES.MOD_SET_MIN_SLOTS);
    }
  });

  it("allows attaching a two-item weapon set", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "occ4", 3, "Player");
    const now = seedBuild(db, user.id, "b1", "v1");
    createSetRecord(db, user.id, {
      id: "w-two",
      name: "Two Guns",
      type: "weapon",
      tagIds: [],
      now,
    });
    await upsertSetItem(db, "w-two", "weapon", {
      slot: "primary",
      itemHash: 1001,
      itemName: "Scout",
    });
    await upsertSetItem(db, "w-two", "weapon", {
      slot: "special",
      itemHash: 1002,
      itemName: "Shotgun",
    });

    await expect(
      prepareAttachments(
        db,
        user.id,
        "v1",
        [{ setId: "w-two", mode: "live" }],
        now,
      ),
    ).resolves.toHaveLength(1);
  });
});
