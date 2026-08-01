import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/settings/legacy_db_import_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void _seedLegacy(String path) {
  final db = sqlite3.open(path);
  try {
    db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bungie_membership_id TEXT NOT NULL UNIQUE,
        membership_type INTEGER NOT NULL,
        display_name TEXT NOT NULL DEFAULT '',
        last_sync_at TEXT
      );
    ''');
    db.execute('''
      CREATE TABLE builds (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        subclass TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    db.execute(
      "INSERT INTO users (bungie_membership_id, membership_type) VALUES ('m1', 3)",
    );
    db.execute(
      "INSERT INTO builds (id, user_id, name, class_name, subclass, created_at, updated_at) "
      "VALUES ('b1', 1, 'B', 'Titan', 'Solar', 't', 't')",
    );
  } finally {
    db.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late StorageRoot root;
  late LegacyDbImportController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dart048_ctrl_');
    root = StorageRoot(basePath: temp.path);
    await root.ensureLayout();
    controller = LegacyDbImportController(storageRoot: root);
  });

  tearDown(() async {
    controller.dispose();
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  test('dry-run success enables apply when no target', () async {
    final source = p.join(temp.path, 'legacy.db');
    _seedLegacy(source);
    controller.setSourcePath(source);
    await controller.dryRun();

    expect(controller.phase, LegacyDbImportPhase.dryRunReady);
    expect(controller.hasSuccessfulDryRun, isTrue);
    expect(controller.canApply, isTrue);
    expect(controller.plan!.sourceTableCounts['users'], 1);
  });

  test('apply requires confirm when target exists', () async {
    final source = p.join(temp.path, 'legacy.db');
    _seedLegacy(source);
    // Existing platform DB
    final existing = AppDatabase.file(root.appDbPath);
    await existing.customSelect('SELECT 1').get();
    await existing.close();

    controller.setSourcePath(source);
    await controller.dryRun();
    expect(controller.hasSuccessfulDryRun, isTrue);
    expect(controller.canApply, isFalse);

    controller.setConfirmReplace(true);
    expect(controller.canApply, isTrue);

    await controller.apply();
    expect(controller.phase, LegacyDbImportPhase.applied);
    expect(controller.result, isNotNull);
    expect(controller.result!.backupPath, isNotNull);
  });

  test('apply without dry-run fails', () async {
    await controller.apply();
    expect(controller.phase, LegacyDbImportPhase.error);
    expect(controller.errorMessage, contains('dry-run'));
  });
}
