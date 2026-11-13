import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import 'builds_mock_derived_name.dart';
import 'builds_mock_models.dart';

/// Resolved Bungie icon paths for Builds mock identity segments.
///
/// Paths come from DIM cache (`superIconPath`) or OfflineCatalog
/// (`displayProperties.icon` projected onto [CatalogItem.icon]) — same source
/// Catalog grids already use. Never invents paths.
class BuildsMockSegmentIcons {
  const BuildsMockSegmentIcons({
    this.superIconPath,
    this.exoticArmorIconPath,
    this.exoticWeaponIconPath,
  });

  final String? superIconPath;
  final String? exoticArmorIconPath;
  final String? exoticWeaponIconPath;
}

/// Resolve Super + exotic icon paths for one build.
///
/// Order for Super: cached `subclass.superIconPath` → catalog by plug hash →
/// catalog by Super name. Missing Super icon means omit the segment (caller).
BuildsMockSegmentIcons resolveBuildsMockSegmentIcons({
  required MockBuild build,
  CachedDimLoadout? loadout,
  Iterable<CatalogItem> catalogItems = const [],
}) {
  final byHash = <int, CatalogItem>{
    for (final i in catalogItems) i.hash: i,
  };
  return BuildsMockSegmentIcons(
    superIconPath: _resolveSuperIcon(
      loadout: loadout,
      byHash: byHash,
      catalogItems: catalogItems,
    ),
    exoticArmorIconPath: _resolveExoticIcon(
      name: build.exoticArmor,
      loadout: loadout,
      byHash: byHash,
      catalogItems: catalogItems,
      armor: true,
    ),
    exoticWeaponIconPath: _resolveExoticIcon(
      name: build.exoticWeapon,
      loadout: loadout,
      byHash: byHash,
      catalogItems: catalogItems,
      armor: false,
    ),
  );
}

String? _resolveSuperIcon({
  required CachedDimLoadout? loadout,
  required Map<int, CatalogItem> byHash,
  required Iterable<CatalogItem> catalogItems,
}) {
  final cached = dimLoadoutSuperIconPath(loadout);
  if (cached != null && cached.isNotEmpty) return cached;

  final hash = dimLoadoutSuperPlugHash(loadout);
  final fromHash = _iconFromHash(byHash, hash);
  if (fromHash != null) return fromHash;

  final superName = dimLoadoutSuperName(loadout);
  return _iconFromName(
    catalogItems,
    superName,
    preferStore: MvpStoreName.abilities.fileStem,
  );
}

String? _resolveExoticIcon({
  required String name,
  required CachedDimLoadout? loadout,
  required Map<int, CatalogItem> byHash,
  required Iterable<CatalogItem> catalogItems,
  required bool armor,
}) {
  final cleaned = name.trim();
  if (cleaned.isEmpty ||
      cleaned == '—' ||
      cleaned.toLowerCase() == 'none') {
    return null;
  }

  // Prefer DIM item hash when the item name matches.
  if (loadout != null) {
    for (final item in loadout.items) {
      if (item.name.trim().toLowerCase() != cleaned.toLowerCase()) continue;
      final icon = _iconFromHash(byHash, item.hash);
      if (icon != null) return icon;
    }
    final exotic = loadout.exotic;
    if (exotic != null &&
        exotic.name.trim().toLowerCase() == cleaned.toLowerCase()) {
      final icon = _iconFromHash(byHash, exotic.hash);
      if (icon != null) return icon;
    }
  }

  return resolveCatalogExoticIconPath(
    name: cleaned,
    catalogItems: catalogItems,
    armor: armor,
  );
}

/// OfflineCatalog exotic icon by display name (filter dropdowns + titles).
///
/// Prefers the exotic-armor / exotic-weapons store, then any exotic match.
/// Returns null when no catalog row has an icon — callers show no badge.
String? resolveCatalogExoticIconPath({
  required String name,
  required Iterable<CatalogItem> catalogItems,
  required bool armor,
}) {
  final cleaned = name.trim();
  if (cleaned.isEmpty ||
      cleaned == '—' ||
      cleaned.toLowerCase() == 'none') {
    return null;
  }
  final preferStore = armor
      ? MvpStoreName.exoticArmor.fileStem
      : MvpStoreName.exoticWeapons.fileStem;
  final preferred = _iconFromName(
    catalogItems,
    cleaned,
    preferStore: preferStore,
    exoticOnly: true,
  );
  if (preferred != null) return preferred;
  return _iconFromName(catalogItems, cleaned, exoticOnly: true);
}

/// Set-bonus family icon by display name (Builds Set filter).
///
/// [iconByLowerName] is typically built from [SetBonusCatalogRecord.icon].
String? resolveSetFilterIconPath({
  required String setName,
  required Map<String, String> iconByLowerName,
}) {
  final key = setName.trim().toLowerCase();
  if (key.isEmpty) return null;
  final path = iconByLowerName[key]?.trim();
  if (path == null || path.isEmpty) return null;
  return path;
}

/// Super plug hash: subclass.superName match among plugs, else socket index 2.
int? dimLoadoutSuperPlugHash(CachedDimLoadout? loadout) {
  if (loadout == null) return null;
  final superName = dimLoadoutSuperName(loadout)?.toLowerCase();
  final plugs = loadout.subclassPlugs;
  if (superName != null) {
    for (final p in plugs) {
      if (p.name.trim().toLowerCase() == superName && p.hash != 0) {
        return p.hash;
      }
    }
  }
  if (plugs.length >= 3 && plugs[2].hash != 0) return plugs[2].hash;
  return null;
}

String? _iconFromHash(Map<int, CatalogItem> byHash, int? hash) {
  if (hash == null || hash == 0) return null;
  final icon = byHash[hash]?.icon?.trim();
  if (icon == null || icon.isEmpty) return null;
  return icon;
}

String? _iconFromName(
  Iterable<CatalogItem> items,
  String? name, {
  String? preferStore,
  bool exoticOnly = false,
}) {
  final key = name?.trim().toLowerCase();
  if (key == null || key.isEmpty) return null;
  String? fallback;
  for (final item in items) {
    if (item.name.trim().toLowerCase() != key) continue;
    if (exoticOnly && !item.isExotic) continue;
    final icon = item.icon?.trim();
    if (icon == null || icon.isEmpty) continue;
    if (preferStore != null &&
        (item.sourceStore ?? '').toLowerCase() == preferStore.toLowerCase()) {
      return icon;
    }
    fallback ??= icon;
  }
  return fallback;
}
