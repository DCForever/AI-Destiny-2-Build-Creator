import 'isolate_rebuild_impl.dart' as impl;
import 'types/stores.dart';

/// Rebuild MVP entity stores **off the UI isolate** (desktop).
///
/// On web this throws — use prebuilt entity bundles (DART-044).
Future<EntityCacheMeta> rebuildEntityCacheInIsolate({
  required String basePath,
  required String version,
  String? builtAtIso,
}) {
  return impl.rebuildEntityCacheInIsolate(
    basePath: basePath,
    version: version,
    builtAtIso: builtAtIso,
  );
}

/// Same rebuild on the current isolate (tests / tooling).
Future<EntityCacheMeta> rebuildEntityCacheLocal({
  required String basePath,
  required String version,
  String? builtAtIso,
}) {
  return impl.rebuildEntityCacheLocal(
    basePath: basePath,
    version: version,
    builtAtIso: builtAtIso,
  );
}
