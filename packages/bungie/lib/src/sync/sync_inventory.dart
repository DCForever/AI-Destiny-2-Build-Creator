import 'package:destiny2_db/destiny2_db.dart';

import '../profile/bungie_profile_client.dart';
import '../profile/inventory_buckets.dart';
import '../profile/inventory_parse.dart';
import '../profile/profile_types.dart';

/// Result of a successful full inventory sync into Drift.
class SyncInventoryResult {
  const SyncInventoryResult({
    required this.itemCount,
    required this.syncVersion,
    required this.lastFullSyncAt,
    required this.diagnostics,
  });

  final int itemCount;
  final int syncVersion;
  final String lastFullSyncAt;
  final InventoryParseDiagnostics diagnostics;
}

/// Thrown when inventory sync is already in progress for the user.
///
/// Mirrors product `SyncInProgressError` / DART-016 busy lock.
class SyncInProgressError implements Exception {
  SyncInProgressError([this.message = 'Inventory sync already in progress for this user']);

  final String message;

  @override
  String toString() => 'SyncInProgressError: $message';
}

/// Resolve Destiny membership, fetch inventory, full-replace into Drift.
///
/// - Uses first membership from [BungieProfileClient.getMemberships] (primary-sorted).
/// - Updates local user membership type/display when changed.
/// - Optional [equipmentBucketLookup] maps itemHash → equipment bucketHash for
///   vault/postmaster resolution; without it, transfer-container items are dropped.
/// - [now] ISO-8601 timestamp written as syncedAt / lastFullSyncAt (injectable for tests).
Future<SyncInventoryResult> syncUserInventory({
  required AppDatabase db,
  required int userId,
  required String accessToken,
  required BungieProfileClient profileClient,
  Map<int, int>? equipmentBucketLookup,
  String? now,
  InventoryBusyLock? lock,
}) async {
  try {
    return await (lock ?? defaultInventoryBusyLock).runExclusive(userId, () async {
      return _performSync(
        db: db,
        userId: userId,
        accessToken: accessToken,
        profileClient: profileClient,
        equipmentBucketLookup: equipmentBucketLookup ?? const {},
        now: now ?? DateTime.now().toUtc().toIso8601String(),
      );
    });
  } on InventoryReplaceBusyException {
    throw SyncInProgressError();
  }
}

Future<SyncInventoryResult> _performSync({
  required AppDatabase db,
  required int userId,
  required String accessToken,
  required BungieProfileClient profileClient,
  required Map<int, int> equipmentBucketLookup,
  required String now,
}) async {
  final memberships = await profileClient.getMemberships(accessToken);
  if (memberships.isEmpty) {
    throw StateError('No Destiny memberships found');
  }
  final membership = memberships.first;

  final user = await getUser(db, userId);
  if (user == null) {
    throw StateError('User $userId not found');
  }
  if (user.membershipType != membership.membershipType ||
      user.displayName != membership.displayName) {
    await updateUserMembership(
      db,
      userId,
      membershipType: membership.membershipType,
      displayName: membership.displayName,
    );
  }

  final parsed = await profileClient.getFullInventoryWithDiagnostics(
    accessToken,
    membership,
  );

  final resolved = resolveTransferContainerBuckets(
    parsed.items,
    equipmentBucketLookup,
  );
  final records = _normalizeItems(resolved.items, now);

  parsed.diagnostics.resolution = InventoryResolutionCounts(
    resolvedFromTransfer: resolved.resolvedFromTransfer,
    droppedNonEquipment: resolved.droppedNonEquipment,
    storedTotal: records.length,
    storedEquipment:
        records.where((i) => i.bucket != inventoryBucketLabel(kSubclassBucketHash)).length,
  );

  // Exclusive lock already held — use non-exclusive replace inside.
  final status = await replaceInventoryBatch(
    db,
    userId,
    items: records,
    now: now,
  );

  return SyncInventoryResult(
    itemCount: status.itemCount,
    syncVersion: status.syncVersion,
    lastFullSyncAt: status.lastFullSyncAt ?? now,
    diagnostics: parsed.diagnostics,
  );
}

List<InventoryItemRecord> _normalizeItems(
  List<RawInventoryItem> rawItems,
  String syncedAt,
) {
  return rawItems.map((raw) {
    final rollTags = <String>[
      if (raw.isCrafted) 'Crafted',
    ];
    final socketPlugs = raw.socketCapture
        ?.map((s) => s.toJsonMap())
        .toList(growable: false);
    return InventoryItemRecord(
      instanceId: raw.instanceId,
      itemHash: raw.itemHash,
      bucket: inventoryBucketLabel(raw.bucketHash),
      location: raw.location,
      characterId: raw.characterId,
      power: raw.power,
      isMasterwork: raw.isMasterwork,
      isCrafted: raw.isCrafted,
      plugHashes: raw.plugHashes,
      rollTags: rollTags,
      statValues: raw.statValues,
      gearTier: raw.gearTier,
      socketPlugs: socketPlugs,
      syncedAt: syncedAt,
    );
  }).toList(growable: false);
}
