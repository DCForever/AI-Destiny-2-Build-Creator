/// Client entrypoint for the Jaspr web host (DART-042–044).
///
/// Compiled to JavaScript and executed in the browser. No Next.js, no secrets.
/// Opens Drift WASM + OPFS when this tab wins the single-tab writer lock.
/// Loads prebuilt entity bundles for offline Catalog (no raw rebuild).
library;

import 'package:jaspr/client.dart';

import 'app.dart';
import 'catalog/bundle_fetch_web.dart';
import 'catalog/entity_bundle_loader.dart';
import 'db/tab_lock_backend_web.dart';
import 'db/tab_writer_lock.dart';
import 'db/wasm_database_opener.dart';
import 'db/web_database_bootstrap.dart';

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

  runApp(
    App(
      bootstrap: bootstrap,
      entityLoader: entityLoader,
    ),
  );
}
