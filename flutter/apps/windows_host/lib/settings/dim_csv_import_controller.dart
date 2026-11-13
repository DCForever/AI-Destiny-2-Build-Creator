import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/foundation.dart';

/// Which DIM CSV inventory this controller imports into StorageRoot.
enum DimCsvImportKind {
  armor,
  weapons,
}

/// UI phase for Settings DIM CSV import.
enum DimCsvImportPhase {
  /// Initial load of cache in progress.
  loading,

  /// Idle with optional status from cache or last import.
  idle,

  /// Import in progress.
  importing,

  /// Last operation failed (path/parse/write).
  error,
}

/// Orchestrates path-typed DIM Armor / Weapons CSV import into StorageRoot.
///
/// Source file is read-only; only the app-private fill_in cache is written.
/// Soft guidance never auto-applies. No Bungie / OAuth / network.
class DimCsvImportController extends ChangeNotifier {
  factory DimCsvImportController.armor({
    required StorageRoot storageRoot,
    DimArmorCsvImporter? importer,
  }) {
    final i = importer ?? DimArmorCsvImporter(root: storageRoot);
    return DimCsvImportController._(
      kind: DimCsvImportKind.armor,
      cachePath: i.cachePath,
      importFromPath: (path) async =>
          _outcomeFromArmor(await i.importFromPath(path)),
      loadCache: () async => _outcomeFromArmor(await i.loadCache()),
    );
  }

  factory DimCsvImportController.weapons({
    required StorageRoot storageRoot,
    DimWeaponsCsvImporter? importer,
  }) {
    final i = importer ?? DimWeaponsCsvImporter(root: storageRoot);
    return DimCsvImportController._(
      kind: DimCsvImportKind.weapons,
      cachePath: i.cachePath,
      importFromPath: (path) async =>
          _outcomeFromWeapons(await i.importFromPath(path)),
      loadCache: () async => _outcomeFromWeapons(await i.loadCache()),
    );
  }

  /// Injectable adapters for widget tests (no dart:io).
  ///
  /// Return `count` on success, or `error` on failure.
  factory DimCsvImportController.forTest({
    required DimCsvImportKind kind,
    required String cachePath,
    required Future<({int? count, String? error})> Function(String path)
        importFromPath,
    required Future<({int? count, String? error})> Function() loadCache,
  }) {
    return DimCsvImportController._(
      kind: kind,
      cachePath: cachePath,
      importFromPath: (path) async {
        final r = await importFromPath(path);
        if (r.count != null && r.error == null) {
          return _DimCsvOutcome.ok(r.count!);
        }
        return _DimCsvOutcome.fail(r.error ?? "Couldn't read file");
      },
      loadCache: () async {
        final r = await loadCache();
        if (r.count != null && r.error == null) {
          return _DimCsvOutcome.ok(r.count!);
        }
        return _DimCsvOutcome.fail(r.error ?? "Couldn't read file");
      },
    );
  }

  DimCsvImportController._({
    required this.kind,
    required String cachePath,
    required Future<_DimCsvOutcome> Function(String path) importFromPath,
    required Future<_DimCsvOutcome> Function() loadCache,
  })  : _cachePath = cachePath,
        _importFromPath = importFromPath,
        _loadCache = loadCache;

  final DimCsvImportKind kind;
  final String _cachePath;
  final Future<_DimCsvOutcome> Function(String path) _importFromPath;
  final Future<_DimCsvOutcome> Function() _loadCache;

  DimCsvImportPhase _phase = DimCsvImportPhase.idle;
  String _sourcePath = '';
  int? _cachedCount;
  String? _errorMessage;
  String? _statusMessage;
  var _disposed = false;
  Future<void>? _cacheLoadFuture;

  DimCsvImportPhase get phase => _phase;
  String get sourcePath => _sourcePath;
  String get cachePath => _cachePath;
  int? get cachedCount => _cachedCount;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  bool get isBusy =>
      _phase == DimCsvImportPhase.loading ||
      _phase == DimCsvImportPhase.importing;

  /// Human-readable status for the card (cached count, not imported, or last
  /// import outcome). Prefer [errorMessage] when [phase] is error.
  String get displayStatus {
    if (_phase == DimCsvImportPhase.error &&
        _errorMessage != null &&
        _errorMessage!.isNotEmpty) {
      return _errorMessage!;
    }
    if (_statusMessage != null && _statusMessage!.isNotEmpty) {
      return _statusMessage!;
    }
    if (_cachedCount != null) {
      return 'Cached: $_cachedCount items';
    }
    return 'not imported yet';
  }

  void setSourcePath(String path) {
    if (_disposed || path == _sourcePath) return;
    _sourcePath = path;
    notifyListeners();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_disposed) return;
    _phase = DimCsvImportPhase.loading;
    _errorMessage = null;
    _safeNotify();
    try {
      final outcome = await _loadCache();
      if (_disposed) return;
      if (outcome.isOk) {
        _cachedCount = outcome.count;
        _statusMessage = 'Cached: ${outcome.count} items';
        _phase = DimCsvImportPhase.idle;
      } else {
        _cachedCount = null;
        _statusMessage = 'not imported yet';
        _phase = DimCsvImportPhase.idle;
      }
    } catch (_) {
      if (_disposed) return;
      _cachedCount = null;
      _statusMessage = 'not imported yet';
      _phase = DimCsvImportPhase.idle;
    }
    _safeNotify();
  }

  /// Load cached inventory once when the Settings card mounts.
  ///
  /// Safe to call multiple times — returns the in-flight future unless
  /// [force] is true.
  Future<void> loadCachedStatus({bool force = false}) {
    if (_disposed) return Future<void>.value();
    if (_cacheLoadFuture != null && !force) return _cacheLoadFuture!;
    _cacheLoadFuture = _bootstrap();
    return _cacheLoadFuture!;
  }

  /// Re-run cache load (e.g. after external change). Prefer [importFromPath]
  /// for user-driven imports.
  Future<void> reloadCache() => loadCachedStatus(force: true);

  Future<void> importFromPath() async {
    if (_disposed) return;
    final source = _sourcePath.trim();
    if (source.isEmpty) {
      _phase = DimCsvImportPhase.error;
      _errorMessage = "Couldn't read file: path is required";
      _safeNotify();
      return;
    }

    _phase = DimCsvImportPhase.importing;
    _errorMessage = null;
    _safeNotify();

    try {
      final outcome = await _importFromPath(source);
      if (_disposed) return;
      if (outcome.isOk) {
        _cachedCount = outcome.count;
        _statusMessage = 'Imported ${outcome.count} items';
        _errorMessage = null;
        _phase = DimCsvImportPhase.idle;
      } else {
        _phase = DimCsvImportPhase.error;
        _errorMessage = outcome.error ?? "Couldn't read file";
      }
    } catch (e) {
      if (_disposed) return;
      _phase = DimCsvImportPhase.error;
      _errorMessage = e.toString();
    }
    _safeNotify();
  }
}

class _DimCsvOutcome {
  const _DimCsvOutcome._({this.count, this.error});

  factory _DimCsvOutcome.ok(int count) => _DimCsvOutcome._(count: count);

  factory _DimCsvOutcome.fail(String message) =>
      _DimCsvOutcome._(error: message);

  final int? count;
  final String? error;

  bool get isOk => count != null && error == null;
}

_DimCsvOutcome _outcomeFromArmor(DimArmorCsvImportResult result) {
  if (result.isOk) return _DimCsvOutcome.ok(result.items!.length);
  return _DimCsvOutcome.fail(result.error ?? "Couldn't read file");
}

_DimCsvOutcome _outcomeFromWeapons(DimWeaponsCsvImportResult result) {
  if (result.isOk) return _DimCsvOutcome.ok(result.items!.length);
  return _DimCsvOutcome.fail(result.error ?? "Couldn't read file");
}
