import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import { getInventoryStatus } from "@/lib/db/repositories/inventoryRepository";
import type { DbUser } from "@/lib/db/types";
import type { BungieProfileClient } from "@/lib/bungie/types";
import type { EntityCache, ManifestService } from "@/lib/manifest/types/services";
import {
  syncUserInventory,
  SyncInProgressError,
  type SyncInventoryResult,
} from "@/lib/bungie/syncInventory";

/** Reuse inventory sync when last full sync is within this window (DBR-EQP-007). */
export const EQUIP_SYNC_FRESH_MS = 60_000;

export type SyncIfStaleResult = {
  synced: boolean;
  lastFullSyncAt: string | null;
  result?: SyncInventoryResult;
};

export function isInventoryFresh(
  lastFullSyncAt: string | null | undefined,
  nowMs = Date.now(),
  freshMs = EQUIP_SYNC_FRESH_MS,
): boolean {
  if (!lastFullSyncAt) return false;
  const syncedAt = Date.parse(lastFullSyncAt);
  if (Number.isNaN(syncedAt)) return false;
  const age = nowMs - syncedAt;
  return age >= 0 && age < freshMs;
}

export async function syncIfStale(
  db: AppDatabase,
  user: DbUser,
  accessToken: string,
  profileClient: BungieProfileClient,
  entityCache: EntityCache,
  manifest: ManifestService,
  manifestVersion: string,
  nowMs = Date.now(),
): Promise<SyncIfStaleResult> {
  const status = getInventoryStatus(db, user.id);
  if (isInventoryFresh(status?.lastFullSyncAt, nowMs)) {
    return { synced: false, lastFullSyncAt: status?.lastFullSyncAt ?? null };
  }

  try {
    const result = await syncUserInventory(
      db,
      user,
      accessToken,
      profileClient,
      entityCache,
      manifest,
      manifestVersion,
    );
    return { synced: true, lastFullSyncAt: result.lastFullSyncAt, result };
  } catch (error) {
    if (error instanceof SyncInProgressError) {
      throw new ApiError(
        API_ERROR_CODES.SYNC_BUSY,
        "Inventory sync already in progress; retry shortly",
        undefined,
        409,
      );
    }
    throw error;
  }
}
