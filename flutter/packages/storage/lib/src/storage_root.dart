import 'package:path/path.dart' as p;

import 'io/layout.dart' as layout;
import 'version_dir.dart';

/// Canonical on-disk layout root for multiplatform Dart shells.
///
/// Production hosts (Flutter Windows first) resolve the base via
/// **path_provider** `getApplicationSupportDirectory()` and pass that path
/// into [StorageRoot.windowsAppSupport]. Do **not** use process CWD or the
/// Next.js repo `.cache` tree as the production root.
///
/// Layout (relative to [basePath]):
/// ```text
/// app.db
/// current-version.json
/// manifest/<versionDir>/<table>.json
/// entities/<versionDir>/<store>.json
/// entities/<versionDir>/meta.json
/// entities/<versionDir>/perk-weapon-index.json
/// users/<membershipId>/preferences.json
/// ```
class StorageRoot {
  /// Absolute or root-relative base directory for all app storage.
  final String basePath;

  /// Creates a [StorageRoot] rooted at [basePath].
  ///
  /// [basePath] must be non-empty after trim. Tests inject a fake path;
  /// Windows hosts inject the path_provider application-support directory.
  StorageRoot({required String basePath}) : basePath = _validateBase(basePath);

  /// Windows / Flutter host factory: application support path from
  /// `path_provider.getApplicationSupportDirectory().path`.
  ///
  /// The Flutter Windows runner already scopes company/product under AppData;
  /// this root is that directory (no extra nested product folder, no `.cache`).
  factory StorageRoot.windowsAppSupport(String applicationSupportPath) {
    return StorageRoot(basePath: applicationSupportPath);
  }

  static String _validateBase(String basePath) {
    final trimmed = basePath.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        basePath,
        'basePath',
        'StorageRoot base path must be non-empty',
      );
    }
    return trimmed;
  }

  /// Primary SQLite database path (opened by Drift in later slices).
  String get appDbPath => p.join(basePath, 'app.db');

  /// Sidecar tracking which manifest version is current.
  String get currentVersionPath => p.join(basePath, 'current-version.json');

  /// Directory for raw Bungie manifest tables.
  String get manifestDir => p.join(basePath, 'manifest');

  /// Directory for derived entity stores.
  String get entitiesDir => p.join(basePath, 'entities');

  /// Directory for per-user files.
  String get usersDir => p.join(basePath, 'users');

  /// Raw table JSON path: `manifest/<versionDir>/<table>.json`.
  String rawTablePath(String version, String table) {
    return p.join(
      manifestDir,
      versionToDirName(version),
      '$table.json',
    );
  }

  /// Entity store JSON path: `entities/<versionDir>/<store>.json`.
  String entityStorePath(String version, String store) {
    return p.join(
      entitiesDir,
      versionToDirName(version),
      '$store.json',
    );
  }

  /// Entity cache meta: `entities/<versionDir>/meta.json`.
  String entityCacheMetaPath(String version) {
    return p.join(
      entitiesDir,
      versionToDirName(version),
      'meta.json',
    );
  }

  /// Perk–weapon index: `entities/<versionDir>/perk-weapon-index.json`.
  String perkWeaponIndexPath(String version) {
    return p.join(
      entitiesDir,
      versionToDirName(version),
      'perk-weapon-index.json',
    );
  }

  /// User preferences: `users/<membershipId>/preferences.json`.
  String userPreferencesPath(String bungieMembershipId) {
    return p.join(usersDir, bungieMembershipId, 'preferences.json');
  }

  /// Creates top-level layout directories under [basePath] if missing.
  ///
  /// Does not create versioned subfolders (writers create those as needed).
  /// On web (no dart:io) this is a no-op — entity data uses prebuilt bundles.
  Future<void> ensureLayout() async {
    await layout.ensureStorageLayout(basePath, [
      manifestDir,
      entitiesDir,
      usersDir,
    ]);
  }
}
