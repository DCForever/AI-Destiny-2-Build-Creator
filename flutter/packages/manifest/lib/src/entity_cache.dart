import 'dart:convert';

import 'package:destiny2_storage/destiny2_storage.dart';

import 'entity_cache_reader.dart';
import 'extractors/registry.dart';
import 'io/text_file.dart' as text_file;
import 'memory_entity_cache.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// File-backed entity cache under [StorageRoot] (read + MVP rebuild).
///
/// Port of product `FileEntityCache` for MVP stores only (DART-017).
/// Uses conditional text-file helpers so the package can compile on web
/// (web catalog uses [MemoryEntityCache] / prebuilt bundles — DART-044).
class FileEntityCache implements EntityCacheReader {
  FileEntityCache({
    required this.storageRoot,
    String? version,
  }) : _version = version;

  final StorageRoot storageRoot;
  String? _version;
  final Map<MvpStoreName, List<Object>> _storeCache = {};

  @override
  String? get version => _version;

  @override
  Future<EntityCacheMeta?> getMeta() async {
    final v = _version;
    if (v == null) return null;
    final text = await text_file.readTextFile(storageRoot.entityCacheMetaPath(v));
    if (text == null) return null;
    return EntityCacheMeta.fromJson(
      Map<String, dynamic>.from(jsonDecode(text) as Map),
    );
  }

  @override
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
    final text = await text_file.readTextFile(filePath);
    if (text == null) {
      throw EntityCacheException(
        'store "${name.fileStem}" not found at $filePath — run rebuild() first',
      );
    }

    final list = jsonDecode(text) as List<dynamic>;
    final records = decodeMvpStoreRecords(name, list);
    _storeCache[name] = records;
    return records.cast<T>();
  }

  /// Run MVP extractors and write store JSON + meta under [StorageRoot].
  ///
  /// Desktop / native only — throws on web (no file write).
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
      final encoded = encodeStoreRecords(extractor.store, data);
      await text_file.writeTextFile(filePath, jsonEncode(encoded));
      counts[extractor.store.fileStem] = data.length;
      _storeCache[extractor.store] = data;
    }

    final meta = EntityCacheMeta(
      manifestVersion: version,
      builtAt: builtAtIso,
      counts: counts,
    );
    final metaPath = storageRoot.entityCacheMetaPath(version);
    await text_file.writeTextFile(metaPath, jsonEncode(meta.toJson()));

    _version = version;
    return meta;
  }
}
