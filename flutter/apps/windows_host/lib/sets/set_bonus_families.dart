import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../host_bootstrap.dart';

/// Load armor set-bonus family display names for Sets create / goals (G-SET-013).
///
/// Prefers entity store `set-bonuses` after manifest rebuild; falls back to a
/// raw `DestinyEquipableItemSetDefinition` read so the picker works before a
/// full re-extract when tables are already on disk.
Future<List<String>> loadArmorSetBonusFamilyNames(AppServices services) async {
  final refresh = services.manifestRefresh;
  if (refresh is! WindowsManifestRefresh) {
    return const [];
  }

  final version = await refresh.service.readCurrentVersion();
  if (version == null || version.isEmpty) {
    return const [];
  }

  // 1) Entity cache store (after Settings refresh that rebuilds extractors).
  try {
    final cache = FileEntityCache(
      storageRoot: services.storageRoot,
      version: version,
    );
    final rows =
        await cache.getStore<SetBonusCatalogRecord>(MvpStoreName.setBonuses);
    final names = <String>{
      for (final r in rows)
        if (r.name.trim().isNotEmpty) r.name.trim(),
    };
    if (names.isNotEmpty) {
      return names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
  } catch (_) {
    // Store missing or stale — try raw table.
  }

  // 2) Raw table (no rebuild required if manifest tables already downloaded).
  try {
    final table = await refresh.service.loadRawTable(
      version,
      'DestinyEquipableItemSetDefinition',
    );
    return setBonusFamilyNamesFromRawTable(table);
  } catch (_) {
    return const [];
  }
}
