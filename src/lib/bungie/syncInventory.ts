import { computeRollTags } from "@/lib/inventory/rollTags";
import { buildStoredSocketPlugs } from "@/lib/inventory/instances/buildStoredSocketPlugs";
import { loadWeaponSocketContext } from "@/lib/inventory/instances/weaponSocketContext";
import type { StoredSocketPlug } from "@/lib/inventory/instances/types";
import { isWeaponBucketHash } from "@/lib/bungie/inventoryBuckets";
import type { AppDatabase } from "@/lib/db/client";
import { upsertInventoryBatch, getInventoryStatus } from "@/lib/db/repositories/inventoryRepository";
import { updateUserMembership } from "@/lib/db/repositories/userRepository";
import type { DbUser, UserInventoryItem } from "@/lib/db/types";
import {
  inventoryBucketLabel,
  SUBCLASS_BUCKET_HASH,
} from "@/lib/bungie/inventoryBuckets";
import {
  buildEquipmentBucketLookup,
  needsEquipmentBucketResolution,
  resolveTransferContainerBuckets,
} from "@/lib/bungie/resolveEquipmentBuckets";
import type {
  BungieProfileClient,
  DestinyMembership,
  InventoryParseDiagnostics,
  RawInventoryItem,
} from "@/lib/bungie/types";
import type { EntityCache, ManifestService } from "@/lib/manifest/types/services";
import type { ExoticWeaponRecord, WeaponRecord } from "@/lib/manifest/types/records";

type WeaponCatalogRecord = WeaponRecord | ExoticWeaponRecord;

const syncLocks = new Map<number, Promise<SyncInventoryResult>>();

export interface SyncInventoryResult {
  itemCount: number;
  syncVersion: number;
  lastFullSyncAt: string;
  diagnostics: InventoryParseDiagnostics;
}

export class SyncInProgressError extends Error {
  constructor() {
    super("Inventory sync already in progress for this user");
    this.name = "SyncInProgressError";
  }
}


function bucketLabel(bucketHash: number): string {
  return inventoryBucketLabel(bucketHash);
}

async function buildWeaponLookup(cache: EntityCache): Promise<Map<number, WeaponCatalogRecord>> {
  const [weapons, exoticWeapons] = await Promise.all([
    cache.getStore("weapons"),
    cache.getStore("exotic-weapons"),
  ]);
  const lookup = new Map<number, WeaponCatalogRecord>();
  for (const weapon of [...weapons, ...exoticWeapons]) {
    lookup.set(weapon.hash, weapon);
  }
  return lookup;
}

async function buildExoticArmorHashSet(cache: EntityCache): Promise<Set<number>> {
  const armor = await cache.getStore("exotic-armor");
  return new Set(armor.map((piece) => piece.hash));
}

function enrichManifestDiagnostics(
  diagnostics: InventoryParseDiagnostics,
  rawItems: RawInventoryItem[],
  weaponLookup: Map<number, WeaponCatalogRecord>,
  exoticArmorHashes: Set<number>,
): void {
  const equipmentHashes = new Set<number>();
  for (const item of rawItems) {
    if (item.bucketHash === SUBCLASS_BUCKET_HASH) continue;
    equipmentHashes.add(item.itemHash);
  }

  let inWeaponsCatalog = 0;
  let inExoticArmorCatalog = 0;
  for (const hash of equipmentHashes) {
    if (weaponLookup.has(hash)) {
      inWeaponsCatalog += 1;
    }
    if (exoticArmorHashes.has(hash)) {
      inExoticArmorCatalog += 1;
    }
  }

  const matchedHashes = new Set<number>();
  for (const hash of equipmentHashes) {
    if (weaponLookup.has(hash) || exoticArmorHashes.has(hash)) {
      matchedHashes.add(hash);
    }
  }

  diagnostics.manifest = {
    equipmentItemHashes: equipmentHashes.size,
    inWeaponsCatalog,
    inExoticArmorCatalog,
    unmatchedEquipmentHashes: equipmentHashes.size - matchedHashes.size,
  };
}

function logInventorySyncDiagnostics(diagnostics: InventoryParseDiagnostics): void {
  const topUnknownBuckets = Object.entries(diagnostics.dropped.unknownBuckets)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 15);
  console.info(
    "[inventory-sync]",
    JSON.stringify(
      {
        membership: diagnostics.membership,
        rawTotal: diagnostics.raw.total,
        parsedTotal: diagnostics.parsed.total,
        equipmentTotal: diagnostics.parsed.equipmentTotal,
        subclassTotal: diagnostics.parsed.subclassTotal,
        droppedTotal: diagnostics.dropped.total,
        dropped: {
          invalidShape: diagnostics.dropped.invalidShape,
          unknownBucket: diagnostics.dropped.unknownBucket,
          missingInstanceId: diagnostics.dropped.missingInstanceId,
          topUnknownBuckets,
        },
        byLocation: diagnostics.parsed.byLocation,
        byBucket: diagnostics.parsed.byBucket,
        resolution: diagnostics.resolution,
        manifest: diagnostics.manifest,
      },
      null,
      2,
    ),
  );
}

async function buildPerkNameMap(cache: EntityCache): Promise<Map<number, string>> {
  const perks = await cache.getStore("weapon-perks");
  return new Map(perks.map((p) => [p.hash, p.name]));
}

function normalizeItems(
  rawItems: RawInventoryItem[],
  perkNameMap: Map<number, string>,
  weaponLookup: Map<number, WeaponCatalogRecord>,
  syncedAt: string,
  socketPlugsByInstance: Map<string, StoredSocketPlug[] | null>,
): UserInventoryItem[] {
  return rawItems.map((raw) => {
    const catalogEntry = weaponLookup.get(raw.itemHash) ?? null;
    // Legendary WeaponRecord only — exotics also have perkColumns but not roll columns.
    const weaponRecord =
      catalogEntry && "originTraitHashes" in catalogEntry
        ? (catalogEntry as WeaponRecord)
        : null;
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
      statValues: raw.statValues,
      gearTier: raw.gearTier ?? null,
      socketPlugs: socketPlugsByInstance.get(raw.instanceId) ?? null,
      syncedAt,
    };
  });
}

async function buildSocketPlugsForItems(
  rawItems: RawInventoryItem[],
  manifest: ManifestService,
  manifestVersion: string,
): Promise<Map<string, StoredSocketPlug[] | null>> {
  const byInstance = new Map<string, StoredSocketPlug[] | null>();
  const contextCache = new Map<
    number,
    Awaited<ReturnType<typeof loadWeaponSocketContext>>
  >();

  for (const raw of rawItems) {
    if (!isWeaponBucketHash(raw.bucketHash) || !raw.socketCapture?.length) {
      byInstance.set(raw.instanceId, null);
      continue;
    }

    const allPlugHashes = [
      ...new Set(
        raw.socketCapture.flatMap((row) => [row.equippedPlugHash, ...row.reusablePlugHashes]),
      ),
    ];

    let ctx = contextCache.get(raw.itemHash);
    if (!ctx) {
      ctx = await loadWeaponSocketContext(manifest, manifestVersion, raw.itemHash, allPlugHashes);
      contextCache.set(raw.itemHash, ctx);
    } else {
      const missing = allPlugHashes.filter((hash) => !ctx!.plugCategoryByHash.has(hash));
      if (missing.length > 0) {
        const extra = await loadWeaponSocketContext(
          manifest,
          manifestVersion,
          raw.itemHash,
          [...allPlugHashes, ...missing],
        );
        for (const [hash, category] of extra.plugCategoryByHash) {
          ctx.plugCategoryByHash.set(hash, category);
        }
      }
    }

    const stored = buildStoredSocketPlugs({
      socketCapture: raw.socketCapture,
      plugCategoryByHash: ctx.plugCategoryByHash,
      plugItemTypeByHash: ctx.plugItemTypeByHash,
      weaponPerkSocketIndexes: ctx.weaponPerkSocketIndexes,
    });
    byInstance.set(raw.instanceId, stored);
  }

  return byInstance;
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
  manifest: ManifestService,
  manifestVersion: string,
): Promise<SyncInventoryResult> {
  const membership = await resolveDestinyMembership(profileClient, accessToken);

  if (
    user.membershipType !== membership.membershipType ||
    user.displayName !== membership.displayName
  ) {
    updateUserMembership(db, user.id, membership.membershipType, membership.displayName);
  }

  const { items: rawItems, diagnostics } = await profileClient.getFullInventoryWithDiagnostics(
    accessToken,
    membership,
  );

  const transferItemHashes = rawItems
    .filter((item) => needsEquipmentBucketResolution(item.bucketHash))
    .map((item) => item.itemHash);
  const equipmentBucketLookup = await buildEquipmentBucketLookup(
    manifest,
    manifestVersion,
    transferItemHashes,
  );
  const resolved = resolveTransferContainerBuckets(rawItems, equipmentBucketLookup);

  const [perkNameMap, weaponLookup, exoticArmorHashes] = await Promise.all([
    buildPerkNameMap(entityCache),
    buildWeaponLookup(entityCache),
    buildExoticArmorHashSet(entityCache),
  ]);
  enrichManifestDiagnostics(diagnostics, resolved.items, weaponLookup, exoticArmorHashes);

  const syncedAt = new Date().toISOString();
  const socketPlugsByInstance = await buildSocketPlugsForItems(
    resolved.items,
    manifest,
    manifestVersion,
  );
  const items = normalizeItems(
    resolved.items,
    perkNameMap,
    weaponLookup,
    syncedAt,
    socketPlugsByInstance,
  );
  diagnostics.resolution = {
    resolvedFromTransfer: resolved.resolvedFromTransfer,
    droppedNonEquipment: resolved.droppedNonEquipment,
    storedTotal: items.length,
    storedEquipment: items.filter((item) => item.bucket !== "Subclass").length,
  };
  logInventorySyncDiagnostics(diagnostics);
  upsertInventoryBatch(db, user.id, items);

  const status = getInventoryStatus(db, user.id);
  return {
    itemCount: status?.itemCount ?? items.length,
    syncVersion: status?.syncVersion ?? 1,
    lastFullSyncAt: status?.lastFullSyncAt ?? syncedAt,
    diagnostics,
  };
}

export async function syncUserInventory(
  db: AppDatabase,
  user: DbUser,
  accessToken: string,
  profileClient: BungieProfileClient,
  entityCache: EntityCache,
  manifest: ManifestService,
  manifestVersion: string,
): Promise<SyncInventoryResult> {
  const existing = syncLocks.get(user.id);
  if (existing) {
    throw new SyncInProgressError();
  }

  const syncPromise = performSync(
    db,
    user,
    accessToken,
    profileClient,
    entityCache,
    manifest,
    manifestVersion,
  ).finally(() => {
    syncLocks.delete(user.id);
  });

  syncLocks.set(user.id, syncPromise);
  return syncPromise;
}

/** Test helper: clear in-memory sync mutex state. */
export function clearSyncLocksForTests(): void {
  syncLocks.clear();
}
