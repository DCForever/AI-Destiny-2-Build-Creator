import 'dart:convert';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/foundation.dart';

/// UI phase for the Warlock matrix path Settings card.
enum WarlockMatrixPathPhase {
  loading,
  idle,
  saving,
  probing,
  error,
}

/// Orchestrates save of the matrix path preference + read-only status probe.
///
/// Writes only `{StorageRoot}/settings/warlock_matrix_path.txt`. The matrix
/// file itself is never written, moved, or deleted.
class WarlockMatrixPathController extends ChangeNotifier {
  WarlockMatrixPathController({
    required StorageRoot storageRoot,
    WarlockMatrixPathSettingStore? setting,
    Map<String, String>? environment,
    this.matrixMaxBytes = kCachedDimLoadoutsMaxBytes,
  })  : _setting = setting ?? WarlockMatrixPathSetting(root: storageRoot),
        _environment = environment;

  final WarlockMatrixPathSettingStore _setting;
  final Map<String, String>? _environment;
  final int matrixMaxBytes;

  WarlockMatrixPathPhase _phase = WarlockMatrixPathPhase.idle;
  String _pathField = '';
  String? _savedPath;
  String? _statusMessage;
  String? _errorMessage;
  int? _buildCount;
  var _disposed = false;
  Future<void>? _bootstrapFuture;

  WarlockMatrixPathPhase get phase => _phase;
  String get pathField => _pathField;
  String? get savedPath => _savedPath;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  int? get buildCount => _buildCount;
  String get settingFilePath => _setting.settingPath;

  bool get isBusy =>
      _phase == WarlockMatrixPathPhase.loading ||
      _phase == WarlockMatrixPathPhase.saving ||
      _phase == WarlockMatrixPathPhase.probing;

  /// Resolved path using saved setting → env → none.
  String? get resolvedPath => resolveWarlockMatrixPath(
        savedSetting: _savedPath,
        environment: _environment ?? const <String, String>{},
      );

  String get displayStatus {
    if (_phase == WarlockMatrixPathPhase.error &&
        _errorMessage != null &&
        _errorMessage!.isNotEmpty) {
      return _errorMessage!;
    }
    if (_statusMessage != null && _statusMessage!.isNotEmpty) {
      return _statusMessage!;
    }
    return 'No path set';
  }

  void setPathField(String path) {
    if (_disposed || path == _pathField) return;
    _pathField = path;
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

  /// Load saved preference and probe resolved path status.
  Future<void> load({bool force = false}) {
    if (_disposed) return Future<void>.value();
    if (_bootstrapFuture != null && !force) return _bootstrapFuture!;
    _bootstrapFuture = _load();
    return _bootstrapFuture!;
  }

  Future<void> _load() async {
    if (_disposed) return;
    _phase = WarlockMatrixPathPhase.loading;
    _errorMessage = null;
    _safeNotify();
    try {
      _savedPath = await _setting.load();
      if (_disposed) return;
      _pathField = _savedPath ??
          warlockMatrixPathFromEnvironment(
            _environment ?? const <String, String>{},
          ) ??
          '';
      await _probe(_pathField);
    } catch (e) {
      if (_disposed) return;
      _phase = WarlockMatrixPathPhase.error;
      _errorMessage = e.toString();
      _safeNotify();
    }
  }

  /// Persist the path field and re-probe. Invokes [onSaved] with the trimmed
  /// saved value (null when cleared) after a successful write.
  Future<void> save({ValueChanged<String?>? onSaved}) async {
    if (_disposed) return;
    final trimmed = _pathField.trim();
    _phase = WarlockMatrixPathPhase.saving;
    _errorMessage = null;
    _safeNotify();
    try {
      await _setting.save(trimmed);
      if (_disposed) return;
      _savedPath = trimmed.isEmpty ? null : trimmed;
      onSaved?.call(_savedPath);
      await _probe(trimmed);
    } catch (e) {
      if (_disposed) return;
      _phase = WarlockMatrixPathPhase.error;
      _errorMessage = 'Could not save path: $e';
      _safeNotify();
    }
  }

  Future<void> _probe(String path) async {
    if (_disposed) return;
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      _buildCount = null;
      _statusMessage = 'No path set';
      _phase = WarlockMatrixPathPhase.idle;
      _safeNotify();
      return;
    }

    _phase = WarlockMatrixPathPhase.probing;
    _safeNotify();
    try {
      final bytes = await readOnlyFileBytes(
        trimmed,
        maxBytes: matrixMaxBytes,
      );
      if (_disposed) return;
      final decoded = jsonDecode(utf8.decode(bytes));
      final builds = parseWarlockMatrix(decoded);
      _buildCount = builds.length;
      _statusMessage = 'File found · ${builds.length} builds';
      _errorMessage = null;
      _phase = WarlockMatrixPathPhase.idle;
    } on ReadOnlyFileException catch (e) {
      if (_disposed) return;
      _buildCount = null;
      final msg = e.message;
      if (msg.toLowerCase().contains('not found')) {
        _statusMessage = 'File not found';
        _errorMessage = null;
        _phase = WarlockMatrixPathPhase.idle;
      } else {
        _statusMessage = null;
        _errorMessage = msg;
        _phase = WarlockMatrixPathPhase.error;
      }
    } on FormatException catch (e) {
      if (_disposed) return;
      _buildCount = null;
      _statusMessage = 'not valid JSON';
      _errorMessage = 'not valid JSON (${e.message})';
      _phase = WarlockMatrixPathPhase.error;
    } catch (e) {
      if (_disposed) return;
      _buildCount = null;
      _statusMessage = null;
      _errorMessage = e.toString();
      _phase = WarlockMatrixPathPhase.error;
    }
    _safeNotify();
  }
}
