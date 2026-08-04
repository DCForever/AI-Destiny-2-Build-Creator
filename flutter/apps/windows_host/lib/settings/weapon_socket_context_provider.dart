import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Production weapon socket context for inventory socket enrichment (DART-052).
///
/// Loads plug categories / item types + weapon perk socket indexes from raw
/// `DestinyInventoryItemDefinition` when a [BungieManifestService] is available
/// (Windows after DART-018). Empty context when raw tables are missing —
/// sync falls back to raw capture maps without columnKind.
class WindowsWeaponSocketEnrichment {
  const WindowsWeaponSocketEnrichment({
    required this.weaponSocketContextBuilder,
  });

  final WeaponSocketContextBuilder weaponSocketContextBuilder;
}

WindowsWeaponSocketEnrichment createWindowsWeaponSocketEnrichment({
  BungieManifestService? manifestService,
}) {
  Future<WeaponSocketContext> builder(
    int itemHash,
    List<int> plugHashes,
  ) async {
    // Soft enrichment only — never throw into inventory sync.
    try {
      final service = manifestService;
      if (service == null) {
        return const WeaponSocketContext(plugCategoryByHash: {});
      }
      final version = await service.readCurrentVersion();
      if (version == null || version.isEmpty) {
        return const WeaponSocketContext(plugCategoryByHash: {});
      }
      final table = await service.loadRawTable(
        version,
        'DestinyInventoryItemDefinition',
      );
      return buildWeaponSocketContextFromItemDefs(
        table,
        itemHash,
        plugHashes,
      );
    } catch (_) {
      return const WeaponSocketContext(plugCategoryByHash: {});
    }
  }

  return WindowsWeaponSocketEnrichment(
    weaponSocketContextBuilder: builder,
  );
}
