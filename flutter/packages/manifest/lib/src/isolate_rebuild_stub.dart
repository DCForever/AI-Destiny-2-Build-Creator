import 'types/stores.dart';

Future<EntityCacheMeta> rebuildEntityCacheInIsolate({
  required String basePath,
  required String version,
  String? builtAtIso,
}) {
  return Future.error(
    UnsupportedError(
      'Entity cache isolate rebuild requires dart:io (desktop). '
      'Web hosts load prebuilt entity bundles (DART-044).',
    ),
  );
}

Future<EntityCacheMeta> rebuildEntityCacheLocal({
  required String basePath,
  required String version,
  String? builtAtIso,
}) {
  return rebuildEntityCacheInIsolate(
    basePath: basePath,
    version: version,
    builtAtIso: builtAtIso,
  );
}
