import 'classify_weapon_socket.dart';
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

/// Build plugHash → Bungie icon path from DestinyInventoryItemDefinition.
///
/// Reads `displayProperties.icon` (e.g. `/common/destiny2_content/icons/…`).
/// Used for icon-first perk cells (DIM-style); never invents paths.
Map<int, String> buildPerkIconMapFromItemDefs(
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
    final icon = display['icon'];
    if (icon is String && icon.trim().isNotEmpty) {
      map[hash] = icon.trim();
    }
  }
  return map;
}

/// Build plugHash → definition description from DestinyInventoryItemDefinition.
///
/// Reads `displayProperties.description` only — never invents Destiny copy
/// (DBR-UI-005 / DART-071 host map contract). Empty/missing omitted from map
/// so resolve yields honest empty description.
Map<int, String> buildPerkDescriptionMapFromItemDefs(
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
    final desc = display['description'];
    if (desc is String && desc.trim().isNotEmpty) {
      map[hash] = desc.trim();
    }
  }
  return map;
}

/// Build plugHash → enhanced flag from DestinyInventoryItemDefinition.
///
/// Primary enhanced path for catalog gold/E (GAP-CAT-PERK-002): uses
/// [isEnhancedPlug] with **name + plugCategoryIdentifier** so plugs whose
/// display name omits "Enhanced" but sit under `enhancements.v2` / `enhanced`
/// categories still mark true. Only `true` entries are retained (unknown /
/// false omitted). Never invents hashes.
///
/// Name-only empty-category is a **fallback** for hosts without raw defs —
/// not the primary production path.
Map<int, bool> buildPlugEnhancedMapFromItemDefs(
  Map<dynamic, dynamic> inventoryItemDefinitionTable,
  Iterable<int> plugHashes,
) {
  if (plugHashes.isEmpty) return const {};

  final map = <int, bool>{};
  for (final hash in plugHashes.toSet()) {
    if (hash == 0) continue;
    final raw = _tableEntry(inventoryItemDefinitionTable, hash);
    if (raw is! Map) continue;
    final display = raw['displayProperties'];
    final name = display is Map ? display['name'] as String? : null;
    var category = '';
    final plugBlock = raw['plug'];
    if (plugBlock is Map) {
      final cat = plugBlock['plugCategoryIdentifier'];
      if (cat is String) category = cat;
    }
    if (isEnhancedPlug(name, category)) {
      map[hash] = true;
    }
  }
  return map;
}

/// Seed plugHash → display name from catalog/entity rows (hash + name).
///
/// Web residual path (GAP-INV-02): MVP entity stores project mods/weapons/armor
/// as named rows; when a plug hash collides with a projected entity, resolve the
/// display name without raw DestinyInventoryItemDefinition. Missing hashes are
/// omitted (never invent names). Soft metadata only.
Map<int, String> buildPerkNameMapFromNamedHashes(
  Iterable<({int hash, String name})> named, {
  Iterable<int>? onlyHashes,
}) {
  final filter = onlyHashes?.toSet();
  final map = <int, String>{};
  for (final row in named) {
    if (row.hash == 0) continue;
    if (filter != null && !filter.contains(row.hash)) continue;
    final n = row.name.trim();
    if (n.isEmpty) continue;
    map.putIfAbsent(row.hash, () => n);
  }
  return map;
}

/// Merge name maps (later maps win on conflict).
Map<int, String> mergePerkNameMaps(Iterable<Map<int, String>> maps) {
  final out = <int, String>{};
  for (final m in maps) {
    out.addAll(m);
  }
  return out;
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

/// Optional async builder: plug hashes → enhanced flags (category + name).
typedef PlugEnhancedMapBuilder = Future<Map<int, bool>> Function(
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
