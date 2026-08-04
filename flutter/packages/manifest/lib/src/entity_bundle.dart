import 'dart:convert';

import 'catalog/catalog_item.dart';
import 'catalog/catalog_projector.dart';
import 'catalog/offline_catalog.dart';
import 'memory_entity_cache.dart';
import 'types/records.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// Prebuilt MVP entity bundle (DART-044) — no raw Bungie table rebuild.
///
/// Single-document format for web static assets and tests:
/// ```json
/// {
///   "manifestVersion": "prebuilt-mvp-1",
///   "builtAt": "…",
///   "counts": { "weapons": 1, … },
///   "stores": { "weapons": [ … ], "exotic-armor": [ … ], … }
/// }
/// ```
class EntityBundleDocument {
  const EntityBundleDocument({
    required this.meta,
    required this.stores,
  });

  final EntityCacheMeta meta;
  final Map<MvpStoreName, List<Object>> stores;

  String get version => meta.manifestVersion;

  /// Parse a JSON map (already decoded).
  factory EntityBundleDocument.fromJson(Map<String, dynamic> json) {
    final version = json['manifestVersion'] as String? ??
        json['version'] as String? ??
        '';
    if (version.isEmpty) {
      throw EntityBundleException('manifestVersion is required');
    }

    final builtAt = json['builtAt'] as String? ??
        DateTime.now().toUtc().toIso8601String();

    final rawStores = json['stores'];
    if (rawStores is! Map) {
      throw EntityBundleException('stores map is required');
    }

    final stores = <MvpStoreName, List<Object>>{};
    final counts = <String, int>{};
    for (final entry in rawStores.entries) {
      final store = MvpStoreName.tryParse(entry.key.toString());
      if (store == null) continue;
      final value = entry.value;
      if (value is! List) {
        throw EntityBundleException(
          'store "${store.fileStem}" must be a JSON array',
        );
      }
      final records = decodeMvpStoreRecords(store, value);
      stores[store] = records;
      counts[store.fileStem] = records.length;
    }

    final metaCounts = <String, int>{};
    final rawCounts = json['counts'];
    if (rawCounts is Map) {
      for (final e in rawCounts.entries) {
        metaCounts[e.key.toString()] = (e.value as num).toInt();
      }
    } else {
      metaCounts.addAll(counts);
    }

    return EntityBundleDocument(
      meta: EntityCacheMeta(
        manifestVersion: version,
        builtAt: builtAt,
        counts: metaCounts,
      ),
      stores: stores,
    );
  }

  /// Parse a JSON string.
  factory EntityBundleDocument.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw EntityBundleException('bundle root must be a JSON object');
    }
    return EntityBundleDocument.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Map<String, dynamic> toJson() => {
        'manifestVersion': meta.manifestVersion,
        'builtAt': meta.builtAt,
        'counts': meta.counts,
        'stores': {
          for (final e in stores.entries)
            e.key.fileStem: encodeStoreRecords(e.key, e.value),
        },
      };

  /// In-memory cache over this document.
  MemoryEntityCache toMemoryCache() {
    return MemoryEntityCache(
      version: version,
      meta: meta,
      stores: stores,
    );
  }

  /// Project all present MVP stores into catalog rows (unowned).
  List<CatalogItem> toCatalogItems() {
    return projectMvpStores(
      weapons: stores[MvpStoreName.weapons]?.cast<WeaponRecord>() ?? const [],
      exoticWeapons:
          stores[MvpStoreName.exoticWeapons]?.cast<ExoticWeaponRecord>() ??
              const [],
      exoticArmor:
          stores[MvpStoreName.exoticArmor]?.cast<ExoticArmorRecord>() ??
              const [],
      legendaryArmor:
          stores[MvpStoreName.legendaryArmor]?.cast<LegendaryArmorRecord>() ??
              const [],
      aspects: stores[MvpStoreName.aspects]?.cast<AspectRecord>() ?? const [],
      fragments:
          stores[MvpStoreName.fragments]?.cast<FragmentRecord>() ?? const [],
      abilities:
          stores[MvpStoreName.abilities]?.cast<AbilityRecord>() ?? const [],
      mods: stores[MvpStoreName.mods]?.cast<ModRecord>() ?? const [],
    );
  }

  /// Load result suitable for offline catalog / UI.
  OfflineCatalogLoadResult toLoadResult() {
    final items = toCatalogItems();
    final storeCounts = <String, int>{
      for (final e in stores.entries) e.key.fileStem: e.value.length,
    };
    return OfflineCatalogLoadResult(
      version: version,
      items: items,
      emptyReason: items.isEmpty
          ? CatalogEmptyReason.noStores
          : CatalogEmptyReason.none,
      storeCounts: storeCounts,
    );
  }
}

class EntityBundleException implements Exception {
  EntityBundleException(this.message);
  final String message;

  @override
  String toString() => 'EntityBundleException: $message';
}

/// Build an [OfflineCatalog] preloaded from a prebuilt bundle (no StorageRoot).
OfflineCatalog offlineCatalogFromBundle(EntityBundleDocument bundle) {
  final result = bundle.toLoadResult();
  return OfflineCatalog.preloaded(
    items: result.items,
    version: bundle.version,
  );
}
