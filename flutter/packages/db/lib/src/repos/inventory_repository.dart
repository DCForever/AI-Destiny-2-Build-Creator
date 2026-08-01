import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import 'inventory_busy_lock.dart';
import 'inventory_records.dart';
import 'json_codec.dart';

InventoryItemRecord _rowToItem(InventoryItem row) {
  return InventoryItemRecord(
    instanceId: row.instanceId,
    itemHash: row.itemHash,
    bucket: row.bucket,
    location: row.location,
    characterId: row.characterId,
    power: row.power,
    isMasterwork: row.isMasterwork == 1,
    isCrafted: row.isCrafted == 1,
    plugHashes: parseIntJsonArray(row.plugHashes),
    rollTags: parseStringJsonArray(row.rollTags),
    statValues: parseJsonObjectMap(row.statValues),
    gearTier: row.gearTier,
    socketPlugs: parseJsonObjectList(row.socketPlugs),
    syncedAt: row.syncedAt,
  );
}

InventoryItemsCompanion _itemToCompanion(int userId, InventoryItemRecord item) {
  return InventoryItemsCompanion.insert(
    userId: userId,
    instanceId: item.instanceId,
    itemHash: item.itemHash,
    bucket: item.bucket,
    location: item.location,
    characterId: Value(item.characterId),
    power: Value(item.power),
    isMasterwork: Value(item.isMasterwork ? 1 : 0),
    isCrafted: Value(item.isCrafted ? 1 : 0),
    plugHashes: Value(encodeIntJsonArray(item.plugHashes)),
    rollTags: Value(encodeStringJsonArray(item.rollTags)),
    statValues: Value(encodeJsonObjectMap(item.statValues)),
    gearTier: Value(item.gearTier),
    socketPlugs: Value(encodeJsonObjectList(item.socketPlugs)),
    syncedAt: item.syncedAt,
  );
}

/// Full-replace inventory for [userId] in **one** transaction (lock-free).
///
/// Full-replace shape (product `upsertInventoryBatch` intent):
/// 1. Delete existing rows for the user
/// 2. Batch-insert the new set (composite unique `(user_id, instance_id)` enforced)
/// 3. Upsert `inventory_sync_meta` with incremented `syncVersion`
/// 4. Update `users.last_sync_at`
///
/// Returns the new [InventorySyncStatus].
Future<InventorySyncStatus> replaceInventoryBatch(
  AppDatabase db,
  int userId, {
  required List<InventoryItemRecord> items,
  required String now,
}) {
  return db.transaction(() async {
    // 1) Clear prior inventory for this user.
    await (db.delete(db.inventoryItems)..where((t) => t.userId.equals(userId)))
        .go();

    // 2) Batch insert the new set.
    if (items.isNotEmpty) {
      await db.batch((batch) {
        for (final item in items) {
          batch.insert(db.inventoryItems, _itemToCompanion(userId, item));
        }
      });
    }

    // 3) Bump sync meta.
    final prior = await (db.select(db.inventorySyncMeta)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    final nextVersion = (prior?.syncVersion ?? 0) + 1;
    final status = InventorySyncStatus(
      itemCount: items.length,
      syncVersion: nextVersion,
      lastFullSyncAt: now,
    );

    await db.into(db.inventorySyncMeta).insertOnConflictUpdate(
          InventorySyncMetaCompanion(
            userId: Value(userId),
            itemCount: Value(status.itemCount),
            syncVersion: Value(status.syncVersion),
            lastFullSyncAt: Value(status.lastFullSyncAt),
          ),
        );

    // 4) users.last_sync_at
    await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
          UsersCompanion(lastSyncAt: Value(now)),
        );

    return status;
  });
}

/// Full-replace under [lock] (default shared busy lock).
///
/// Throws [InventoryReplaceBusyException] if [userId] already has an exclusive
/// replace in flight.
Future<InventorySyncStatus> replaceInventoryBatchExclusive(
  AppDatabase db,
  int userId, {
  required List<InventoryItemRecord> items,
  required String now,
  InventoryBusyLock? lock,
}) {
  final gate = lock ?? defaultInventoryBusyLock;
  return gate.runExclusive(
    userId,
    () => replaceInventoryBatch(db, userId, items: items, now: now),
  );
}

/// Whether [userId] is busy under the default (or provided) lock.
bool isInventoryReplaceBusy(int userId, {InventoryBusyLock? lock}) {
  return (lock ?? defaultInventoryBusyLock).isBusy(userId);
}

Future<InventorySyncStatus?> getInventoryStatus(
  AppDatabase db,
  int userId,
) async {
  final row = await (db.select(db.inventorySyncMeta)
        ..where((t) => t.userId.equals(userId)))
      .getSingleOrNull();
  if (row == null) return null;
  return InventorySyncStatus(
    itemCount: row.itemCount,
    syncVersion: row.syncVersion,
    lastFullSyncAt: row.lastFullSyncAt,
  );
}

Future<List<InventoryItemRecord>> listInventoryItems(
  AppDatabase db,
  int userId,
) async {
  final rows = await (db.select(db.inventoryItems)
        ..where((t) => t.userId.equals(userId)))
      .get();
  return rows.map(_rowToItem).toList();
}

Future<List<InventoryItemRecord>> queryInventoryByBucket(
  AppDatabase db,
  int userId,
  String bucket,
) async {
  final rows = await (db.select(db.inventoryItems)
        ..where(
          (t) => t.userId.equals(userId) & t.bucket.equals(bucket),
        ))
      .get();
  return rows.map(_rowToItem).toList();
}

Future<List<InventoryItemRecord>> queryInventoryByHashes(
  AppDatabase db,
  int userId,
  List<int> itemHashes,
) async {
  if (itemHashes.isEmpty) return const [];
  final rows = await (db.select(db.inventoryItems)
        ..where(
          (t) => t.userId.equals(userId) & t.itemHash.isIn(itemHashes),
        ))
      .get();
  return rows.map(_rowToItem).toList();
}

Future<List<InventoryItemRecord>> queryInventoryByInstanceIds(
  AppDatabase db,
  int userId,
  List<String> instanceIds,
) async {
  if (instanceIds.isEmpty) return const [];
  final rows = await (db.select(db.inventoryItems)
        ..where(
          (t) => t.userId.equals(userId) & t.instanceId.isIn(instanceIds),
        ))
      .get();
  return rows.map(_rowToItem).toList();
}

/// Filter in memory by roll tag (product scans all user rows).
Future<List<InventoryItemRecord>> queryInventoryByTags(
  AppDatabase db,
  int userId,
  String tag, {
  int limit = 20,
}) async {
  final all = await listInventoryItems(db, userId);
  return all.where((i) => i.rollTags.contains(tag)).take(limit).toList();
}
