import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Resolve armor_stats plug investments from raw item defs (BR-SET-011).
///
/// Returns a pure [resolvePlug] when [manifestService] can load
/// DestinyInventoryItemDefinition; null when raw tables are unavailable
/// (fall back to stripped/live ItemStats).
typedef ArmorPlugStatResolver = PlugStatSource? Function(int hash);

class WindowsArmorBaseRollEnrichment {
  const WindowsArmorBaseRollEnrichment({
    this.resolvePlug,
  });

  final ArmorPlugStatResolver? resolvePlug;
}

/// Build a batch-cached plug resolver for set enrichment.
///
/// Loads raw table once, then resolves any plug hash from it.
Future<WindowsArmorBaseRollEnrichment> createWindowsArmorBaseRollEnrichment({
  BungieManifestService? manifestService,
}) async {
  final service = manifestService;
  if (service == null) {
    return const WindowsArmorBaseRollEnrichment();
  }
  try {
    final version = await service.readCurrentVersion();
    if (version == null || version.isEmpty) {
      return const WindowsArmorBaseRollEnrichment();
    }
    final table = await service.loadRawTable(
      version,
      'DestinyInventoryItemDefinition',
    );
    return WindowsArmorBaseRollEnrichment(
      resolvePlug: (hash) => resolvePlugStatFromItemDefs(table, hash),
    );
  } catch (_) {
    return const WindowsArmorBaseRollEnrichment();
  }
}
