// Next parity: `src/lib/inventory/instances/weaponSocketContext.ts` (DART-052).

/// Destiny socket category hash for weapon perk columns (barrel/mag/traits).
///
/// Product: `WEAPON_PERKS_CATEGORY_HASH = 4241085061`.
const int kWeaponPerksCategoryHash = 4241085061;

/// Manifest-derived inputs for [buildStoredSocketPlugs] / classify.
class WeaponSocketContext {
  const WeaponSocketContext({
    required this.plugCategoryByHash,
    this.plugItemTypeByHash = const {},
    this.weaponPerkSocketIndexes = const [],
  });

  final Map<int, String> plugCategoryByHash;
  final Map<int, String> plugItemTypeByHash;
  final List<int> weaponPerkSocketIndexes;

  /// Merge plug category/type maps from [other] (other wins on conflict).
  WeaponSocketContext mergePlugMaps(WeaponSocketContext other) {
    return WeaponSocketContext(
      plugCategoryByHash: {
        ...plugCategoryByHash,
        ...other.plugCategoryByHash,
      },
      plugItemTypeByHash: {
        ...plugItemTypeByHash,
        ...other.plugItemTypeByHash,
      },
      weaponPerkSocketIndexes: weaponPerkSocketIndexes.isNotEmpty
          ? weaponPerkSocketIndexes
          : other.weaponPerkSocketIndexes,
    );
  }
}

/// Optional async builder: weapon itemHash + plug hashes → socket context.
///
/// Hosts load raw DestinyInventoryItemDefinition (or equivalent). Return empty
/// maps when defs are unavailable — sync falls back to raw capture without
/// columnKind (incomplete enrichment).
typedef WeaponSocketContextBuilder = Future<WeaponSocketContext> Function(
  int itemHash,
  List<int> plugHashes,
);

/// Build [WeaponSocketContext] from DestinyInventoryItemDefinition-shaped data.
///
/// - Weapon perk indexes: `sockets.socketCategories` entry with
///   [kWeaponPerksCategoryHash].
/// - Plug maps: `plug.plugCategoryIdentifier` + `itemTypeDisplayName` for each
///   requested plug hash.
WeaponSocketContext buildWeaponSocketContextFromItemDefs(
  Map<dynamic, dynamic> inventoryItemDefinitionTable,
  int itemHash,
  Iterable<int> plugHashes,
) {
  final itemRaw = _tableEntry(inventoryItemDefinitionTable, itemHash);
  final weaponPerkSocketIndexes = itemRaw is Map
      ? getPerkSocketIndexesFromItemDef(
          Map<dynamic, dynamic>.from(itemRaw),
          kWeaponPerksCategoryHash,
        )
      : const <int>[];

  final plugCategoryByHash = <int, String>{};
  final plugItemTypeByHash = <int, String>{};
  for (final hash in plugHashes.toSet()) {
    final plugRaw = _tableEntry(inventoryItemDefinitionTable, hash);
    if (plugRaw is! Map) continue;
    final plug = Map<dynamic, dynamic>.from(plugRaw);
    final plugBlock = plug['plug'];
    if (plugBlock is Map) {
      final cat = plugBlock['plugCategoryIdentifier'];
      if (cat is String && cat.isNotEmpty) {
        plugCategoryByHash[hash] = cat;
      }
    }
    final typeName = plug['itemTypeDisplayName'];
    if (typeName is String) {
      final trimmed = typeName.trim();
      if (trimmed.isNotEmpty) {
        plugItemTypeByHash[hash] = trimmed;
      }
    }
  }

  return WeaponSocketContext(
    plugCategoryByHash: plugCategoryByHash,
    plugItemTypeByHash: plugItemTypeByHash,
    weaponPerkSocketIndexes: weaponPerkSocketIndexes,
  );
}

/// Socket indexes for a named socket category on a raw item definition map.
///
/// Next parity: `getPerkSocketIndexes`.
List<int> getPerkSocketIndexesFromItemDef(
  Map<dynamic, dynamic> item,
  int categoryHash,
) {
  final sockets = item['sockets'];
  if (sockets is! Map) return const [];
  final categories = sockets['socketCategories'];
  if (categories is! List) return const [];
  for (final cat in categories) {
    if (cat is! Map) continue;
    final hash = cat['socketCategoryHash'];
    final h = hash is int
        ? hash
        : hash is num
            ? hash.toInt()
            : null;
    if (h != categoryHash) continue;
    final indexes = cat['socketIndexes'];
    if (indexes is! List) return const [];
    final out = <int>[];
    for (final i in indexes) {
      if (i is int) {
        out.add(i);
      } else if (i is num) {
        out.add(i.toInt());
      }
    }
    return out;
  }
  return const [];
}

Object? _tableEntry(Map<dynamic, dynamic> table, int hash) {
  if (table.containsKey(hash)) return table[hash];
  final asString = '$hash';
  if (table.containsKey(asString)) return table[asString];
  return null;
}
