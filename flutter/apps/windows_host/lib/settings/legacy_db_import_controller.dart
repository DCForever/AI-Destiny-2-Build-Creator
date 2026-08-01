import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/foundation.dart';

/// UI phase for Settings legacy DB import (DART-048).
enum LegacyDbImportPhase {
  idle,
  dryRunning,
  dryRunReady,
  applying,
  applied,
  error,
}

/// Orchestrates dry-run + apply for Next `.cache/app.db` → StorageRoot.
///
/// Soft guidance never auto-applies. No CLIENT_SECRET. After successful apply,
/// the host process should restart so the single DB connection rebinds.
class LegacyDbImportController extends ChangeNotifier {
  LegacyDbImportController({
    required StorageRoot storageRoot,
    LegacyDbImporter? importer,
  })  : _storageRoot = storageRoot,
        _importer = importer ?? const LegacyDbImporter();

  final StorageRoot _storageRoot;
  final LegacyDbImporter _importer;

  LegacyDbImportPhase _phase = LegacyDbImportPhase.idle;
  String _sourcePath = '';
  LegacyDbImportPlan? _plan;
  LegacyDbImportResult? _result;
  String? _errorMessage;
  bool _confirmReplace = false;

  LegacyDbImportPhase get phase => _phase;
  String get sourcePath => _sourcePath;
  LegacyDbImportPlan? get plan => _plan;
  LegacyDbImportResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get confirmReplace => _confirmReplace;

  String get targetPath => _storageRoot.appDbPath;

  bool get isBusy =>
      _phase == LegacyDbImportPhase.dryRunning ||
      _phase == LegacyDbImportPhase.applying;

  /// Apply enabled only after a successful dry-run for the **current** source.
  /// When the target already exists, [confirmReplace] must also be true.
  bool get canApply {
    if (isBusy) return false;
    final p = _plan;
    if (p == null || !p.canApply) return false;
    if (p.sourcePath != _sourcePath.trim()) return false;
    if (p.targetExists && !_confirmReplace) return false;
    return true;
  }

  /// Dry-run succeeded for the current source (confirm may still be required).
  bool get hasSuccessfulDryRun {
    final p = _plan;
    if (p == null || !p.canApply) return false;
    return p.sourcePath == _sourcePath.trim();
  }

  void setSourcePath(String path) {
    if (path == _sourcePath) return;
    _sourcePath = path;
    // Invalidate prior plan when path changes.
    if (_plan != null && _plan!.sourcePath != path.trim()) {
      _plan = null;
      _result = null;
      if (_phase == LegacyDbImportPhase.dryRunReady ||
          _phase == LegacyDbImportPhase.applied) {
        _phase = LegacyDbImportPhase.idle;
      }
    }
    notifyListeners();
  }

  void setConfirmReplace(bool value) {
    if (value == _confirmReplace) return;
    _confirmReplace = value;
    notifyListeners();
  }

  Future<void> dryRun() async {
    final source = _sourcePath.trim();
    if (source.isEmpty) {
      _phase = LegacyDbImportPhase.error;
      _errorMessage = 'Enter the path to Next .cache/app.db';
      _plan = null;
      notifyListeners();
      return;
    }

    _phase = LegacyDbImportPhase.dryRunning;
    _errorMessage = null;
    _result = null;
    _confirmReplace = false;
    notifyListeners();

    try {
      final plan = await _importer.dryRun(
        sourcePath: source,
        targetPath: targetPath,
      );
      _plan = plan;
      if (plan.canApply) {
        _phase = LegacyDbImportPhase.dryRunReady;
      } else {
        _phase = LegacyDbImportPhase.error;
        _errorMessage = plan.errors.isEmpty
            ? 'Dry-run failed'
            : plan.errors.join('; ');
      }
    } catch (e) {
      _phase = LegacyDbImportPhase.error;
      _errorMessage = e.toString();
      _plan = null;
    }
    notifyListeners();
  }

  /// Requires [canApply] and [confirmReplace] when target already exists.
  Future<void> apply() async {
    if (!canApply) {
      _errorMessage = 'Run a successful dry-run first';
      _phase = LegacyDbImportPhase.error;
      notifyListeners();
      return;
    }
    final p = _plan!;
    if (p.targetExists && !_confirmReplace) {
      _errorMessage =
          'Confirm replace: existing platform app.db will be backed up and replaced';
      _phase = LegacyDbImportPhase.error;
      notifyListeners();
      return;
    }

    _phase = LegacyDbImportPhase.applying;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _importer.apply(
        sourcePath: p.sourcePath,
        targetPath: p.targetPath,
        priorPlan: p,
      );
      _result = result;
      _phase = LegacyDbImportPhase.applied;
    } on LegacyDbImportException catch (e) {
      _phase = LegacyDbImportPhase.error;
      _errorMessage = e.toString();
    } catch (e) {
      _phase = LegacyDbImportPhase.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
