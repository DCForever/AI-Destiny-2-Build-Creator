import 'inventory_records.dart';

/// One human-readable plug/perk card for owned instance detail (DART-063).
class ResolvedPlugCard {
  const ResolvedPlugCard({
    required this.hash,
    required this.displayName,
    this.resolved = false,
    this.columnKind,
    this.columnLabel,
    this.isTrait = false,
  });

  final int hash;
  final String displayName;
  final bool resolved;
  final String? columnKind;
  final String? columnLabel;

  /// True when column is a weapon trait (product trait columns).
  final bool isTrait;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResolvedPlugCard &&
        other.hash == hash &&
        other.displayName == displayName &&
        other.resolved == resolved &&
        other.columnKind == columnKind &&
        other.columnLabel == columnLabel &&
        other.isTrait == isTrait;
  }

  @override
  int get hashCode =>
      Object.hash(hash, displayName, resolved, columnKind, columnLabel, isTrait);
}

/// Armor base-stat board from inventory [statValues] when resolvable.
class ArmorBaseStatBoard {
  const ArmorBaseStatBoard({
    required this.stats,
    this.total,
    this.incomplete = false,
  });

  /// Canonical armor stat keys → values (Health/Melee/…).
  final Map<String, int> stats;
  final int? total;
  final bool incomplete;

  bool get hasAny => stats.isNotEmpty;
}

/// Picker-facing projection of one owned inventory copy.
///
/// DART-026: raw hashes. DART-063: human-readable plugs + armor stats when
/// resolvable (GAP-UI-CATALOG-08).
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
    this.statValues,
    this.gearTier,
    this.socketPlugs,
    this.plugCards = const [],
    this.armorStats,
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
  final Map<String, Object?>? statValues;
  final int? gearTier;
  final List<Map<String, Object?>>? socketPlugs;

  /// Human-readable perk/trait cards when resolvable.
  final List<ResolvedPlugCard> plugCards;

  /// Armor base-stat board when [statValues] resolvable; null for weapons.
  final ArmorBaseStatBoard? armorStats;

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

/// Canonical armor stat display order (EoF six-stat board labels).
const armorBaseStatKeys = <String>[
  'Health',
  'Melee',
  'Grenade',
  'Super',
  'Class',
  'Weapons',
];

/// Alternate keys seen in stored stat maps → display label.
const _armorStatAliases = <String, String>{
  'health': 'Health',
  'mobility': 'Health',
  'resilience': 'Health',
  'recovery': 'Health',
  'melee': 'Melee',
  'strength': 'Melee',
  'grenade': 'Grenade',
  'discipline': 'Grenade',
  'super': 'Super',
  'intellect': 'Super',
  'class': 'Class',
  'classability': 'Class',
  'weapons': 'Weapons',
  'weapon': 'Weapons',
};

/// Build armor base-stat board from raw [statValues] map.
///
/// Returns null when nothing resolvable (do not fabricate zeros).
ArmorBaseStatBoard? buildArmorBaseStatBoard(Map<String, Object?>? statValues) {
  if (statValues == null || statValues.isEmpty) return null;

  final stats = <String, int>{};
  for (final e in statValues.entries) {
    final rawKey = e.key.trim();
    if (rawKey.isEmpty) continue;
    final value = e.value;
    final n = value is int
        ? value
        : value is num
            ? value.toInt()
            : int.tryParse('$value');
    if (n == null) continue;

    final lower = rawKey.toLowerCase().replaceAll(RegExp(r'[\s_]'), '');
    final label = armorBaseStatKeys.contains(rawKey)
        ? rawKey
        : _armorStatAliases[lower] ??
            (armorBaseStatKeys.any((k) => k.toLowerCase() == rawKey.toLowerCase())
                ? armorBaseStatKeys.firstWhere(
                    (k) => k.toLowerCase() == rawKey.toLowerCase(),
                  )
                : rawKey);
    // Prefer first write; do not overwrite with duplicate alias collisions poorly
    stats.putIfAbsent(label, () => n);
  }
  if (stats.isEmpty) return null;

  var total = 0;
  var incomplete = false;
  for (final key in armorBaseStatKeys) {
    final v = stats[key];
    if (v == null) {
      incomplete = true;
      continue;
    }
    total += v;
  }
  // Include unknown extra keys in total for completeness display
  for (final e in stats.entries) {
    if (!armorBaseStatKeys.contains(e.key)) {
      total += e.value;
      incomplete = true;
    }
  }

  return ArmorBaseStatBoard(
    stats: Map.unmodifiable(stats),
    total: total,
    incomplete: incomplete || stats.length < armorBaseStatKeys.length,
  );
}

/// Build resolved plug cards from socket plugs and/or flat plug hashes.
///
/// [plugNameByHash] optional — when missing, displayName falls back to
/// columnLabel or `#hash` without inventing perk names.
List<ResolvedPlugCard> buildResolvedPlugCards({
  List<Map<String, Object?>>? socketPlugs,
  List<int> plugHashes = const [],
  Map<int, String> plugNameByHash = const {},
}) {
  final out = <ResolvedPlugCard>[];
  final seen = <int>{};

  if (socketPlugs != null) {
    for (final raw in socketPlugs) {
      final equipped = raw['equippedPlugHash'];
      final hash = equipped is int
          ? equipped
          : equipped is num
              ? equipped.toInt()
              : null;
      if (hash == null || hash == 0) continue;
      if (!seen.add(hash)) continue;
      final columnKind = raw['columnKind'] as String?;
      final columnLabel = raw['columnLabel'] as String?;
      final name = plugNameByHash[hash];
      final isTrait = columnKind == 'trait' ||
          (columnLabel != null &&
              columnLabel.toLowerCase().contains('trait'));
      out.add(
        ResolvedPlugCard(
          hash: hash,
          displayName: name ??
              (columnLabel != null && columnLabel.isNotEmpty
                  ? '$columnLabel (#$hash)'
                  : '#$hash'),
          resolved: name != null && name.isNotEmpty,
          columnKind: columnKind,
          columnLabel: columnLabel,
          isTrait: isTrait,
        ),
      );
    }
  }

  if (out.isEmpty && plugHashes.isNotEmpty) {
    for (final hash in plugHashes) {
      if (hash == 0 || !seen.add(hash)) continue;
      final name = plugNameByHash[hash];
      out.add(
        ResolvedPlugCard(
          hash: hash,
          displayName: name ?? '#$hash',
          resolved: name != null && name.isNotEmpty,
        ),
      );
    }
  }

  return List.unmodifiable(out);
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
  Iterable<InventoryItemRecord> items, {
  Map<int, String> plugNameByHash = const {},
  bool treatAsArmor = false,
}) {
  final out = items
      .map(
        (row) => _toProjection(
          row,
          plugNameByHash: plugNameByHash,
          treatAsArmor: treatAsArmor || _looksLikeArmorBucket(row.bucket),
        ),
      )
      .toList()
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
  int itemHash, {
  Map<int, String> plugNameByHash = const {},
  bool treatAsArmor = false,
}) {
  return projectCatalogInstances(
    items.where((i) => i.itemHash == itemHash),
    plugNameByHash: plugNameByHash,
    treatAsArmor: treatAsArmor,
  );
}

CatalogInstanceProjection _toProjection(
  InventoryItemRecord row, {
  Map<int, String> plugNameByHash = const {},
  bool treatAsArmor = false,
}) {
  final cards = buildResolvedPlugCards(
    socketPlugs: row.socketPlugs,
    plugHashes: row.plugHashes,
    plugNameByHash: plugNameByHash,
  );
  final armor = treatAsArmor ? buildArmorBaseStatBoard(row.statValues) : null;

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
    statValues: row.statValues,
    gearTier: row.gearTier,
    socketPlugs: row.socketPlugs,
    plugCards: cards,
    armorStats: armor,
    syncedAt: row.syncedAt,
  );
}

bool _looksLikeArmorBucket(String bucket) {
  final b = bucket.toLowerCase();
  return b.contains('helmet') ||
      b.contains('gauntlet') ||
      b.contains('chest') ||
      b.contains('leg') ||
      b.contains('class') ||
      b.contains('armor');
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
