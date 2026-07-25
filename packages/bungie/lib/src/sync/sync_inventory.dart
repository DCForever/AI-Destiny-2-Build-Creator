import 'dart:async';

import 'package:destiny2_db/destiny2_db.dart';

import '../inventory/roll_tag_lookups.dart';
import '../inventory/roll_tags.dart';
import '../profile/bungie_profile_client.dart';
import '../profile/equipment_bucket_lookup.dart';
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
/// - [equipmentBucketLookup] / [equipmentBucketLookupBuilder] map itemHash → equipment
///   bucketHash for vault/postmaster resolution.
/// - **Production hosts MUST wire a non-empty lookup** whenever entity/manifest data
///   is available (DART-050 / GAP-INV-01). Empty lookup is test-only — transfer
///   containers (vault General / postmaster) are dropped before Drift write.
/// - [perkNameMap] / [perkNameMapBuilder] + [weaponRollMetaLookup] /
///   [weaponRollMetaLookupBuilder] supply DART-051 roll tag enrichment inputs
///   (Next `computeRollTags` parity). Empty maps → Crafted-only when `isCrafted`.
/// - [now] ISO-8601 timestamp written as syncedAt / lastFullSyncAt (injectable for tests).
Future<SyncInventoryResult> syncUserInventory({
  required AppDatabase db,
  required int userId,
  required String accessToken,
  required BungieProfileClient profileClient,
  Map<int, int>? equipmentBucketLookup,
  EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder,
  Map<int, String>? perkNameMap,
  PerkNameMapBuilder? perkNameMapBuilder,
  Map<int, RollTagWeaponMeta>? weaponRollMetaLookup,
  WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder,
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
        equipmentBucketLookup: equipmentBucketLookup,
        equipmentBucketLookupBuilder: equipmentBucketLookupBuilder,
        perkNameMap: perkNameMap,
        perkNameMapBuilder: perkNameMapBuilder,
        weaponRollMetaLookup: weaponRollMetaLookup,
        weaponRollMetaLookupBuilder: weaponRollMetaLookupBuilder,
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
  Map<int, int>? equipmentBucketLookup,
  EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder,
  Map<int, String>? perkNameMap,
  PerkNameMapBuilder? perkNameMapBuilder,
  Map<int, RollTagWeaponMeta>? weaponRollMetaLookup,
  WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder,
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

  final transferHashes = <int>[
    for (final item in parsed.items)
      if (needsEquipmentBucketResolution(item.bucketHash)) item.itemHash,
  ];
  final lookup = await _resolveEquipmentBucketLookup(
    transferHashes: transferHashes,
    equipmentBucketLookup: equipmentBucketLookup,
    equipmentBucketLookupBuilder: equipmentBucketLookupBuilder,
  );

  final resolved = resolveTransferContainerBuckets(
    parsed.items,
    lookup,
  );

  final plugHashes = <int>[
    for (final item in resolved.items) ...item.plugHashes,
  ];
  final itemHashes = <int>[
    for (final item in resolved.items) item.itemHash,
  ];
  final resolvedPerkMap = await _resolvePerkNameMap(
    plugHashes: plugHashes,
    perkNameMap: perkNameMap,
    perkNameMapBuilder: perkNameMapBuilder,
  );
  final resolvedWeaponMeta = await _resolveWeaponRollMetaLookup(
    itemHashes: itemHashes,
    weaponRollMetaLookup: weaponRollMetaLookup,
    weaponRollMetaLookupBuilder: weaponRollMetaLookupBuilder,
  );

  final records = _normalizeItems(
    resolved.items,
    now,
    perkNameMap: resolvedPerkMap,
    weaponRollMetaLookup: resolvedWeaponMeta,
  );

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

/// Merge explicit map with async builder (explicit entries win on conflict).
Future<Map<int, int>> _resolveEquipmentBucketLookup({
  required List<int> transferHashes,
  Map<int, int>? equipmentBucketLookup,
  EquipmentBucketLookupBuilder? equipmentBucketLookupBuilder,
}) async {
  final merged = <int, int>{};
  if (equipmentBucketLookupBuilder != null && transferHashes.isNotEmpty) {
    merged.addAll(await equipmentBucketLookupBuilder(transferHashes));
  }
  if (equipmentBucketLookup != null) {
    merged.addAll(equipmentBucketLookup);
  }
  return merged;
}

Future<Map<int, String>> _resolvePerkNameMap({
  required List<int> plugHashes,
  Map<int, String>? perkNameMap,
  PerkNameMapBuilder? perkNameMapBuilder,
}) async {
  final merged = <int, String>{};
  if (perkNameMapBuilder != null && plugHashes.isNotEmpty) {
    merged.addAll(await perkNameMapBuilder(plugHashes));
  }
  if (perkNameMap != null) {
    merged.addAll(perkNameMap);
  }
  return merged;
}

Future<Map<int, RollTagWeaponMeta>> _resolveWeaponRollMetaLookup({
  required List<int> itemHashes,
  Map<int, RollTagWeaponMeta>? weaponRollMetaLookup,
  WeaponRollMetaLookupBuilder? weaponRollMetaLookupBuilder,
}) async {
  final merged = <int, RollTagWeaponMeta>{};
  if (weaponRollMetaLookupBuilder != null && itemHashes.isNotEmpty) {
    merged.addAll(await weaponRollMetaLookupBuilder(itemHashes));
  }
  if (weaponRollMetaLookup != null) {
    merged.addAll(weaponRollMetaLookup);
  }
  return merged;
}

List<InventoryItemRecord> _normalizeItems(
  List<RawInventoryItem> rawItems,
  String syncedAt, {
  Map<int, String> perkNameMap = const {},
  Map<int, RollTagWeaponMeta> weaponRollMetaLookup = const {},
}) {
  return rawItems.map((raw) {
    final rollTags = computeRollTags(
      raw.plugHashes,
      perkNameMap,
      weapon: weaponRollMetaLookup[raw.itemHash],
      isCrafted: raw.isCrafted,
    );
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
