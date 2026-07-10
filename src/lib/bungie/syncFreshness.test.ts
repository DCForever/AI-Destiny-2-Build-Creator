import { describe, expect, it, vi } from "vitest";

import { API_ERROR_CODES } from "@/lib/api/errors";
import { syncIfStale, isInventoryFresh } from "@/lib/bungie/syncFreshness";
import { SyncInProgressError } from "@/lib/bungie/syncInventory";
import { createTestDb } from "@/lib/db/client";
import { inventorySyncMeta } from "@/lib/db/schema";
import { ensureUser } from "@/lib/db/repositories/userRepository";

vi.mock("@/lib/bungie/syncInventory", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/bungie/syncInventory")>();
  return {
    ...actual,
    syncUserInventory: vi.fn(),
  };
});

import { syncUserInventory } from "@/lib/bungie/syncInventory";

describe("syncIfStale", () => {
  it("skips sync when lastFullSyncAt is fresh", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "bm1", 3, "G");
    const now = Date.parse("2026-07-10T12:00:30.000Z");
    db.insert(inventorySyncMeta)
      .values({
        userId: user.id,
        itemCount: 1,
        syncVersion: 1,
        lastFullSyncAt: "2026-07-10T12:00:00.000Z",
      })
      .run();

    const result = await syncIfStale(
      db,
      user,
      "tok",
      {} as never,
      {} as never,
      {} as never,
      "v1",
      now,
    );
    expect(result.synced).toBe(false);
    expect(syncUserInventory).not.toHaveBeenCalled();
  });

  it("maps SyncInProgressError to SYNC_BUSY", async () => {
    vi.mocked(syncUserInventory).mockRejectedValueOnce(new SyncInProgressError());
    const db = createTestDb();
    const user = ensureUser(db, "bm2", 3, "G");

    await expect(
      syncIfStale(db, user, "tok", {} as never, {} as never, {} as never, "v1"),
    ).rejects.toMatchObject({ code: API_ERROR_CODES.SYNC_BUSY });
  });

  it("isInventoryFresh edge cases", () => {
    expect(isInventoryFresh("not-a-date")).toBe(false);
  });
});
