import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Production roll-tag enrichment builders for Windows inventory sync (DART-051).
///
/// - **Perk names:** raw `DestinyInventoryItemDefinition.displayProperties.name`
/// - **Perk icons:** raw `displayProperties.icon` (Bungie CDN path)
/// - **Weapon meta:** OfflineCatalog legendary rows with `frame` + `itemTypeName`
class WindowsRollTagEnrichment {
  const WindowsRollTagEnrichment({
    required this.perkNameMapBuilder,
    required this.perkIconMapBuilder,
    required this.weaponRollMetaLookupBuilder,
  });

  final PerkNameMapBuilder perkNameMapBuilder;
  final PerkNameMapBuilder perkIconMapBuilder;
  final WeaponRollMetaLookupBuilder weaponRollMetaLookupBuilder;
}

WindowsRollTagEnrichment createWindowsRollTagEnrichment({
  required OfflineCatalog offlineCatalog,
  BungieManifestService? manifestService,
}) {
  /// One table load serves both name + icon builders (memoized per call batch).
  Map<dynamic, dynamic>? cachedTable;
  String? cachedVersion;

  Future<Map<dynamic, dynamic>?> loadItemDefs() async {
    final service = manifestService;
    if (service == null) return null;
    try {
      final version = await service.readCurrentVersion();
      if (version == null || version.isEmpty) return null;
      if (cachedTable != null && cachedVersion == version) return cachedTable;
      final table = await service.loadRawTable(
        version,
        'DestinyInventoryItemDefinition',
      );
      cachedTable = table;
      cachedVersion = version;
      return table;
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, String>> perkNameBuilder(List<int> plugHashes) async {
    // Always a real Map — never null (Catalog / sync crash on null Future result).
    final empty = <int, String>{};
    if (plugHashes.isEmpty) return empty;
    try {
      final table = await loadItemDefs();
      if (table == null) return empty;
      // build* returns a fresh map; avoid Map.from (extra copy of large results).
      return buildPerkNameMapFromItemDefs(table, plugHashes);
    } catch (_) {
      return empty;
    }
  }

  Future<Map<int, String>> perkIconBuilder(List<int> plugHashes) async {
    final empty = <int, String>{};
    if (plugHashes.isEmpty) return empty;
    try {
      final table = await loadItemDefs();
      if (table == null) return empty;
      return buildPerkIconMapFromItemDefs(table, plugHashes);
    } catch (_) {
      return empty;
    }
  }

  Future<Map<int, RollTagWeaponMeta>> weaponBuilder(List<int> itemHashes) async {
    if (itemHashes.isEmpty) return const {};
    if (offlineCatalog.baseItems.isEmpty) {
      await offlineCatalog.loadBase();
    }
    final sources = <WeaponRollMetaSource>[
      for (final item in offlineCatalog.baseItems)
        if (item.frame != null &&
            item.frame!.isNotEmpty &&
            item.itemTypeName != null &&
            item.itemTypeName!.isNotEmpty)
          WeaponRollMetaSource(
            hash: item.hash,
            frame: item.frame!,
            itemTypeName: item.itemTypeName!,
            isExotic: item.isExotic,
          ),
    ];
    return buildWeaponRollMetaLookup(sources, onlyHashes: itemHashes);
  }

  return WindowsRollTagEnrichment(
    perkNameMapBuilder: perkNameBuilder,
    perkIconMapBuilder: perkIconBuilder,
    weaponRollMetaLookupBuilder: weaponBuilder,
  );
}

/// Catalog-only weapon meta (web / hosts without raw plug defs).
WindowsRollTagEnrichment createCatalogRollTagEnrichment({
  required OfflineCatalog offlineCatalog,
}) {
  return createWindowsRollTagEnrichment(
    offlineCatalog: offlineCatalog,
    manifestService: null,
  );
}
