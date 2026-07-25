import 'roll_tags.dart';

/// Build plugHash → display name from DestinyInventoryItemDefinition-shaped data.
///
/// Used when MVP entity stores lack a dedicated `weapon-perks` store (DART-051).
/// Reads `displayProperties.name` for each requested plug hash.
Map<int, String> buildPerkNameMapFromItemDefs(
  Map<dynamic, dynamic> inventoryItemDefinitionTable,
  Iterable<int> plugHashes,
) {
  if (plugHashes.isEmpty) return const {};

  final map = <int, String>{};
  for (final hash in plugHashes.toSet()) {
    final raw = _tableEntry(inventoryItemDefinitionTable, hash);
    if (raw is! Map) continue;
    final display = raw['displayProperties'];
    if (display is! Map) continue;
    final name = display['name'];
    if (name is String && name.isNotEmpty) {
      map[hash] = name;
    }
  }
  return map;
}

/// Minimal catalog-like row for weapon roll meta (OfflineCatalog / entity weapons).
class WeaponRollMetaSource {
  const WeaponRollMetaSource({
    required this.hash,
    required this.frame,
    required this.itemTypeName,
    this.isExotic = false,
  });

  final int hash;
  final String frame;
  final String itemTypeName;

  /// When true, skipped for frame champion path (Next legendary WeaponRecord only).
  final bool isExotic;
}

/// Build itemHash → [RollTagWeaponMeta] for legendary weapons with frame + type.
///
/// Mirrors Next using only legendary `WeaponRecord` (not exotic-weapons) for
/// frame-based champion tags.
Map<int, RollTagWeaponMeta> buildWeaponRollMetaLookup(
  Iterable<WeaponRollMetaSource> sources, {
  Iterable<int>? onlyHashes,
}) {
  final filter = onlyHashes?.toSet();
  final lookup = <int, RollTagWeaponMeta>{};
  for (final src in sources) {
    if (src.isExotic) continue;
    if (filter != null && !filter.contains(src.hash)) continue;
    if (src.frame.isEmpty || src.itemTypeName.isEmpty) continue;
    lookup[src.hash] = RollTagWeaponMeta(
      frame: src.frame,
      itemTypeName: src.itemTypeName,
    );
  }
  return lookup;
}

/// Optional async builder: plug hashes → perk display names.
typedef PerkNameMapBuilder = Future<Map<int, String>> Function(
  List<int> plugHashes,
);

/// Optional async builder: inventory itemHashes → weapon roll meta.
typedef WeaponRollMetaLookupBuilder = Future<Map<int, RollTagWeaponMeta>> Function(
  List<int> itemHashes,
);

Object? _tableEntry(Map<dynamic, dynamic> table, int hash) {
  if (table.containsKey(hash)) return table[hash];
  final asString = '$hash';
  if (table.containsKey(asString)) return table[asString];
  return null;
}
