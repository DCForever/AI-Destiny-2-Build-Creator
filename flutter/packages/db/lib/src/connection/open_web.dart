import 'package:drift/drift.dart';

/// Native-style factories are unavailable on web.
///
/// Web hosts must open via Drift WasmDatabase.open and construct
/// AppDatabase with the resolved QueryExecutor (see DART-043).
QueryExecutor openMemoryExecutor() {
  throw UnsupportedError(
    'AppDatabase.memory() is not available on web. '
    'Open via WasmDatabase.open and AppDatabase(executor) (DART-043).',
  );
}

QueryExecutor openFileExecutor(String path) {
  throw UnsupportedError(
    'AppDatabase.file() is not available on web (path: $path). '
    'Open via WasmDatabase.open and AppDatabase(executor) (DART-043).',
  );
}
