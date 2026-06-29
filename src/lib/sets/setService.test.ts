import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { buildVariants, builds, variantSetAttachments } from "@/lib/db/schema";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import {
  addSetItem,
  createUserSet,
  deleteUserSet,
  listUserSets,
  removeSetItem,
} from "@/lib/sets/setService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async () => []),
    },
  })),
}));

describe("setService", () => {
  it("creates set with tags and rejects duplicate name per type", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc1", 3, "Player");

    const created = await createUserSet(db, user.id, {
      name: "Solar PVE",
      type: "weapon",
      tagIds: ["solar", "pve"],
    });
    expect(created?.name).toBe("Solar PVE");
    expect(created?.tagIds).toEqual(["pve", "solar"]);

    await expect(
      createUserSet(db, user.id, { name: "Solar PVE", type: "weapon", tagIds: [] }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.DUPLICATE_SET_NAME });
  });

  it("rejects invalid concept tags", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc2", 3, "Player");

    await expect(
      createUserSet(db, user.id, {
        name: "Bad Tags",
        type: "weapon",
        tagIds: ["not-a-tag" as "solar"],
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.INVALID_TAG });
  });

  it("requires confirmReplace when slot occupied", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc3", 3, "Player");
    const set = await createUserSet(db, user.id, {
      name: "Weapons",
      type: "weapon",
      tagIds: [],
    });

    await addSetItem(db, user.id, set!.id, {
      slot: "primary",
      itemHash: 100,
      itemName: "Test Gun A",
    });

    await expect(
      addSetItem(db, user.id, set!.id, {
        slot: "primary",
        itemHash: 200,
        itemName: "Test Gun B",
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.SLOT_OCCUPIED });

    const updated = await addSetItem(db, user.id, set!.id, {
      slot: "primary",
      itemHash: 200,
      itemName: "Test Gun B",
      confirmReplace: true,
    });

    const active = updated!.items.filter((i) => !i.removedAt);
    expect(active).toHaveLength(1);
    expect(active[0]?.itemHash).toBe(200);
    expect(updated!.items.filter((i) => i.removedAt)).toHaveLength(1);
  });

  it("blocks delete when set is attached", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc4", 3, "Player");
    const now = new Date().toISOString();
    createSetRecord(db, user.id, {
      id: "set-del",
      name: "In Use",
      type: "weapon",
      tagIds: [],
      now,
    });

    db.insert(builds)
      .values({
        id: "b1",
        userId: user.id,
        name: "Build",
        className: "Titan",
        subclass: "Sunbreaker",
        exoticArmorHash: 1,
        exoticArmorName: "Exotic",
        createdAt: now,
        updatedAt: now,
      })
      .run();
    db.insert(buildVariants)
      .values({
        id: "v1",
        buildId: "b1",
        name: "Default",
        isDefault: 1,
        createdAt: now,
        updatedAt: now,
      })
      .run();
    db.insert(variantSetAttachments)
      .values({
        id: "a1",
        variantId: "v1",
        setId: "set-del",
        mode: "live",
        attachedAt: now,
      })
      .run();

    try {
      deleteUserSet(db, user.id, "set-del");
      expect.fail("expected SET_IN_USE");
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      const apiErr = err as ApiError;
      expect(apiErr.code).toBe(API_ERROR_CODES.SET_IN_USE);
      expect(apiErr.details?.buildIds).toEqual(["b1"]);
      expect(apiErr.details?.variantIds).toEqual(["v1"]);
    }
  });

  it("shows modEncourage for armor with empty mod slots", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc5", 3, "Player");
    const set = await createUserSet(db, user.id, {
      name: "Armor",
      type: "armor",
      tagIds: [],
    });

    const detail = await addSetItem(db, user.id, set!.id, {
      slot: "helmet",
      itemHash: 300,
      itemName: "Helmet",
      modHashes: [],
    });
    expect(detail?.modEncourage).toBe(true);
  });

  it("lists sets by tag AND filter", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc6", 3, "Player");
    await createUserSet(db, user.id, { name: "A", type: "weapon", tagIds: ["solar", "melee"] });
    await createUserSet(db, user.id, { name: "B", type: "weapon", tagIds: ["solar"] });

    const filtered = listUserSets(db, user.id, { tags: ["solar", "melee"] });
    expect(filtered).toHaveLength(1);
    expect(filtered[0]?.name).toBe("A");
  });

  it("soft-removes items while keeping history", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "svc7", 3, "Player");
    const set = await createUserSet(db, user.id, { name: "W", type: "weapon", tagIds: [] });
    const withItem = await addSetItem(db, user.id, set!.id, {
      slot: "special",
      itemHash: 400,
      itemName: "Special",
    });
    const itemId = withItem!.items.find((i) => !i.removedAt)!.id;

    const afterRemove = await removeSetItem(db, user.id, set!.id, itemId);
    expect(afterRemove!.items.find((i) => i.id === itemId)?.removedAt).toBeTruthy();
  });
});
