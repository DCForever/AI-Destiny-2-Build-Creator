import 'package:drift/drift.dart';

/// Stub openers for platforms without native or web support.
QueryExecutor openMemoryExecutor() {
  throw UnsupportedError(
    'AppDatabase.memory() is not supported on this platform.',
  );
}

QueryExecutor openFileExecutor(String path) {
  throw UnsupportedError(
    'AppDatabase.file() is not supported on this platform. Path: $path',
  );
}
