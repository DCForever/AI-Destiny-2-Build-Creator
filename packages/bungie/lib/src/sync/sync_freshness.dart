import 'package:destiny2_db/destiny2_db.dart';

import '../profile/bungie_profile_client.dart';
import 'sync_inventory.dart';

/// Reuse inventory sync when last full sync is within this window (DBR-EQP-007).
///
/// Product: `EQUIP_SYNC_FRESH_MS = 60_000`.
const int kEquipSyncFreshMs = 60000;

/// Result of [syncIfStale].
class SyncIfStaleResult {
  const SyncIfStaleResult({
    required this.synced,
    required this.lastFullSyncAt,
    this.result,
  });

  final bool synced;
  final String? lastFullSyncAt;
  final SyncInventoryResult? result;
}

/// Whether [lastFullSyncAt] is within [freshMs] of [nowMs].
///
/// Returns false for null, unparseable timestamps, or future-dated stamps
/// that would yield negative age.
bool isInventoryFresh(
  String? lastFullSyncAt, {
  int? nowMs,
  int freshMs = kEquipSyncFreshMs,
}) {
  if (lastFullSyncAt == null || lastFullSyncAt.isEmpty) return false;
  final syncedAt = DateTime.tryParse(lastFullSyncAt);
  if (syncedAt == null) return false;
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final age = now - syncedAt.millisecondsSinceEpoch;
  return age >= 0 && age < freshMs;
}

/// Sync inventory only when last full sync is missing or older than 60s.
Future<SyncIfStaleResult> syncIfStale({
  required AppDatabase db,
  required int userId,
  required String accessToken,
  required BungieProfileClient profileClient,
  Map<int, int>? equipmentBucketLookup,
  String? now,
  int? nowMs,
  InventoryBusyLock? lock,
}) async {
  final status = await getInventoryStatus(db, userId);
  final clock = nowMs ??
      (now != null
          ? DateTime.parse(now).millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch);

  if (isInventoryFresh(status?.lastFullSyncAt, nowMs: clock)) {
    return SyncIfStaleResult(
      synced: false,
      lastFullSyncAt: status?.lastFullSyncAt,
    );
  }

  final result = await syncUserInventory(
    db: db,
    userId: userId,
    accessToken: accessToken,
    profileClient: profileClient,
    equipmentBucketLookup: equipmentBucketLookup,
    now: now ??
        DateTime.fromMillisecondsSinceEpoch(clock, isUtc: true)
            .toIso8601String(),
    lock: lock,
  );

  return SyncIfStaleResult(
    synced: true,
    lastFullSyncAt: result.lastFullSyncAt,
    result: result,
  );
}
