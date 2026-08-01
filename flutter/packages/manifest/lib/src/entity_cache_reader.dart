import 'types/stores.dart';

/// Read-only access to MVP entity stores (DART-017 / DART-044).
///
/// Implemented by [FileEntityCache] (desktop) and [MemoryEntityCache] (prebuilt
/// bundles / tests). Web catalog uses memory only — no raw rebuild.
abstract class EntityCacheReader {
  String? get version;

  Future<EntityCacheMeta?> getMeta();

  Future<List<T>> getStore<T>(MvpStoreName name);
}
