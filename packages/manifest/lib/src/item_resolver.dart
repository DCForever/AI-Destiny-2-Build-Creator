import 'entity_cache.dart';
import 'normalize.dart';
import 'types/records.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// Name/hash resolution over entity stores (exact match first, contains fallback).
class StoreItemResolver {
  StoreItemResolver(this.cache);

  final FileEntityCache cache;
  final Map<MvpStoreName, _LoadedStore> _loaded = {};

  Future<ResolveResult<T>?> resolve<T extends EntityRecordBase>(
    MvpStoreName store,
    String name,
  ) async {
    final normalized = normalizeName(name);
    if (normalized.isEmpty) return null;

    final loaded = await _load(store);
    final exact = loaded.bySearchName[normalized];
    if (exact != null) {
      return ResolveResult(record: exact as T, confidence: 1);
    }

    // Simple contains ranking (Fuse parity deferred).
    ResolveResult<T>? best;
    for (final rec in loaded.records) {
      final sn = rec.searchName;
      if (!sn.contains(normalized) && !normalized.contains(sn)) continue;
      final conf = sn == normalized
          ? 1.0
          : (sn.startsWith(normalized) ? 0.85 : 0.6);
      if (best == null || conf > best.confidence) {
        best = ResolveResult(record: rec as T, confidence: conf);
      }
    }
    return best;
  }

  Future<T?> getByHash<T extends EntityRecordBase>(
    MvpStoreName store,
    Hash hash,
  ) async {
    final loaded = await _load(store);
    return loaded.byHash[hash] as T?;
  }

  Future<_LoadedStore> _load(MvpStoreName store) async {
    final cached = _loaded[store];
    if (cached != null) return cached;

    final records = await cache.getStore<EntityRecordBase>(store);
    final byHash = <int, EntityRecordBase>{};
    final bySearchName = <String, EntityRecordBase>{};
    for (final r in records) {
      byHash[r.hash] = r;
      bySearchName[r.searchName] = r;
    }
    final loaded = _LoadedStore(
      records: records,
      byHash: byHash,
      bySearchName: bySearchName,
    );
    _loaded[store] = loaded;
    return loaded;
  }
}

class _LoadedStore {
  _LoadedStore({
    required this.records,
    required this.byHash,
    required this.bySearchName,
  });

  final List<EntityRecordBase> records;
  final Map<int, EntityRecordBase> byHash;
  final Map<String, EntityRecordBase> bySearchName;
}
