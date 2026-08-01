import 'package:destiny2_bungie/destiny2_bungie.dart';

/// Weapon socket context for Jaspr inventory sync (DART-052 / GAP-INV-03).
///
/// Web prebuilt entity bundles do not ship raw DestinyInventoryItemDefinition.
/// Production path:
/// - Use [plugCategoryByHash] / [plugItemTypeByHash] / [weaponPerkIndexesByItem]
///   when the host injects entity/raw channel data (tests or future bundle).
/// - Otherwise return empty context → sync stores raw capture maps without
///   columnKind (documented residual until defs exist).
///
/// Soft metadata only — never auto-applies.
class WebWeaponSocketEnrichment {
  const WebWeaponSocketEnrichment({
    required this.weaponSocketContextBuilder,
  });

  final WeaponSocketContextBuilder weaponSocketContextBuilder;
}

/// Build web socket enrichment from optional entity/raw-shaped maps.
WebWeaponSocketEnrichment createWebWeaponSocketEnrichment({
  Map<int, String> plugCategoryByHash = const {},
  Map<int, String> plugItemTypeByHash = const {},
  Map<int, List<int>> weaponPerkIndexesByItem = const {},
  WeaponSocketContextBuilder? weaponSocketContextBuilder,
  Map<dynamic, dynamic>? inventoryItemDefinitionTable,
}) {
  Future<WeaponSocketContext> builder(
    int itemHash,
    List<int> plugHashes,
  ) async {
    if (weaponSocketContextBuilder != null) {
      return weaponSocketContextBuilder(itemHash, plugHashes);
    }

    if (inventoryItemDefinitionTable != null &&
        inventoryItemDefinitionTable.isNotEmpty) {
      return buildWeaponSocketContextFromItemDefs(
        inventoryItemDefinitionTable,
        itemHash,
        plugHashes,
      );
    }

    if (plugCategoryByHash.isEmpty &&
        plugItemTypeByHash.isEmpty &&
        weaponPerkIndexesByItem.isEmpty) {
      return const WeaponSocketContext(plugCategoryByHash: {});
    }

    final cats = <int, String>{};
    final types = <int, String>{};
    for (final h in plugHashes) {
      final c = plugCategoryByHash[h];
      if (c != null && c.isNotEmpty) cats[h] = c;
      final t = plugItemTypeByHash[h];
      if (t != null && t.isNotEmpty) types[h] = t;
    }
    final indexes = weaponPerkIndexesByItem[itemHash] ?? const <int>[];
    return WeaponSocketContext(
      plugCategoryByHash: cats,
      plugItemTypeByHash: types,
      weaponPerkSocketIndexes: indexes,
    );
  }

  return WebWeaponSocketEnrichment(
    weaponSocketContextBuilder: builder,
  );
}
