/// Conditional legacy Next.js `app.db` → StorageRoot import (DART-048).
///
/// Native/VM: [LegacyDbImporter] with dry-run + apply.
/// Web: stub throws [UnsupportedError] (use desktop import path).
library;

export 'legacy_db_import_stub.dart'
    if (dart.library.io) 'legacy_db_import_io.dart';
