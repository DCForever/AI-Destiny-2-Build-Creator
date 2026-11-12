import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';

import '../read_only_file.dart';
import '../storage_root.dart';

/// Read-only load of `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
///
/// Missing file → [DimLoadoutsReadStatus.notLoaded].
/// Corrupt / truncated / wrong schema / oversized →
/// [DimLoadoutsReadStatus.unreadable] with an empty catalog (fail closed).
/// Never writes, never fetches.
class DimLoadoutsReader {
  DimLoadoutsReader({
    required StorageRoot root,
    this.maxBytes = kCachedDimLoadoutsMaxBytes,
  }) : _root = root;

  final StorageRoot _root;
  final int maxBytes;

  String get path => _root.dimLoadoutsCachePath;

  /// Load the compiled catalog. Does not create directories or the file.
  Future<DimLoadoutsReadResult> load() async {
    final file = File(path);
    if (!await file.exists()) {
      return const DimLoadoutsReadResult.notLoaded();
    }
    try {
      final bytes = await readOnlyFileBytes(path, maxBytes: maxBytes);
      final text = utf8.decode(bytes);
      final parsed = parseCachedDimLoadouts(text, maxBytes: maxBytes);
      if (!parsed.isOk || parsed.catalog == null) {
        return DimLoadoutsReadResult.unreadable(
          parsed.detail ?? 'unreadable',
        );
      }
      return DimLoadoutsReadResult.loaded(parsed.catalog!);
    } on ReadOnlyFileException catch (e) {
      return DimLoadoutsReadResult.unreadable(e.message);
    } on FormatException catch (e) {
      return DimLoadoutsReadResult.unreadable(e.message);
    }
  }
}

enum DimLoadoutsReadStatus { notLoaded, unreadable, loaded }

/// Outcome of [DimLoadoutsReader.load].
class DimLoadoutsReadResult {
  const DimLoadoutsReadResult._({
    required this.status,
    this.catalog,
    this.detail,
  });

  const DimLoadoutsReadResult.notLoaded()
      : this._(status: DimLoadoutsReadStatus.notLoaded);

  const DimLoadoutsReadResult.unreadable(String detail)
      : this._(status: DimLoadoutsReadStatus.unreadable, detail: detail);

  const DimLoadoutsReadResult.loaded(CachedDimLoadoutCatalog catalog)
      : this._(status: DimLoadoutsReadStatus.loaded, catalog: catalog);

  final DimLoadoutsReadStatus status;
  final CachedDimLoadoutCatalog? catalog;
  final String? detail;

  /// Always empty unless [status] is [DimLoadoutsReadStatus.loaded].
  List<CachedDimLoadout> get loadouts =>
      catalog?.loadouts ?? const <CachedDimLoadout>[];
}
