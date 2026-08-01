/// Persistence DTOs for inventory repositories (DART-016).
///
/// Mirror product `UserInventoryItem` / inventory sync meta shapes.

/// Owned inventory instance row (one copy of a definition hash).
class InventoryItemRecord {
  const InventoryItemRecord({
    required this.instanceId,
    required this.itemHash,
    required this.bucket,
    required this.location,
    this.characterId,
    this.power = 0,
    this.isMasterwork = false,
    this.isCrafted = false,
    this.plugHashes = const [],
    this.rollTags = const [],
    this.statValues,
    this.gearTier,
    this.socketPlugs,
    required this.syncedAt,
  });

  final String instanceId;
  final int itemHash;
  final String bucket;

  /// Product: `vault` | `character` | `equipped`.
  final String location;
  final String? characterId;
  final int power;
  final bool isMasterwork;
  final bool isCrafted;
  final List<int> plugHashes;
  final List<String> rollTags;
  final Map<String, Object?>? statValues;
  final int? gearTier;

  /// List of socket plug maps (product `StoredSocketPlug` JSON shape).
  final List<Map<String, Object?>>? socketPlugs;
  final String syncedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItemRecord &&
        other.instanceId == instanceId &&
        other.itemHash == itemHash &&
        other.bucket == bucket &&
        other.location == location &&
        other.characterId == characterId &&
        other.power == power &&
        other.isMasterwork == isMasterwork &&
        other.isCrafted == isCrafted &&
        _listEq(other.plugHashes, plugHashes) &&
        _listEq(other.rollTags, rollTags) &&
        _mapEq(other.statValues, statValues) &&
        other.gearTier == gearTier &&
        _socketEq(other.socketPlugs, socketPlugs) &&
        other.syncedAt == syncedAt;
  }

  @override
  int get hashCode => Object.hash(
        instanceId,
        itemHash,
        bucket,
        location,
        characterId,
        power,
        isMasterwork,
        isCrafted,
        Object.hashAll(plugHashes),
        Object.hashAll(rollTags),
        gearTier,
        syncedAt,
      );
}

/// Sync metadata for a user's last full inventory replace.
class InventorySyncStatus {
  const InventorySyncStatus({
    required this.itemCount,
    required this.syncVersion,
    this.lastFullSyncAt,
  });

  final int itemCount;
  final int syncVersion;
  final String? lastFullSyncAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventorySyncStatus &&
        other.itemCount == itemCount &&
        other.syncVersion == syncVersion &&
        other.lastFullSyncAt == lastFullSyncAt;
  }

  @override
  int get hashCode => Object.hash(itemCount, syncVersion, lastFullSyncAt);
}

bool _listEq<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq(Map<String, Object?>? a, Map<String, Object?>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

bool _socketEq(
  List<Map<String, Object?>>? a,
  List<Map<String, Object?>>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_mapEq(a[i], b[i])) return false;
  }
  return true;
}
