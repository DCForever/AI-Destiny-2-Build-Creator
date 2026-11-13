import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'storage_root.dart';

/// Soft cap for `{StorageRoot}/settings/warlock_matrix_path.txt` reads.
///
/// Path preferences are a single line; oversized files are rejected before use.
const int kWarlockMatrixPathSettingMaxBytes = 8 * 1024;

/// Thrown when the Warlock matrix path setting cannot be read safely.
class WarlockMatrixPathSettingException implements Exception {
  WarlockMatrixPathSettingException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
///
/// Reads check length against [maxBytes] before loading bytes and use only the
/// first line of the file.
class WarlockMatrixPathSetting implements WarlockMatrixPathSettingStore {
  WarlockMatrixPathSetting({
    required StorageRoot root,
    this.maxBytes = kWarlockMatrixPathSettingMaxBytes,
    this.beforeRename,
  }) : _root = root;

  final StorageRoot _root;

  /// Size cap checked against file length before reading bytes.
  final int maxBytes;

  /// Test hook: invoked after the `.tmp` is flushed, before rename.
  /// Throw to simulate a mid-write failure without truncating the setting.
  final Future<void> Function()? beforeRename;

  /// Exact settings file path under [StorageRoot].
  @override
  String get settingPath => _root.warlockMatrixPathSettingPath;

  String get _tempPath => '$settingPath.tmp';

  /// Load the saved path, or null when missing/blank.
  ///
  /// Uses only the first line. Oversized files fail closed.
  @override
  Future<String?> load() async {
    final file = File(settingPath);
    if (!await file.exists()) return null;
    final text = utf8.decode(await _readCappedBytes(file));
    final firstLine = _firstLine(text).trim();
    if (firstLine.isEmpty) return null;
    return firstLine;
  }

  /// Persist [path] (trimmed). Blank clears the saved setting (writes empty).
  ///
  /// Atomic replace via `.tmp` + rename. Creates `settings/` if needed.
  /// A failed rename deletes the `.tmp` and leaves the prior file intact.
  @override
  Future<void> save(String path) async {
    await Directory(_root.settingsDir).create(recursive: true);
    final tmp = File(_tempPath);
    final bytes = Uint8List.fromList(utf8.encode(path.trim()));
    final handle = await tmp.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    try {
      final hook = beforeRename;
      if (hook != null) await hook();
      await tmp.rename(settingPath);
    } catch (_) {
      if (await tmp.exists()) {
        await tmp.delete();
      }
      rethrow;
    }
  }

  Future<Uint8List> _readCappedBytes(File file) async {
    if (maxBytes < 1) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be >= 1');
    }
    final handle = await file.open(mode: FileMode.read);
    try {
      final length = await handle.length();
      if (length > maxBytes) {
        throw WarlockMatrixPathSettingException(
          'file exceeds size limit ($length > $maxBytes bytes)',
        );
      }
      if (length == 0) return Uint8List(0);
      return await handle.read(length);
    } finally {
      await handle.close();
    }
  }

  static String _firstLine(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final newline = normalized.indexOf('\n');
    if (newline < 0) return normalized;
    return normalized.substring(0, newline);
  }
}
