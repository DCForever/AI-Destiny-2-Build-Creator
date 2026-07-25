import 'dart:convert';
import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';

import 'extractors/registry.dart';
import 'types/records.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// File-backed entity cache under [StorageRoot] (read + MVP rebuild).
///
/// Port of product `FileEntityCache` for MVP stores only (DART-017).
class FileEntityCache {
  FileEntityCache({
    required this.storageRoot,
    String? version,
  }) : _version = version;

  final StorageRoot storageRoot;
  String? _version;
  final Map<MvpStoreName, List<Object>> _storeCache = {};

  String? get version => _version;

  Future<EntityCacheMeta?> getMeta() async {
    final v = _version;
    if (v == null) return null;
    final file = File(storageRoot.entityCacheMetaPath(v));
    if (!await file.exists()) return null;
    final text = await file.readAsString();
    return EntityCacheMeta.fromJson(
      Map<String, dynamic>.from(jsonDecode(text) as Map),
    );
  }

  Future<List<T>> getStore<T>(MvpStoreName name) async {
    final cached = _storeCache[name];
    if (cached != null) return cached.cast<T>();

    final v = _version;
    if (v == null) {
      throw EntityCacheException(
        'no version is set — call rebuild() first or pass a version',
      );
    }

    final filePath = storageRoot.entityStorePath(v, name.fileStem);
    final file = File(filePath);
    if (!await file.exists()) {
      throw EntityCacheException(
        'store "${name.fileStem}" not found at $filePath — run rebuild() first',
      );
    }

    final text = await file.readAsString();
    final list = jsonDecode(text) as List<dynamic>;
    final records = _decodeRecords(name, list);
    _storeCache[name] = records;
    return records.cast<T>();
  }

  /// Run MVP extractors and write store JSON + meta under [StorageRoot].
  Future<EntityCacheMeta> rebuild({
    required String version,
    required LoadRawTable loadRawTable,
    DateTime? builtAt,
  }) async {
    final tableCache = <String, RawTable>{};

    Future<RawTable> memoizedLoad(String table) async {
      final cached = tableCache[table];
      if (cached != null) return cached;
      final raw = await loadRawTable(table);
      tableCache[table] = raw;
      return raw;
    }

    final counts = <String, int>{};
    final builtAtIso = (builtAt ?? DateTime.now().toUtc()).toIso8601String();

    for (final extractor in mvpExtractors) {
      final data = await extractor.extract(memoizedLoad);
      final filePath =
          storageRoot.entityStorePath(version, extractor.store.fileStem);
      await File(filePath).parent.create(recursive: true);
      final encoded = encodeStoreRecords(extractor.store, data);
      await File(filePath).writeAsString(jsonEncode(encoded));
      counts[extractor.store.fileStem] = data.length;
      _storeCache[extractor.store] = data;
    }

    final meta = EntityCacheMeta(
      manifestVersion: version,
      builtAt: builtAtIso,
      counts: counts,
    );
    final metaPath = storageRoot.entityCacheMetaPath(version);
    await File(metaPath).parent.create(recursive: true);
    await File(metaPath).writeAsString(jsonEncode(meta.toJson()));

    _version = version;
    return meta;
  }

  List<Object> _decodeRecords(MvpStoreName store, List<dynamic> list) {
    switch (store) {
      case MvpStoreName.weapons:
        return list
            .map(
              (e) => WeaponRecord.fromJson(Map<String, dynamic>.from(e as Map)),
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
      case MvpStoreName.aspects:
        return list
            .map(
              (e) => AspectRecord.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      case MvpStoreName.fragments:
        return list
            .map(
              (e) =>
                  FragmentRecord.fromJson(Map<String, dynamic>.from(e as Map)),
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
}
