import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'auth/browser_launcher.dart';
import 'auth/loopback_callback_server.dart';
import 'auth/token_store.dart';
import 'auth/windows_oauth_session.dart';
import 'settings/inventory_sync_controller.dart';

/// Default Windows loopback redirect (must match Bungie Public app registration).
const String kDefaultWindowsRedirectUri = 'http://127.0.0.1:8765/callback';

/// Owns host runtime resources for the Windows shell (DART-019/020/023/025).
///
/// Guarantees a **single** [AppDatabase] instance for the process lifetime of
/// this object. Call [dispose] on shutdown to close the SQLite connection.
/// Entity catalog reads use [OfflineCatalog] (file JSON only — no second DB).
/// OAuth tokens live in [oauthSession] / [TokenStore] — **not** SQLite.
/// Inventory sync UI state lives in [inventorySync] (DART-025).
class AppServices {
  AppServices({
    required this.storageRoot,
    required this.db,
    required this.manifestRefresh,
    required this.offlineCatalog,
    required this.oauthSession,
    required this.profileClient,
    required this.inventorySync,
  });

  final StorageRoot storageRoot;
  final AppDatabase db;
  final ManifestRefreshApi manifestRefresh;
  final OfflineCatalog offlineCatalog;
  final WindowsOAuthSession oauthSession;
  final BungieProfileClient profileClient;
  final InventorySyncController inventorySync;

  bool _closed = false;

  /// Whether [dispose] has already closed the database.
  bool get isClosed => _closed;

  /// Closes the single DB connection. Idempotent.
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    inventorySync.dispose();
    await db.close();
  }
}

/// Bootstrap for Flutter Windows host: StorageRoot → single DB → manifest API → OAuth → inventory sync.
class HostBootstrap {
  HostBootstrap._();

  /// Opens layout + one Drift connection + [ManifestRefreshApi] + [OfflineCatalog]
  /// + [WindowsOAuthSession] + [InventorySyncController].
  ///
  /// Overrides exist for tests:
  /// - [storageRoot]: skip path_provider
  /// - [database]: inject memory/temp DB (must still be the only host connection)
  /// - [manifestRefresh]: fake status API
  /// - [offlineCatalog]: pre-seeded or fake catalog
  /// - [resolveApplicationSupportPath]: alternate path_provider
  /// - [apiKey]: public Bungie API key only (never CLIENT_SECRET)
  /// - [clientId] / [redirectUri]: Public OAuth app (never CLIENT_SECRET)
  /// - [tokenStore] / [oauthClient] / [browserLauncher] / [waitForCallbackOverride]
  /// - [profileClient]: fake inventory profile client for tests
  /// - [inventorySync]: prebuilt controller (optional)
  static Future<AppServices> open({
    StorageRoot? storageRoot,
    AppDatabase? database,
    ManifestRefreshApi? manifestRefresh,
    OfflineCatalog? offlineCatalog,
    String? apiKey,
    String? clientId,
    String? redirectUri,
    TokenStore? tokenStore,
    BungieOAuthClient? oauthClient,
    BrowserLauncher? browserLauncher,
    LoopbackCallbackServer? loopbackServer,
    Future<LoopbackCallbackResult> Function()? waitForCallbackOverride,
    Future<String> Function()? resolveApplicationSupportPath,
    BungieProfileClient? profileClient,
    InventorySyncController? inventorySync,
    InventoryBusyLock? inventoryLock,
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

    final resolvedClientId = clientId ?? '';
    final resolvedRedirect = (redirectUri == null || redirectUri.isEmpty)
        ? kDefaultWindowsRedirectUri
        : redirectUri;

    final store = tokenStore ?? SecureTokenStore();
    final client = oauthClient ??
        BungieOAuthClient(
          clientId: resolvedClientId.isEmpty ? 'unconfigured' : resolvedClientId,
          redirectUri: resolvedRedirect,
        );

    final session = WindowsOAuthSession(
      clientId: resolvedClientId,
      redirectUri: resolvedRedirect,
      tokenStore: store,
      oauthClient: client,
      browserLauncher: browserLauncher,
      loopbackServer: loopbackServer,
      waitForCallbackOverride: waitForCallbackOverride,
    );
    await session.restore();

    // Public API key only. Empty → placeholder so bootstrap still works offline;
    // live profile calls fail until BUNGIE_API_KEY is configured (never CLIENT_SECRET).
    final resolvedProfile = profileClient ??
        HttpBungieProfileClient(
          http: BungieHttpClient(
            apiKey: (apiKey == null || apiKey.isEmpty) ? 'unconfigured' : apiKey,
          ),
        );

    final sync = inventorySync ??
        InventorySyncController(
          db: db,
          session: session,
          profileClient: resolvedProfile,
          lock: inventoryLock,
        );

    return AppServices(
      storageRoot: root,
      db: db,
      manifestRefresh: refresh,
      offlineCatalog: catalog,
      oauthSession: session,
      profileClient: resolvedProfile,
      inventorySync: sync,
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
