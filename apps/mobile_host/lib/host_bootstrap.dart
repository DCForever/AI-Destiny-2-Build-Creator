import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Owns host runtime resources for the Flutter mobile shell (DART-040).
///
/// Guarantees a **single** [AppDatabase] instance for the process lifetime of
/// this object. Call [dispose] on shutdown to close the SQLite connection.
/// No OAuth / CLIENT_SECRET in this slice — local library only.
class MobileAppServices {
  MobileAppServices({
    required this.storageRoot,
    required this.db,
    required this.manifestRefresh,
  });

  final StorageRoot storageRoot;
  final AppDatabase db;
  final ManifestRefreshApi manifestRefresh;

  bool _closed = false;

  /// Whether [dispose] has already closed the database.
  bool get isClosed => _closed;

  /// Closes the single DB connection. Idempotent.
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    await db.close();
  }
}

/// Bootstrap for Flutter mobile host: StorageRoot → single DB → manifest status API.
class MobileHostBootstrap {
  MobileHostBootstrap._();

  /// Opens layout + one Drift connection + [ManifestRefreshApi].
  ///
  /// Overrides exist for tests:
  /// - [storageRoot]: skip path_provider
  /// - [database]: inject memory/temp DB (must still be the only host connection)
  /// - [manifestRefresh]: fake status API
  /// - [resolveApplicationSupportPath]: alternate path_provider
  /// - [apiKey]: public Bungie API key only (never CLIENT_SECRET); optional
  static Future<MobileAppServices> open({
    StorageRoot? storageRoot,
    AppDatabase? database,
    ManifestRefreshApi? manifestRefresh,
    String? apiKey,
    Future<String> Function()? resolveApplicationSupportPath,
  }) async {
    final root = storageRoot ??
        StorageRoot.windowsAppSupport(
          await _resolveSupportPath(resolveApplicationSupportPath),
        );
    await root.ensureLayout();

    final db = database ?? AppDatabase.file(root.appDbPath);
    // Touch the connection so schema create + ensure* upgrades run once.
    await db.customSelect('SELECT 1').get();

    final refresh = manifestRefresh ??
        WindowsManifestRefresh(
          storageRoot: root,
          apiKey: apiKey,
        );

    return MobileAppServices(
      storageRoot: root,
      db: db,
      manifestRefresh: refresh,
    );
  }

  static Future<String> _resolveSupportPath(
    Future<String> Function()? resolveApplicationSupportPath,
  ) async {
    if (resolveApplicationSupportPath != null) {
      return resolveApplicationSupportPath();
    }
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }
}
