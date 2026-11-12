import 'dart:io';
import 'dart:typed_data';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:path/path.dart' as p;

import 'read_only_file.dart';
import 'storage_root.dart';

/// Outcome of importing a user-picked DIM Armor CSV into the app cache.
class DimArmorCsvImportResult {
  DimArmorCsvImportResult._({this.items, this.error});

  factory DimArmorCsvImportResult.ok(List<FillInInventoryItem> items) {
    return DimArmorCsvImportResult._(
      items: List<FillInInventoryItem>.unmodifiable(items),
    );
  }

  factory DimArmorCsvImportResult.couldNotRead(String message) {
    return DimArmorCsvImportResult._(error: message);
  }

  final List<FillInInventoryItem>? items;
  final String? error;

  bool get isOk => items != null && error == null;
}

/// Read-only import of a DIM Armor CSV into an app-private cache.
///
/// - Reads [sourcePath] with [FileMode.read] only (never writes/moves/deletes
///   the source).
/// - On success, replaces `{StorageRoot.basePath}/fill_in/dim_armor_inventory.csv`.
/// - Never touches Mario paths (`warlock-matrix.json`, `personalize-queue.csv`,
///   `dim-icons.json`) or Daniel's per-build SQLite/preferences store.
class DimArmorCsvImporter {
  DimArmorCsvImporter({
    required StorageRoot root,
    this.maxBytes = kDimArmorCsvMaxBytes,
  }) : _root = root;

  final StorageRoot _root;
  final int maxBytes;

  /// Exact cache file path kept until the next successful import.
  String get cachePath => _root.dimArmorInventoryCachePath;

  /// Import [sourcePath], parse, and refresh the app-private cache.
  Future<DimArmorCsvImportResult> importFromPath(
    String sourcePath, {
    Map<int, int> armorSetHashByItemHash = const <int, int>{},
  }) async {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: path is required",
      );
    }
    if (_isMarioPath(trimmed)) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: Mario data files are not Fill In inventory",
      );
    }

    final Uint8List bytes;
    try {
      bytes = await readOnlyFileBytes(trimmed);
    } on ReadOnlyFileException catch (e) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: ${e.message}",
      );
    } on ArgumentError catch (e) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: ${e.message}",
      );
    }

    final parsed = parseDimArmorCsvBytes(
      bytes,
      armorSetHashByItemHash: armorSetHashByItemHash,
      maxBytes: maxBytes,
    );
    if (!parsed.isOk) {
      return DimArmorCsvImportResult.couldNotRead(
        parsed.error ?? "Couldn't read file",
      );
    }

    await _writeCache(bytes);
    return DimArmorCsvImportResult.ok(parsed.items!);
  }

  /// Load the last successful import from the app-private cache, if present.
  Future<DimArmorCsvImportResult> loadCache({
    Map<int, int> armorSetHashByItemHash = const <int, int>{},
  }) async {
    final file = File(cachePath);
    if (!await file.exists()) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: no cached inventory yet",
      );
    }
    final bytes = await readOnlyFileBytes(cachePath);
    final parsed = parseDimArmorCsvBytes(
      bytes,
      armorSetHashByItemHash: armorSetHashByItemHash,
      maxBytes: maxBytes,
    );
    if (!parsed.isOk) {
      return DimArmorCsvImportResult.couldNotRead(
        parsed.error ?? "Couldn't read file",
      );
    }
    return DimArmorCsvImportResult.ok(parsed.items!);
  }

  Future<void> _writeCache(Uint8List bytes) async {
    await Directory(_root.fillInCacheDir).create(recursive: true);
    final cache = File(cachePath);
    await cache.writeAsBytes(bytes, flush: true);
  }
}

bool _isMarioPath(String path) {
  final name = p.basename(path).toLowerCase();
  return name == 'warlock-matrix.json' ||
      name == 'personalize-queue.csv' ||
      name == 'dim-icons.json';
}
