import { computeRollTags } from "@/lib/inventory/rollTags";
import type { AppDatabase } from "@/lib/db/client";
import { upsertInventoryBatch, getInventoryStatus } from "@/lib/db/repositories/inventoryRepository";
import { updateUserMembership } from "@/lib/db/repositories/userRepository";
import type { DbUser, UserInventoryItem } from "@/lib/db/types";
import type { BungieProfileClient, DestinyMembership, RawInventoryItem } from "@/lib/bungie/types";
import type { EntityCache } from "@/lib/manifest/types/services";
import type { WeaponRecord } from "@/lib/manifest/types/records";

const syncLocks = new Map<number, Promise<SyncInventoryResult>>();

export interface SyncInventoryResult {
  itemCount: number;
  syncVersion: number;
  lastFullSyncAt: string;
}

export class SyncInProgressError extends Error {
  constructor() {
    super("Inventory sync already in progress for this user");
    this.name = "SyncInProgressError";
  }
}

function bucketLabel(bucketHash: number): string {
  const labels: Record<number, string> = {
    1498876634: "Kinetic",
    2465295065: "Energy",
    953998645: "Power",
    3448274439: "Helmet",
    3551918588: "Gauntlets",
    14239492: "Chest",
    20886954: "Legs",
    1585787867: "ClassItem",
    3284755031: "Subclass",
  };
  return labels[bucketHash] ?? "Unknown";
}

async function buildWeaponLookup(cache: EntityCache): Promise<Map<number, WeaponRecord>> {
  const weapons = await cache.getStore("weapons");
  const lookup = new Map<number, WeaponRecord>();
  for (const weapon of weapons) {
    lookup.set(weapon.hash, weapon);
  }
  return lookup;
}

async function buildPerkNameMap(cache: EntityCache): Promise<Map<number, string>> {
  const perks = await cache.getStore("weapon-perks");
  return new Map(perks.map((p) => [p.hash, p.name]));
}

function normalizeItems(
  rawItems: RawInventoryItem[],
  perkNameMap: Map<number, string>,
  weaponLookup: Map<number, WeaponRecord>,
  syncedAt: string,
): UserInventoryItem[] {
  return rawItems.map((raw) => {
    const weaponRecord = weaponLookup.get(raw.itemHash) ?? null;
    const rollTags = computeRollTags(raw.plugHashes, perkNameMap, weaponRecord, {
      isCrafted: raw.isCrafted,
    });
    return {
      instanceId: raw.instanceId,
      itemHash: raw.itemHash,
      bucket: bucketLabel(raw.bucketHash),
      location: raw.location,
      characterId: raw.characterId,
      power: raw.power,
      isMasterwork: raw.isMasterwork,
      isCrafted: raw.isCrafted,
      plugHashes: raw.plugHashes,
      rollTags,
      syncedAt,
    };
  });
}

async function resolveDestinyMembership(
  profileClient: BungieProfileClient,
  accessToken: string,
): Promise<DestinyMembership> {
  const memberships = await profileClient.getMemberships(accessToken);
  const membership = memberships[0];
  if (!membership) {
    throw new Error("No Destiny memberships found");
  }
  return membership;
}

async function performSync(
  db: AppDatabase,
  user: DbUser,
  accessToken: string,
  profileClient: BungieProfileClient,
  entityCache: EntityCache,
): Promise<SyncInventoryResult> {
  const membership = await resolveDestinyMembership(profileClient, accessToken);

  if (
    user.membershipType !== membership.membershipType ||
    user.displayName !== membership.displayName
  ) {
    updateUserMembership(db, user.id, membership.membershipType, membership.displayName);
  }

  const rawItems = await profileClient.getFullInventory(accessToken, membership);
  const [perkNameMap, weaponLookup] = await Promise.all([
    buildPerkNameMap(entityCache),
    buildWeaponLookup(entityCache),
  ]);

  const syncedAt = new Date().toISOString();
  const items = normalizeItems(rawItems, perkNameMap, weaponLookup, syncedAt);
  upsertInventoryBatch(db, user.id, items);

  const status = getInventoryStatus(db, user.id);
  return {
    itemCount: status?.itemCount ?? items.length,
    syncVersion: status?.syncVersion ?? 1,
    lastFullSyncAt: status?.lastFullSyncAt ?? syncedAt,
  };
}

export async function syncUserInventory(
  db: AppDatabase,
  user: DbUser,
  accessToken: string,
  profileClient: BungieProfileClient,
  entityCache: EntityCache,
): Promise<SyncInventoryResult> {
  const existing = syncLocks.get(user.id);
  if (existing) {
    throw new SyncInProgressError();
  }

  const syncPromise = performSync(db, user, accessToken, profileClient, entityCache).finally(() => {
    syncLocks.delete(user.id);
  });

  syncLocks.set(user.id, syncPromise);
  return syncPromise;
}

/** Test helper: clear in-memory sync mutex state. */
export function clearSyncLocksForTests(): void {
  syncLocks.clear();
}
