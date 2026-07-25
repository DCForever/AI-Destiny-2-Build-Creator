import 'inventory_records.dart';

/// Picker-facing projection of one owned inventory copy (DART-026).
///
/// Raw plug hashes only — perk name resolution is out of scope for this slice.
class CatalogInstanceProjection {
  const CatalogInstanceProjection({
    required this.instanceId,
    required this.itemHash,
    required this.bucket,
    required this.location,
    this.characterId,
    required this.power,
    this.isMasterwork = false,
    this.isCrafted = false,
    this.plugHashes = const [],
    this.rollTags = const [],
    required this.syncedAt,
  });

  final String instanceId;
  final int itemHash;
  final String bucket;
  final String location;
  final String? characterId;
  final int power;
  final bool isMasterwork;
  final bool isCrafted;
  final List<int> plugHashes;
  final List<String> rollTags;
  final String syncedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogInstanceProjection &&
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
        syncedAt,
      );

  @override
  String toString() =>
      'CatalogInstanceProjection($instanceId, hash=$itemHash, power=$power)';
}

/// Count owned instances by definition hash (inventory → owned map).
Map<int, int> ownedHashCountsFromInventory(Iterable<InventoryItemRecord> items) {
  final counts = <int, int>{};
  for (final item in items) {
    counts[item.itemHash] = (counts[item.itemHash] ?? 0) + 1;
  }
  return counts;
}

/// Project all inventory rows to picker DTOs (power descending).
List<CatalogInstanceProjection> projectCatalogInstances(
  Iterable<InventoryItemRecord> items,
) {
  final out = items.map(_toProjection).toList()
    ..sort((a, b) {
      final byPower = b.power.compareTo(a.power);
      if (byPower != 0) return byPower;
      return a.instanceId.compareTo(b.instanceId);
    });
  return out;
}

/// Project owned copies for a single [itemHash] (power descending).
List<CatalogInstanceProjection> projectInstancesForHash(
  Iterable<InventoryItemRecord> items,
  int itemHash,
) {
  return projectCatalogInstances(
    items.where((i) => i.itemHash == itemHash),
  );
}

CatalogInstanceProjection _toProjection(InventoryItemRecord row) {
  return CatalogInstanceProjection(
    instanceId: row.instanceId,
    itemHash: row.itemHash,
    bucket: row.bucket,
    location: row.location,
    characterId: row.characterId,
    power: row.power,
    isMasterwork: row.isMasterwork,
    isCrafted: row.isCrafted,
    plugHashes: List<int>.unmodifiable(row.plugHashes),
    rollTags: List<String>.unmodifiable(row.rollTags),
    syncedAt: row.syncedAt,
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
