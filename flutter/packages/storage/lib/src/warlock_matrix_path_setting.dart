import 'dart:io';

import 'storage_root.dart';

/// Load/save contract for the Warlock matrix path preference.
abstract class WarlockMatrixPathSettingStore {
  String get settingPath;
  Future<String?> load();
  Future<void> save(String path);
}

/// App-private persistence for the Warlock matrix file path preference.
///
/// Writes only `{StorageRoot}/settings/warlock_matrix_path.txt` via a `.tmp`
/// sibling + rename. Never writes, moves, or deletes the matrix file itself.
/// Does not touch SQLite / per-build preferences.
class WarlockMatrixPathSetting implements WarlockMatrixPathSettingStore {
  WarlockMatrixPathSetting({required StorageRoot root}) : _root = root;

  final StorageRoot _root;

  /// Exact settings file path under [StorageRoot].
  @override
  String get settingPath => _root.warlockMatrixPathSettingPath;

  String get _tempPath => '$settingPath.tmp';

  /// Load the saved path, or null when missing/blank.
  @override
  Future<String?> load() async {
    final file = File(settingPath);
    if (!await file.exists()) return null;
    final text = (await file.readAsString()).trim();
    if (text.isEmpty) return null;
    return text;
  }

  /// Persist [path] (trimmed). Blank clears the saved setting (writes empty).
  ///
  /// Atomic replace via `.tmp` + rename. Creates `settings/` if needed.
  @override
  Future<void> save(String path) async {
    await Directory(_root.settingsDir).create(recursive: true);
    final tmp = File(_tempPath);
    await tmp.writeAsString(path.trim(), flush: true);
    try {
      await tmp.rename(settingPath);
    } catch (_) {
      if (await tmp.exists()) {
        await tmp.delete();
      }
      rethrow;
    }
  }
}
