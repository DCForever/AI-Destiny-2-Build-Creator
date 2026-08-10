import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

import '../host_bootstrap.dart';

/// Load armor set-bonus families (name + 2pc/4pc perk text) for Sets goals UI.
///
/// Prefers entity store `set-bonuses`; falls back to raw
/// `DestinyEquipableItemSetDefinition` + sandbox perks so descriptions work
/// even before a full entity rebuild.
Future<List<SetsBonusFamilyOption>> loadArmorSetBonusFamilies(
  AppServices services,
) async {
  final refresh = services.manifestRefresh;
  if (refresh is! WindowsManifestRefresh) {
    return const [];
  }

  final version = await refresh.service.readCurrentVersion();
  if (version == null || version.isEmpty) {
    return const [];
  }

  // 1) Entity cache store.
  try {
    final cache = FileEntityCache(
      storageRoot: services.storageRoot,
      version: version,
    );
    final rows =
        await cache.getStore<SetBonusCatalogRecord>(MvpStoreName.setBonuses);
    final mapped = _mapCatalog(rows);
    if (mapped.isNotEmpty) return mapped;
  } catch (_) {
    // Store missing or stale — try raw tables.
  }

  // 2) Raw tables (names + perk descriptions from sandbox perks).
  try {
    final setTable = await refresh.service.loadRawTable(
      version,
      'DestinyEquipableItemSetDefinition',
    );
    final sandbox = await refresh.service.loadRawTable(
      version,
      'DestinySandboxPerkDefinition',
    );
    return _mapCatalog(setBonusCatalogFromRawTables(setTable, sandbox));
  } catch (_) {
    return const [];
  }
}

/// @nodoc — kept for call sites that only need names.
Future<List<String>> loadArmorSetBonusFamilyNames(AppServices services) async {
  final families = await loadArmorSetBonusFamilies(services);
  return [for (final f in families) f.name];
}

List<SetsBonusFamilyOption> _mapCatalog(List<SetBonusCatalogRecord> rows) {
  final out = <SetsBonusFamilyOption>[];
  for (final r in rows) {
    if (r.name.trim().isEmpty) continue;
    String twoName = '';
    String twoDesc = '';
    String fourName = '';
    String fourDesc = '';
    final extra = StringBuffer();
    for (final p in r.perks) {
      // Index every tier for search (name + description).
      if (p.name.trim().isNotEmpty) extra.writeln(p.name.trim());
      if (p.description.trim().isNotEmpty) extra.writeln(p.description.trim());

      if (p.requiredCount == 2) {
        twoName = p.name;
        twoDesc = p.description;
      } else if (p.requiredCount == 4) {
        fourName = p.name;
        fourDesc = p.description;
      } else if (p.requiredCount <= 2 && twoName.isEmpty && twoDesc.isEmpty) {
        twoName = p.name;
        twoDesc = p.description;
      } else if (p.requiredCount >= 3 &&
          p.requiredCount <= 4 &&
          fourName.isEmpty &&
          fourDesc.isEmpty) {
        fourName = p.name;
        fourDesc = p.description;
      } else if (p.requiredCount > 4 && fourName.isEmpty) {
        fourName = p.name;
        fourDesc = p.description;
      }
    }
    out.add(
      SetsBonusFamilyOption(
        name: r.name.trim(),
        hash: r.hash,
        iconPath: r.icon,
        twoPcName: twoName,
        twoPcDescription: twoDesc,
        fourPcName: fourName,
        fourPcDescription: fourDesc,
        extraSearchText: extra.toString(),
      ),
    );
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}
