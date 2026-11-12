import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:destiny2_domain/destiny2_domain.dart';

import '../read_only_file.dart';
import '../storage_root.dart';

/// Read-only byte loader used by [DimLoadoutsReader] (injectable in tests).
typedef DimLoadoutsBytesReader = Future<Uint8List> Function(
  String path, {
  int? maxBytes,
});

/// Read-only load of `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
///
/// Missing file → [DimLoadoutsReadStatus.notLoaded].
/// Corrupt / truncated / wrong schema / oversized / IO errors →
/// [DimLoadoutsReadStatus.unreadable] with an empty catalog (fail closed).
/// Never writes, never fetches.
class DimLoadoutsReader {
  DimLoadoutsReader({
    required StorageRoot root,
    this.maxBytes = kCachedDimLoadoutsMaxBytes,
    DimLoadoutsBytesReader? readBytes,
  })  : _root = root,
        _readBytes = readBytes ?? readOnlyFileBytes;

  final StorageRoot _root;
  final int maxBytes;
  final DimLoadoutsBytesReader _readBytes;

  String get path => _root.dimLoadoutsCachePath;

  /// Load the compiled catalog. Does not create directories or the file.
  Future<DimLoadoutsReadResult> load() async {
    try {
      final type = await FileSystemEntity.type(path, followLinks: true);
      if (type == FileSystemEntityType.notFound) {
        return const DimLoadoutsReadResult.notLoaded();
      }
      if (type != FileSystemEntityType.file) {
        return const DimLoadoutsReadResult.unreadable(
          'path is not a regular file',
        );
      }
      final bytes = await _readBytes(path, maxBytes: maxBytes);
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
    } on FileSystemException catch (e) {
      return DimLoadoutsReadResult.unreadable(
        e.message.isEmpty ? 'file system error' : e.message,
      );
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
