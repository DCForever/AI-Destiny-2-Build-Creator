import 'dart:convert';
import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';

import '../entity_cache.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'catalog_item.dart';
import 'catalog_projector.dart';
import 'filter_catalog.dart';

/// Why base catalog is empty when load succeeds with no rows.
enum CatalogEmptyReason {
  none,
  noVersion,
  noStores,
}

/// Result of loading offline entity stores into catalog rows.
class OfflineCatalogLoadResult {
  const OfflineCatalogLoadResult({
    required this.version,
    required this.items,
    this.error,
    this.emptyReason = CatalogEmptyReason.none,
  });

  final String? version;
  final List<CatalogItem> items;
  final String? error;
  final CatalogEmptyReason emptyReason;

  bool get ok => error == null;
  bool get isEmpty => items.isEmpty;
}

/// Offline catalog: project MVP entity stores and filter facets offline.
///
/// Does **not** open SQLite. Reads entity JSON under [StorageRoot] only.
/// Ownership annotate lives on the host bridge (DART-026) over inventory.
class OfflineCatalog {
  OfflineCatalog({
    required this.storageRoot,
    this.version,
    FileEntityCache? cache,
  })  : _injectedCache = cache,
        _preloaded = null;

  /// In-memory base list (widget tests / fakes) — [loadBase] returns it as-is.
  OfflineCatalog.preloaded({
    required this.storageRoot,
    required List<CatalogItem> items,
    this.version,
  })  : _injectedCache = null,
        _preloaded = OfflineCatalogLoadResult(
          version: version,
          items: List<CatalogItem>.unmodifiable(items),
          emptyReason: items.isEmpty
              ? (version == null
                  ? CatalogEmptyReason.noVersion
                  : CatalogEmptyReason.noStores)
              : CatalogEmptyReason.none,
        ) {
    _base = _preloaded!.items;
    _loadedVersion = version;
    _lastLoad = _preloaded;
  }

  final StorageRoot storageRoot;

  /// Optional fixed version (tests). When null, reads `current-version.json`.
  final String? version;

  final FileEntityCache? _injectedCache;
  final OfflineCatalogLoadResult? _preloaded;

  List<CatalogItem> _base = const [];
  String? _loadedVersion;
  OfflineCatalogLoadResult? _lastLoad;

  List<CatalogItem> get baseItems => _base;
  String? get loadedVersion => _loadedVersion;
  OfflineCatalogLoadResult? get lastLoad => _lastLoad;

  /// Load (or reload) base catalog from entity stores.
  Future<OfflineCatalogLoadResult> loadBase() async {
    final pre = _preloaded;
    if (pre != null) {
      _base = pre.items;
      _loadedVersion = pre.version;
      _lastLoad = pre;
      return pre;
    }

    try {
      final ver = version ?? await _readCurrentVersion();
      if (ver == null || ver.isEmpty) {
        _base = const [];
        _loadedVersion = null;
        _lastLoad = const OfflineCatalogLoadResult(
          version: null,
          items: [],
          emptyReason: CatalogEmptyReason.noVersion,
        );
        return _lastLoad!;
      }

      final cache = _injectedCache ??
          FileEntityCache(storageRoot: storageRoot, version: ver);

      final weapons = await _tryStore<WeaponRecord>(cache, MvpStoreName.weapons);
      final exoticArmor =
          await _tryStore<ExoticArmorRecord>(cache, MvpStoreName.exoticArmor);
      final aspects =
          await _tryStore<AspectRecord>(cache, MvpStoreName.aspects);
      final fragments =
          await _tryStore<FragmentRecord>(cache, MvpStoreName.fragments);
      final abilities =
          await _tryStore<AbilityRecord>(cache, MvpStoreName.abilities);
      final mods = await _tryStore<ModRecord>(cache, MvpStoreName.mods);

      final anyLoaded = weapons.isNotEmpty ||
          exoticArmor.isNotEmpty ||
          aspects.isNotEmpty ||
          fragments.isNotEmpty ||
          abilities.isNotEmpty ||
          mods.isNotEmpty;

      // If every store threw/missing and none loaded, treat as no_stores when
      // meta is also absent — still return partials when some stores exist.
      final items = projectMvpStores(
        weapons: weapons,
        exoticArmor: exoticArmor,
        aspects: aspects,
        fragments: fragments,
        abilities: abilities,
        mods: mods,
      );

      _base = items;
      _loadedVersion = ver;
      _lastLoad = OfflineCatalogLoadResult(
        version: ver,
        items: items,
        emptyReason: anyLoaded || items.isNotEmpty
            ? CatalogEmptyReason.none
            : CatalogEmptyReason.noStores,
      );
      return _lastLoad!;
    } catch (e) {
      _base = const [];
      _loadedVersion = null;
      _lastLoad = OfflineCatalogLoadResult(
        version: null,
        items: const [],
        error: e.toString(),
      );
      return _lastLoad!;
    }
  }

  /// Filter the last loaded base list (call [loadBase] first).
  List<CatalogItem> browse([CatalogClientFilters filters = const CatalogClientFilters()]) {
    return filterCatalogClient(_base, filters);
  }

  Future<String?> _readCurrentVersion() async {
    final file = File(storageRoot.currentVersionPath);
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is Map && json['version'] is String) {
        return json['version'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<List<T>> _tryStore<T>(FileEntityCache cache, MvpStoreName store) async {
    try {
      return await cache.getStore<T>(store);
    } on EntityCacheException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
