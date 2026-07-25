import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Production roll-tag enrichment builders for Windows inventory sync (DART-051).
///
/// - **Perk names:** raw `DestinyInventoryItemDefinition.displayProperties.name`
///   for equipped plug hashes (MVP has no `weapon-perks` entity store).
/// - **Weapon meta:** OfflineCatalog legendary rows with `frame` + `itemTypeName`
///   for frame-based champion tags (Next legendary `WeaponRecord` path).
class WindowsRollTagEnrichment {
  const WindowsRollTagEnrichment({
    required this.perkNameMapBuilder,
    required this.weaponRollMetaLookupBuilder,
  });

  final PerkNameMapBuilder perkNameMapBuilder;
  final WeaponRollMetaLookupBuilder weaponRollMetaLookupBuilder;
}

WindowsRollTagEnrichment createWindowsRollTagEnrichment({
  required OfflineCatalog offlineCatalog,
  BungieManifestService? manifestService,
}) {
  Future<Map<int, String>> perkBuilder(List<int> plugHashes) async {
    if (plugHashes.isEmpty) return const {};
    final service = manifestService;
    if (service == null) return const {};
    final version = await service.readCurrentVersion();
    if (version == null || version.isEmpty) return const {};
    try {
      final table = await service.loadRawTable(
        version,
        'DestinyInventoryItemDefinition',
      );
      return buildPerkNameMapFromItemDefs(table, plugHashes);
    } catch (_) {
      return const {};
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
    perkNameMapBuilder: perkBuilder,
    weaponRollMetaLookupBuilder: weaponBuilder,
  );
}

/// Catalog-only weapon meta (web / hosts without raw plug defs).
///
/// Frame champion tags work; perk-name rules need raw defs or injected maps.
WindowsRollTagEnrichment createCatalogRollTagEnrichment({
  required OfflineCatalog offlineCatalog,
}) {
  return createWindowsRollTagEnrichment(
    offlineCatalog: offlineCatalog,
    manifestService: null,
  );
}
