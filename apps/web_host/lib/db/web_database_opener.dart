/// Abstraction for opening Drift on web (DART-043).
library;

import 'package:destiny2_db/destiny2_db.dart';

/// Result of a successful or inspected WASM open attempt.
class WebDatabaseOpenResult {
  const WebDatabaseOpenResult({
    required this.database,
    required this.storageImplementation,
    this.missingFeatures = const [],
  });

  final AppDatabase database;
  final String storageImplementation;
  final List<String> missingFeatures;
}

/// Opens (or fakes) the app database for the writer tab.
abstract class WebDatabaseOpener {
  Future<WebDatabaseOpenResult> open();
}

/// Test double: does not touch WASM/OPFS.
class FakeWebDatabaseOpener implements WebDatabaseOpener {
  FakeWebDatabaseOpener({
    this.storageImplementation = 'fake-memory',
    this.missingFeatures = const [],
    this.onOpen,
  });

  final String storageImplementation;
  final List<String> missingFeatures;
  final void Function()? onOpen;

  int openCount = 0;

  @override
  Future<WebDatabaseOpenResult> open() async {
    openCount++;
    onOpen?.call();
    // AppDatabase.memory is native-only; tests on VM use real memory DB.
    final db = AppDatabase.memory();
    return WebDatabaseOpenResult(
      database: db,
      storageImplementation: storageImplementation,
      missingFeatures: missingFeatures,
    );
  }
}
