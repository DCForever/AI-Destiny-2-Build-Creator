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
/// - Checks file length against [maxBytes] **before** reading bytes.
/// - Reads [sourcePath] with [FileMode.read] only (never writes/moves/deletes
///   the source).
/// - On success, atomically replaces
///   `{StorageRoot.basePath}/fill_in/dim_armor_inventory.csv` via a `.tmp`
///   sibling + rename.
/// - Never touches Mario paths (`warlock-matrix.json`, `personalize-queue.csv`,
///   `dim-icons.json`) or Daniel's per-build SQLite/preferences store.
class DimArmorCsvImporter {
  DimArmorCsvImporter({
    required StorageRoot root,
    this.maxBytes = kDimArmorCsvMaxBytes,
    this.beforeCacheRename,
  }) : _root = root;

  final StorageRoot _root;
  final int maxBytes;

  /// Test hook: invoked after the `.tmp` is flushed, before rename.
  /// Throw to simulate a mid-write failure without truncating the old cache.
  final Future<void> Function()? beforeCacheRename;

  /// Exact cache file path kept until the next successful import.
  String get cachePath => _root.dimArmorInventoryCachePath;

  /// Staging path used for atomic replace.
  String get cacheTempPath => '$cachePath.tmp';

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
      bytes = await readOnlyFileBytes(trimmed, maxBytes: maxBytes);
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

    try {
      await _writeCacheAtomic(bytes);
    } catch (e) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't write cache: $e",
      );
    }
    return DimArmorCsvImportResult.ok(parsed.items!);
  }

  /// Load the last successful import from the app-private cache, if present.
  ///
  /// Always returns a [DimArmorCsvImportResult] — never throws to callers.
  Future<DimArmorCsvImportResult> loadCache({
    Map<int, int> armorSetHashByItemHash = const <int, int>{},
  }) async {
    try {
      final file = File(cachePath);
      if (!await file.exists()) {
        return DimArmorCsvImportResult.couldNotRead(
          "Couldn't read file: no cached inventory yet",
        );
      }
      final bytes = await readOnlyFileBytes(cachePath, maxBytes: maxBytes);
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
    } on ReadOnlyFileException catch (e) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: ${e.message}",
      );
    } on ArgumentError catch (e) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: ${e.message}",
      );
    } catch (e) {
      return DimArmorCsvImportResult.couldNotRead(
        "Couldn't read file: $e",
      );
    }
  }

  Future<void> _writeCacheAtomic(Uint8List bytes) async {
    await Directory(_root.fillInCacheDir).create(recursive: true);
    final tmp = File(cacheTempPath);
    final handle = await tmp.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    try {
      final hook = beforeCacheRename;
      if (hook != null) {
        await hook();
      }
      await tmp.rename(cachePath);
    } catch (_) {
      if (await tmp.exists()) {
        await tmp.delete();
      }
      rethrow;
    }
  }
}

bool _isMarioPath(String path) {
  final name = p.basename(path).toLowerCase();
  return name == 'warlock-matrix.json' ||
      name == 'personalize-queue.csv' ||
      name == 'dim-icons.json';
}
