import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Owns host runtime resources for the Windows shell (DART-019/020).
///
/// Guarantees a **single** [AppDatabase] instance for the process lifetime of
/// this object. Call [dispose] on shutdown to close the SQLite connection.
/// Entity catalog reads use [OfflineCatalog] (file JSON only — no second DB).
class AppServices {
  AppServices({
    required this.storageRoot,
    required this.db,
    required this.manifestRefresh,
    required this.offlineCatalog,
  });

  final StorageRoot storageRoot;
  final AppDatabase db;
  final ManifestRefreshApi manifestRefresh;
  final OfflineCatalog offlineCatalog;

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

/// Bootstrap for Flutter Windows host: StorageRoot → single DB → manifest API.
class HostBootstrap {
  HostBootstrap._();

  /// Opens layout + one Drift connection + [ManifestRefreshApi] + [OfflineCatalog].
  ///
  /// Overrides exist for tests:
  /// - [storageRoot]: skip path_provider
  /// - [database]: inject memory/temp DB (must still be the only host connection)
  /// - [manifestRefresh]: fake status API
  /// - [offlineCatalog]: pre-seeded or fake catalog
  /// - [resolveApplicationSupportPath]: alternate path_provider
  /// - [apiKey]: public Bungie API key only (never CLIENT_SECRET)
  static Future<AppServices> open({
    StorageRoot? storageRoot,
    AppDatabase? database,
    ManifestRefreshApi? manifestRefresh,
    OfflineCatalog? offlineCatalog,
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

    final catalog = offlineCatalog ?? OfflineCatalog(storageRoot: root);

    return AppServices(
      storageRoot: root,
      db: db,
      manifestRefresh: refresh,
      offlineCatalog: catalog,
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
