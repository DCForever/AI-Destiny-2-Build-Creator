import 'entity_cache_reader.dart';
import 'types/records.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// In-memory [EntityCacheReader] for prebuilt bundles and tests (DART-044).
///
/// No `dart:io`, no raw-table rebuild.
class MemoryEntityCache implements EntityCacheReader {
  MemoryEntityCache({
    required String version,
    EntityCacheMeta? meta,
    Map<MvpStoreName, List<Object>> stores = const {},
  })  : _version = version,
        _meta = meta ??
            EntityCacheMeta(
              manifestVersion: version,
              builtAt: DateTime.now().toUtc().toIso8601String(),
              counts: {
                for (final e in stores.entries) e.key.fileStem: e.value.length,
              },
            ),
        _stores = {
          for (final e in stores.entries)
            e.key: List<Object>.unmodifiable(e.value),
        };

  final String _version;
  final EntityCacheMeta _meta;
  final Map<MvpStoreName, List<Object>> _stores;

  @override
  String? get version => _version;

  @override
  Future<EntityCacheMeta?> getMeta() async => _meta;

  @override
  Future<List<T>> getStore<T>(MvpStoreName name) async {
    final list = _stores[name];
    if (list == null) {
      throw EntityCacheException(
        'store "${name.fileStem}" not present in memory cache',
      );
    }
    return list.cast<T>();
  }

  /// Decode store JSON arrays into a [MemoryEntityCache].
  factory MemoryEntityCache.fromStoreJson({
    required String version,
    required Map<String, List<dynamic>> storeJson,
    EntityCacheMeta? meta,
    String? builtAt,
  }) {
    final stores = <MvpStoreName, List<Object>>{};
    final counts = <String, int>{};
    for (final entry in storeJson.entries) {
      final store = MvpStoreName.tryParse(entry.key);
      if (store == null) continue;
      final records = decodeMvpStoreRecords(store, entry.value);
      stores[store] = records;
      counts[store.fileStem] = records.length;
    }
    return MemoryEntityCache(
      version: version,
      meta: meta ??
          EntityCacheMeta(
            manifestVersion: version,
            builtAt: builtAt ?? DateTime.now().toUtc().toIso8601String(),
            counts: counts,
          ),
      stores: stores,
    );
  }
}

/// Typed decode shared by file and memory caches.
List<Object> decodeMvpStoreRecords(MvpStoreName store, List<dynamic> list) {
  switch (store) {
    case MvpStoreName.weapons:
      return list
          .map(
            (e) => WeaponRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    case MvpStoreName.exoticWeapons:
      return list
          .map(
            (e) => ExoticWeaponRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    case MvpStoreName.exoticArmor:
      return list
          .map(
            (e) => ExoticArmorRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    case MvpStoreName.legendaryArmor:
      return list
          .map(
            (e) => LegendaryArmorRecord.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    case MvpStoreName.aspects:
      return list
          .map(
            (e) => AspectRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    case MvpStoreName.fragments:
      return list
          .map(
            (e) => FragmentRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    case MvpStoreName.abilities:
      return list
          .map(
            (e) => AbilityRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    case MvpStoreName.mods:
      return list
          .map((e) => ModRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  }
}
