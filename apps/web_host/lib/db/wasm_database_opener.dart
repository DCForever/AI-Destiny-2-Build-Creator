/// Real Drift WASM opener for the browser (DART-043).
///
/// Only import from client / web compilation units — not from VM-only tests.
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'web_database_opener.dart';

/// Opens `destiny2_app_db` via [WasmDatabase.open].
class WasmWebDatabaseOpener implements WebDatabaseOpener {
  WasmWebDatabaseOpener({
    this.databaseName = 'destiny2_app_db',
    this.sqlite3Uri = 'sqlite3.wasm',
    this.driftWorkerUri = 'drift_worker.js',
  });

  final String databaseName;
  final String sqlite3Uri;
  final String driftWorkerUri;

  @override
  Future<WebDatabaseOpenResult> open() async {
    final result = await WasmDatabase.open(
      databaseName: databaseName,
      sqlite3Uri: Uri.parse(sqlite3Uri),
      driftWorkerUri: Uri.parse(driftWorkerUri),
    );

    final missing = result.missingFeatures.map((e) => e.name).toList();
    final impl = result.chosenImplementation.name;

    final executor = result.resolvedExecutor;
    final db = AppDatabase(executor);

    return WebDatabaseOpenResult(
      database: db,
      storageImplementation: impl,
      missingFeatures: missing,
    );
  }
}

/// Delayed connection helper (optional alternate wiring).
DatabaseConnection connectOnWeb({
  String databaseName = 'destiny2_app_db',
  String sqlite3Uri = 'sqlite3.wasm',
  String driftWorkerUri = 'drift_worker.js',
}) {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: databaseName,
        sqlite3Uri: Uri.parse(sqlite3Uri),
        driftWorkerUri: Uri.parse(driftWorkerUri),
      );
      return result.resolvedExecutor;
    }),
  );
}
