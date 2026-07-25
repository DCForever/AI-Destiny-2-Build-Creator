import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Catalog-only roll-tag enrichment for Jaspr equip sync (DART-051).
///
/// Web prebuilt bundles lack full raw DestinyInventoryItemDefinition, so perk
/// **name** map is empty unless a host injects one. Frame champion tags still
/// apply from OfflineCatalog weapon rows with frame + itemTypeName.
class WebRollTagEnrichment {
  const WebRollTagEnrichment({
    required this.perkNameMapBuilder,
    required this.weaponRollMetaLookupBuilder,
  });

  final PerkNameMapBuilder perkNameMapBuilder;
  final WeaponRollMetaLookupBuilder weaponRollMetaLookupBuilder;
}

WebRollTagEnrichment createWebRollTagEnrichment({
  required OfflineCatalog offlineCatalog,
}) {
  Future<Map<int, String>> perkBuilder(List<int> plugHashes) async {
    // No raw weapon-perks / item defs on web MVP — perk-name rules need residual
    // channel (entity weapon-perks or injected map). Frame tags still work.
    return const {};
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

  return WebRollTagEnrichment(
    perkNameMapBuilder: perkBuilder,
    weaponRollMetaLookupBuilder: weaponBuilder,
  );
}
