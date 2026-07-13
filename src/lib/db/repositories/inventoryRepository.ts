import { eq, and, inArray, sql } from "drizzle-orm";

import type { AppDatabase } from "../client";
import { inventoryItems, inventorySyncMeta, users } from "../schema";
import type { RollTag, UserInventoryItem } from "../types";
import type { StoredSocketPlug } from "@/lib/inventory/instances/types";

export function upsertInventoryBatch(
  db: AppDatabase,
  userId: number,
  items: UserInventoryItem[],
): void {
  const now = new Date().toISOString();
  db.transaction((tx) => {
    for (const item of items) {
      tx.insert(inventoryItems)
        .values({
          userId,
          instanceId: item.instanceId,
          itemHash: item.itemHash,
          bucket: item.bucket,
          location: item.location,
          characterId: item.characterId ?? null,
          power: item.power,
          isMasterwork: item.isMasterwork ? 1 : 0,
          isCrafted: item.isCrafted ? 1 : 0,
          plugHashes: JSON.stringify(item.plugHashes),
          rollTags: JSON.stringify(item.rollTags),
          statValues: item.statValues ? JSON.stringify(item.statValues) : null,
          gearTier: item.gearTier ?? null,
          socketPlugs: item.socketPlugs ? JSON.stringify(item.socketPlugs) : null,
          syncedAt: item.syncedAt || now,
        })
        .onConflictDoUpdate({
          target: [inventoryItems.userId, inventoryItems.instanceId],
          set: {
            itemHash: sql`excluded.item_hash`,
            bucket: sql`excluded.bucket`,
            location: sql`excluded.location`,
            characterId: sql`excluded.character_id`,
            power: sql`excluded.power`,
            isMasterwork: sql`excluded.is_masterwork`,
            isCrafted: sql`excluded.is_crafted`,
            plugHashes: sql`excluded.plug_hashes`,
            rollTags: sql`excluded.roll_tags`,
            statValues: sql`excluded.stat_values`,
            gearTier: sql`excluded.gear_tier`,
            socketPlugs: sql`excluded.socket_plugs`,
            syncedAt: sql`excluded.synced_at`,
          },
        })
        .run();
    }

    const instanceIds = items.map((i) => i.instanceId);
    if (instanceIds.length === 0) {
      tx.delete(inventoryItems).where(eq(inventoryItems.userId, userId)).run();
    } else {
      tx.delete(inventoryItems)
        .where(
          and(
            eq(inventoryItems.userId, userId),
            sql`${inventoryItems.instanceId} NOT IN (${sql.join(instanceIds.map((id) => sql`${id}`), sql`, `)})`,
          ),
        )
        .run();
    }

    const meta = tx.select().from(inventorySyncMeta).where(eq(inventorySyncMeta.userId, userId)).get();
    const syncVersion = (meta?.syncVersion ?? 0) + 1;
    tx.insert(inventorySyncMeta)
      .values({
        userId,
        itemCount: items.length,
        syncVersion,
        lastFullSyncAt: now,
      })
      .onConflictDoUpdate({
        target: inventorySyncMeta.userId,
        set: {
          itemCount: items.length,
          syncVersion,
          lastFullSyncAt: now,
        },
      })
      .run();

    tx.update(users).set({ lastSyncAt: now }).where(eq(users.id, userId)).run();
  });
}

export function getInventoryStatus(
  db: AppDatabase,
  userId: number,
): { itemCount: number; syncVersion: number; lastFullSyncAt: string | null } | null {
  const meta = db.select().from(inventorySyncMeta).where(eq(inventorySyncMeta.userId, userId)).get();
  if (!meta) return null;
  return {
    itemCount: meta.itemCount,
    syncVersion: meta.syncVersion,
    lastFullSyncAt: meta.lastFullSyncAt,
  };
}

export function queryInventoryByBucket(
  db: AppDatabase,
  userId: number,
  bucket: string,
): UserInventoryItem[] {
  const rows = db
    .select()
    .from(inventoryItems)
    .where(and(eq(inventoryItems.userId, userId), eq(inventoryItems.bucket, bucket)))
    .all();
  return rows.map(rowToItem);
}

export function queryInventoryByHashes(
  db: AppDatabase,
  userId: number,
  itemHashes: number[],
): UserInventoryItem[] {
  if (itemHashes.length === 0) return [];
  const rows = db
    .select()
    .from(inventoryItems)
    .where(and(eq(inventoryItems.userId, userId), inArray(inventoryItems.itemHash, itemHashes)))
    .all();
  return rows.map(rowToItem);
}

export function listInventoryItems(db: AppDatabase, userId: number): UserInventoryItem[] {
  const rows = db.select().from(inventoryItems).where(eq(inventoryItems.userId, userId)).all();
  return rows.map(rowToItem);
}

export function queryInventoryByTags(
  db: AppDatabase,
  userId: number,
  tag: RollTag,
  limit = 20,
): UserInventoryItem[] {
  const rows = db.select().from(inventoryItems).where(eq(inventoryItems.userId, userId)).all();
  return rows
    .map(rowToItem)
    .filter((item) => item.rollTags.includes(tag))
    .slice(0, limit);
}

function rowToItem(row: typeof inventoryItems.$inferSelect): UserInventoryItem {
  const statValues = row.statValues
    ? (JSON.parse(row.statValues) as Partial<Record<string, number>>)
    : undefined;
  return {
    instanceId: row.instanceId,
    itemHash: row.itemHash,
    bucket: row.bucket,
    location: row.location as UserInventoryItem["location"],
    characterId: row.characterId ?? undefined,
    power: row.power,
    isMasterwork: row.isMasterwork === 1,
    isCrafted: row.isCrafted === 1,
    plugHashes: JSON.parse(row.plugHashes) as number[],
    rollTags: JSON.parse(row.rollTags) as RollTag[],
    statValues,
    gearTier: row.gearTier ?? null,
    socketPlugs: row.socketPlugs
      ? (JSON.parse(row.socketPlugs) as StoredSocketPlug[])
      : null,
    syncedAt: row.syncedAt,
  };
}
