import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:destiny2_storage/destiny2_storage.dart';

import 'entity_cache.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// Rebuild MVP entity stores **off the UI isolate**.
///
/// Passes only [basePath] + [version] across the isolate boundary; raw tables
/// are reloaded from disk inside the isolate (DART-018 exit criteria).
Future<EntityCacheMeta> rebuildEntityCacheInIsolate({
  required String basePath,
  required String version,
  String? builtAtIso,
}) {
  return Isolate.run(
    () => _rebuildInIsolate(
      basePath: basePath,
      version: version,
      builtAtIso: builtAtIso,
    ),
  );
}

/// Same rebuild on the current isolate (tests / tooling).
Future<EntityCacheMeta> rebuildEntityCacheLocal({
  required String basePath,
  required String version,
  String? builtAtIso,
}) {
  return _rebuildInIsolate(
    basePath: basePath,
    version: version,
    builtAtIso: builtAtIso,
  );
}

Future<EntityCacheMeta> _rebuildInIsolate({
  required String basePath,
  required String version,
  String? builtAtIso,
}) async {
  final storageRoot = StorageRoot(basePath: basePath);
  final cache = FileEntityCache(storageRoot: storageRoot);

  Future<RawTable> loadRawTable(String tableName) async {
    final path = storageRoot.rawTablePath(version, tableName);
    final file = File(path);
    if (!await file.exists()) {
      // Extractors request only mvp tables; missing optional tables → empty.
      return <String, dynamic>{};
    }
    final parsed = jsonDecode(await file.readAsString());
    if (parsed is! Map) {
      throw ManifestServiceException(
        'Raw table "$tableName" is not a valid JSON object at $path',
      );
    }
    return Map<String, dynamic>.from(parsed);
  }

  return cache.rebuild(
    version: version,
    loadRawTable: loadRawTable,
    builtAt: builtAtIso != null ? DateTime.tryParse(builtAtIso) : null,
  );
}
