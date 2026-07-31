import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Catalog/entity roll-tag enrichment for Jaspr inventory sync (DART-051 / GAP-INV-02).
///
/// - **Perk names:** seed from OfflineCatalog / entity hash→name rows so plug
///   hashes that exist in the prebuilt bundle resolve (mods, projected items).
///   Optional [extraPerkNames] / [perkNameMapBuilder] fill residual gaps
///   (true weapon-perks without entity rows still need injection or raw defs).
/// - **Weapon meta:** OfflineCatalog frame + itemTypeName for frame champion tags.
///
/// Soft metadata only — never auto-applies.
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
  Map<int, String> extraPerkNames = const {},
  PerkNameMapBuilder? perkNameMapBuilder,
  Iterable<({int hash, String name})>? extraNamedHashes,
}) {
  Future<Map<int, String>> perkBuilder(List<int> plugHashes) async {
    if (plugHashes.isEmpty) return const {};
    if (offlineCatalog.baseItems.isEmpty) {
      await offlineCatalog.loadBase();
    }
    final fromCatalog = buildPerkNameMapFromNamedHashes(
      [
        for (final item in offlineCatalog.baseItems)
          (hash: item.hash, name: item.name),
        ...?extraNamedHashes,
      ],
      onlyHashes: plugHashes,
    );
    final merged = mergePerkNameMaps([
      fromCatalog,
      {
        for (final h in plugHashes)
          if (extraPerkNames[h] != null && extraPerkNames[h]!.isNotEmpty)
            h: extraPerkNames[h]!,
      },
    ]);
    if (perkNameMapBuilder != null) {
      final more = await perkNameMapBuilder(plugHashes);
      return mergePerkNameMaps([merged, more]);
    }
    return merged;
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
