/// Client entrypoint for the Jaspr web host (DART-042–047).
///
/// Compiled to JavaScript and executed in the browser. No Next.js, no secrets.
/// Opens Drift WASM + OPFS when this tab wins the single-tab writer lock.
/// Loads prebuilt entity bundles for offline Catalog (no raw rebuild).
/// Public+PKCE OAuth with origin-scoped token storage (DART-045).
/// Compose spine (builds/sets/synergies) on writer DB (DART-046).
/// Equip-ready + DIM jsonOnly + optional equip (DART-047).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'auth/browser_http_transport.dart';
import 'auth/pending_auth_store.dart';
import 'auth/token_store.dart';
import 'auth/web_oauth_config.dart';
import 'auth/web_oauth_session.dart';
import 'auth/web_storage_browser.dart';
import 'catalog/bundle_fetch_web.dart';
import 'catalog/entity_bundle_loader.dart';
import 'db/tab_lock_backend_web.dart';
import 'db/tab_writer_lock.dart';
import 'db/wasm_database_opener.dart';
import 'db/web_database_bootstrap.dart';

/// Public Bungie API key only (never CLIENT_SECRET).
const String _bungieApiKeyDefine = String.fromEnvironment('BUNGIE_API_KEY');

Future<void> _browserClipboardWriter(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
  } catch (_) {
    // Fallback: controller still retains lastJson for preview.
  }
}

void main() {
  final lockBackend = WebLocalStorageTabLockBackend();
  final bootstrap = WebDatabaseBootstrap(
    lockBackend: lockBackend,
    opener: WasmWebDatabaseOpener(),
  );

  registerWriterLockUnloadHook(
    backend: lockBackend,
    lockName: kWebAppDbWriterLockName,
    ownerId: bootstrap.tabId,
  );

  // Kick off open as early as possible; App also observes status.
  bootstrap.start();

  final entityLoader = WebEntityBundleLoader(
    fetcher: fetchEntityBundleText,
  );

  final navigator = BrowserWebAuthNavigator();
  final oauthConfig = WebOAuthConfig.resolve(origin: navigator.origin);
  final tokenStore = LocalStorageTokenStore(storage: BrowserLocalStorage());
  final pendingStore =
      SessionStoragePendingAuthStore(storage: BrowserSessionStorage());
  final oauthClient = BungieOAuthClient(
    clientId:
        oauthConfig.clientId.isEmpty ? 'unconfigured' : oauthConfig.clientId,
    redirectUri: oauthConfig.redirectUri,
    transport: createBrowserBungieHttpTransport(),
  );
  final oauthSession = WebOAuthSession(
    config: oauthConfig,
    tokenStore: tokenStore,
    oauthClient: oauthClient,
    navigator: navigator,
    pendingAuthStore: pendingStore,
  );
  oauthSession.restore();

  final apiKey =
      _bungieApiKeyDefine.isEmpty ? 'unconfigured' : _bungieApiKeyDefine;
  final platformHttp = BungieHttpClient(
    apiKey: apiKey,
    transport: createBrowserBungieHttpTransport(),
  );
  final profileClient = HttpBungieProfileClient(http: platformHttp);
  final writeClient = HttpBungieWriteClient(http: platformHttp);

  runApp(
    App(
      bootstrap: bootstrap,
      entityLoader: entityLoader,
      oauthSession: oauthSession,
      profileClient: profileClient,
      writeClient: writeClient,
      clipboardWriter: _browserClipboardWriter,
    ),
  );
}
