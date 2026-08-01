import 'inventory_buckets.dart';

/// Slot / equipment labels that map to inventory equipment bucket hashes.
///
/// Used when hosts only have entity/catalog rows (no raw DestinyInventoryItemDefinition).
const Map<String, int> kEquipmentSlotLabelToBucketHash = {
  'Kinetic': 1498876634,
  'Energy': 2465295065,
  'Power': 953998645,
  'Helmet': 3448274439,
  'Gauntlets': 3551918588,
  'Chest': 14239492,
  'Legs': 20886954,
  'ClassItem': 1585787867,
  'Subclass': kSubclassBucketHash,
};

/// Build itemHash → equipment bucketHash from DestinyInventoryItemDefinition-shaped data.
///
/// Parity with product `buildEquipmentBucketLookup` in
/// `src/lib/bungie/resolveEquipmentBuckets.ts`.
///
/// [inventoryItemDefinitionTable] is a hash-keyed raw table map (string or int keys).
/// Only definitions whose `inventory.bucketTypeHash` is an **equipment** bucket are
/// retained. Non-equipment buckets (shaders, consumables, etc.) are omitted so
/// transfer-container items fall through to `droppedNonEquipment`.
///
/// **Production hosts MUST supply a non-empty lookup** when entity/manifest data is
/// available. An empty map is valid for unit tests of the drop path only — it is
/// **not** production-OK (vault/postmaster copies are dropped).
Map<int, int> buildEquipmentBucketLookup(
  Map<dynamic, dynamic> inventoryItemDefinitionTable,
  Iterable<int> itemHashes,
) {
  if (itemHashes.isEmpty) return const {};

  final lookup = <int, int>{};
  for (final hash in itemHashes.toSet()) {
    final raw = _tableEntry(inventoryItemDefinitionTable, hash);
    if (raw is! Map) continue;
    final inventory = raw['inventory'];
    if (inventory is! Map) continue;
    final bucketTypeHash = _asInt(inventory['bucketTypeHash']);
    if (bucketTypeHash == null) continue;
    if (!isEquipmentBucketHash(bucketTypeHash)) continue;
    lookup[hash] = bucketTypeHash;
  }
  return lookup;
}

/// Build itemHash → equipment bucketHash from catalog/entity **slot labels**.
///
/// Fallback when raw DestinyInventoryItemDefinition is unavailable (e.g. web
/// prebuilt entity bundles without full raw tables). Incomplete vs full raw
/// table (legendary armor may be missing from MVP entity stores).
///
/// [itemHashToSlotLabel] values should be Kinetic/Energy/Power/Helmet/… labels.
Map<int, int> buildEquipmentBucketLookupFromSlots(
  Map<int, String> itemHashToSlotLabel, {
  Iterable<int>? onlyHashes,
}) {
  final hashes = onlyHashes?.toSet();
  final lookup = <int, int>{};
  for (final entry in itemHashToSlotLabel.entries) {
    if (hashes != null && !hashes.contains(entry.key)) continue;
    final bucket = kEquipmentSlotLabelToBucketHash[entry.value];
    if (bucket == null) continue;
    if (!isEquipmentBucketHash(bucket)) continue;
    lookup[entry.key] = bucket;
  }
  return lookup;
}

/// Optional async builder: given transfer-container item hashes, return lookup.
///
/// Production sync paths should inject a builder that loads raw definitions
/// and/or entity slot maps (see host wiring). Empty result drops vault/postmaster.
typedef EquipmentBucketLookupBuilder = Future<Map<int, int>> Function(
  List<int> transferItemHashes,
);

Object? _tableEntry(Map<dynamic, dynamic> table, int hash) {
  if (table.containsKey(hash)) return table[hash];
  final asString = '$hash';
  if (table.containsKey(asString)) return table[asString];
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
