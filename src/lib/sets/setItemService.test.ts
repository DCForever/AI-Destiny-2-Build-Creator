import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { createTestDb } from "@/lib/db/client";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { ensureUser } from "@/lib/db/repositories/userRepository";

import { upsertSetItem } from "./setItemService";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore: vi.fn(async () => []) },
  })),
}));

function seedSet(id: string) {
  const db = createTestDb();
  const user = ensureUser(db, id, 3, "Player");
  createSetRecord(db, user.id, {
    id,
    name: `Set ${id}`,
    type: "weapon",
    tagIds: [],
    now: new Date().toISOString(),
  });
  return db;
}

describe("upsertSetItem instanceId", () => {
  it("persists the selected copy's instanceId", async () => {
    const db = seedSet("s1");
    const record = await upsertSetItem(db, "s1", "weapon", {
      slot: "primary",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-A",
      selectedPerks: [1, 2, 3],
    });
    expect(record.instanceId).toBe("inst-A");
    expect(record.selectedPerks).toEqual([1, 2, 3]);
  });

  it("distinguishes two copies with the same itemHash by instanceId", async () => {
    const db = seedSet("s2");
    const a = await upsertSetItem(db, "s2", "weapon", {
      slot: "primary",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-A",
    });
    const b = await upsertSetItem(db, "s2", "weapon", {
      slot: "special",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-B",
    });
    expect(a.instanceId).toBe("inst-A");
    expect(b.instanceId).toBe("inst-B");
    expect(a.id).not.toBe(b.id);
  });

  it("defaults selectedPerks to an empty array when omitted", async () => {
    const db = seedSet("s3");
    const record = await upsertSetItem(db, "s3", "weapon", {
      slot: "primary",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-A",
    });
    expect(record.selectedPerks).toEqual([]);
  });

  it("persists column-ordered selectedPerks from a perk grid selection", async () => {
    const db = seedSet("s-grid");
    const record = await upsertSetItem(db, "s-grid", "weapon", {
      slot: "primary",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-grid",
      selectedPerks: [10, 20, 30, 40],
    });
    expect(record.instanceId).toBe("inst-grid");
    expect(record.selectedPerks).toEqual([10, 20, 30, 40]);
  });

  it("still enforces occupied-slot replace confirmation and swaps the instanceId", async () => {
    const db = seedSet("s4");
    await upsertSetItem(db, "s4", "weapon", {
      slot: "primary",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-A",
    });

    await expect(
      upsertSetItem(db, "s4", "weapon", {
        slot: "primary",
        itemHash: 100,
        itemName: "Gunburn",
        instanceId: "inst-B",
      }),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.SLOT_OCCUPIED });

    const replaced = await upsertSetItem(db, "s4", "weapon", {
      slot: "primary",
      itemHash: 100,
      itemName: "Gunburn",
      instanceId: "inst-B",
      confirmReplace: true,
    });
    expect(replaced.instanceId).toBe("inst-B");
  });
});
