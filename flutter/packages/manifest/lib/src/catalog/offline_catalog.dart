import 'dart:convert';

import 'package:destiny2_storage/destiny2_storage.dart';

import '../entity_cache.dart';
import '../entity_cache_reader.dart';
import '../io/text_file.dart' as text_file;
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
  OfflineCatalogLoadResult({
    required this.version,
    required this.items,
    this.error,
    this.emptyReason = CatalogEmptyReason.none,
    Map<String, int>? storeCounts,
  }) : storeCounts = storeCounts ?? const <String, int>{};

  final String? version;
  final List<CatalogItem> items;
  final String? error;
  final CatalogEmptyReason emptyReason;

  /// Per-store row counts after load (`exotic-weapons` → 0 when missing).
  /// Always non-null (empty map when unknown / preloaded / load error).
  final Map<String, int> storeCounts;

  bool get ok => error == null;
  bool get isEmpty => items.isEmpty;

  /// MVP stores expected by [mvpExtractors] / [MvpStoreName] that loaded empty
  /// or were missing from disk (common cause of “no exotics in weapons”).
  List<String> get missingOrEmptyStores {
    final counts = storeCounts;
    final out = <String>[];
    for (final s in MvpStoreName.values) {
      final n = counts[s.fileStem] ?? 0;
      if (n <= 0) out.add(s.fileStem);
    }
    return out;
  }

  /// True when legendary weapons loaded but exotic weapons did not.
  bool get missingExoticWeapons {
    final counts = storeCounts;
    final legendary = counts[MvpStoreName.weapons.fileStem] ?? 0;
    final exotic = counts[MvpStoreName.exoticWeapons.fileStem] ?? 0;
    return legendary > 0 && exotic <= 0;
  }
}

/// Offline catalog: project MVP entity stores and filter facets offline.
///
/// Does **not** open SQLite. Reads entity JSON via [EntityCacheReader]
/// (file-backed or prebuilt memory bundle). Ownership annotate lives on the
/// host bridge (DART-026) over inventory.
class OfflineCatalog {
  OfflineCatalog({
    this.storageRoot,
    this.version,
    EntityCacheReader? cache,
  })  : _injectedCache = cache,
        _preloaded = null {
    if (storageRoot == null && cache == null) {
      throw ArgumentError(
        'OfflineCatalog requires storageRoot and/or cache '
        '(or use OfflineCatalog.preloaded)',
      );
    }
  }

  /// In-memory base list (widget tests / fakes / web prebuilt) —
  /// [loadBase] returns it as-is. No [StorageRoot] required (DART-044).
  ///
  /// Optional [perkColumnsByHash] seeds definition can-roll / unowned pools
  /// (host-fixture residual-polish Capture + smoke; never invent plugs).
  OfflineCatalog.preloaded({
    required List<CatalogItem> items,
    this.version,
    this.storageRoot,
    Map<int, List<WeaponPerkColumn>> perkColumnsByHash = const {},
  })  : _injectedCache = null,
        _preloaded = OfflineCatalogLoadResult(
          version: version,
          items: List<CatalogItem>.unmodifiable(items),
          emptyReason: items.isEmpty
              ? (version == null
                  ? CatalogEmptyReason.noVersion
                  : CatalogEmptyReason.noStores)
              : CatalogEmptyReason.none,
          storeCounts: const {},
        ) {
    _base = _preloaded!.items;
    _loadedVersion = version;
    _lastLoad = _preloaded;
    if (perkColumnsByHash.isNotEmpty) {
      _perkColumnsByHash = Map<int, List<WeaponPerkColumn>>.unmodifiable(
        {
          for (final e in perkColumnsByHash.entries)
            e.key: List<WeaponPerkColumn>.unmodifiable(e.value),
        },
      );
    }
  }

  /// Optional disk root for [FileEntityCache] / current-version.json.
  final StorageRoot? storageRoot;

  /// Optional fixed version (tests / bundles). When null, reads
  /// `current-version.json` under [storageRoot] when present.
  final String? version;

  final EntityCacheReader? _injectedCache;
  final OfflineCatalogLoadResult? _preloaded;

  List<CatalogItem> _base = const [];
  String? _loadedVersion;
  OfflineCatalogLoadResult? _lastLoad;

  /// Weapon definition perk pools (itemHash → columns) from entity stores.
  /// Used for catalog detail can-roll / unowned definition fallback.
  Map<int, List<WeaponPerkColumn>> _perkColumnsByHash = const {};

  List<CatalogItem> get baseItems => _base;
  String? get loadedVersion => _loadedVersion;
  OfflineCatalogLoadResult? get lastLoad => _lastLoad;

  /// Definition [WeaponPerkColumn]s for [itemHash], or empty when unknown.
  List<WeaponPerkColumn> perkColumnsFor(int itemHash) =>
      _perkColumnsByHash[itemHash] ?? const [];

  /// Load (or reload) base catalog from entity stores.
  Future<OfflineCatalogLoadResult> loadBase() async {
    final pre = _preloaded;
    if (pre != null) {
      _base = pre.items;
      _loadedVersion = pre.version;
      _lastLoad = pre;
      // Preloaded items lack raw WeaponRecord; keep any prior map or empty.
      return pre;
    }

    try {
      final ver = version ??
          _injectedCache?.version ??
          await _readCurrentVersion();
      if (ver == null || ver.isEmpty) {
        _base = const [];
        _loadedVersion = null;
        _perkColumnsByHash = const {};
        _lastLoad = OfflineCatalogLoadResult(
          version: null,
          items: const [],
          emptyReason: CatalogEmptyReason.noVersion,
          storeCounts: const {},
        );
        return _lastLoad!;
      }

      final cache = _injectedCache ??
          FileEntityCache(storageRoot: storageRoot!, version: ver);

      final weapons = await _tryStore<WeaponRecord>(cache, MvpStoreName.weapons);
      final exoticWeapons = await _tryStore<ExoticWeaponRecord>(
        cache,
        MvpStoreName.exoticWeapons,
      );
      final exoticArmor =
          await _tryStore<ExoticArmorRecord>(cache, MvpStoreName.exoticArmor);
      final legendaryArmor = await _tryStore<LegendaryArmorRecord>(
        cache,
        MvpStoreName.legendaryArmor,
      );
      final aspects =
          await _tryStore<AspectRecord>(cache, MvpStoreName.aspects);
      final fragments =
          await _tryStore<FragmentRecord>(cache, MvpStoreName.fragments);
      final abilities =
          await _tryStore<AbilityRecord>(cache, MvpStoreName.abilities);
      final mods = await _tryStore<ModRecord>(cache, MvpStoreName.mods);

      final storeCounts = <String, int>{
        MvpStoreName.weapons.fileStem: weapons.length,
        MvpStoreName.exoticWeapons.fileStem: exoticWeapons.length,
        MvpStoreName.exoticArmor.fileStem: exoticArmor.length,
        MvpStoreName.legendaryArmor.fileStem: legendaryArmor.length,
        MvpStoreName.aspects.fileStem: aspects.length,
        MvpStoreName.fragments.fileStem: fragments.length,
        MvpStoreName.abilities.fileStem: abilities.length,
        MvpStoreName.mods.fileStem: mods.length,
      };

      final anyLoaded = storeCounts.values.any((n) => n > 0);

      final items = projectMvpStores(
        weapons: weapons,
        exoticWeapons: exoticWeapons,
        exoticArmor: exoticArmor,
        legendaryArmor: legendaryArmor,
        aspects: aspects,
        fragments: fragments,
        abilities: abilities,
        mods: mods,
      );

      // Prefer exotic row when both stores list the same hash.
      final perkMap = <int, List<WeaponPerkColumn>>{};
      for (final w in weapons) {
        if (w.perkColumns.isNotEmpty) {
          perkMap[w.hash] = List<WeaponPerkColumn>.unmodifiable(w.perkColumns);
        }
      }
      for (final w in exoticWeapons) {
        if (w.perkColumns.isNotEmpty) {
          perkMap[w.hash] = List<WeaponPerkColumn>.unmodifiable(w.perkColumns);
        }
      }
      _perkColumnsByHash = Map<int, List<WeaponPerkColumn>>.unmodifiable(perkMap);

      _base = items;
      _loadedVersion = ver;
      _lastLoad = OfflineCatalogLoadResult(
        version: ver,
        items: items,
        emptyReason: anyLoaded || items.isNotEmpty
            ? CatalogEmptyReason.none
            : CatalogEmptyReason.noStores,
        storeCounts: storeCounts,
      );
      return _lastLoad!;
    } catch (e) {
      _base = const [];
      _loadedVersion = null;
      _perkColumnsByHash = const {};
      _lastLoad = OfflineCatalogLoadResult(
        version: null,
        items: const [],
        error: e.toString(),
        storeCounts: const {},
      );
      return _lastLoad!;
    }
  }

  /// Filter the last loaded base list (call [loadBase] first).
  List<CatalogItem> browse([
    CatalogClientFilters filters = const CatalogClientFilters(),
  ]) {
    return filterCatalogClient(_base, filters);
  }

  Future<String?> _readCurrentVersion() async {
    final root = storageRoot;
    if (root == null) return null;
    final text = await text_file.readTextFile(root.currentVersionPath);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is Map && json['version'] is String) {
        return json['version'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<List<T>> _tryStore<T>(
    EntityCacheReader cache,
    MvpStoreName store,
  ) async {
    try {
      return await cache.getStore<T>(store);
    } on EntityCacheException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
