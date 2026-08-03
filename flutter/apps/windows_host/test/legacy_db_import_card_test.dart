import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/settings/legacy_db_import_card.dart';
import 'package:destiny2_windows_host/settings/legacy_db_import_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_material_theme.dart';
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

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late StorageRoot root;
  late LegacyDbImportController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dart048_card_');
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

  testWidgets('card renders path field; Apply disabled until dry-run',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LegacyDbImportCard(controller: controller),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('legacy_db_import_card')), findsOneWidget);
    expect(find.byKey(const Key('legacy_db_import_source_field')), findsOneWidget);
    expect(find.byKey(const Key('legacy_db_import_dry_run')), findsOneWidget);

    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('legacy_db_import_apply')),
    );
    expect(apply.onPressed, isNull);
  });

  testWidgets('dry-run then apply without existing target', (tester) async {
    final source = p.join(temp.path, 'legacy.db');
    _seedLegacy(source);

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LegacyDbImportCard(controller: controller),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    await tester.enterText(
      find.byKey(const Key('legacy_db_import_source_field')),
      source,
    );
    await tester.tap(find.byKey(const Key('legacy_db_import_dry_run')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('legacy_db_import_plan_summary')), findsOneWidget);

    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('legacy_db_import_apply')),
    );
    expect(apply.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('legacy_db_import_apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('legacy_db_import_success')), findsOneWidget);
    expect(File(root.appDbPath).existsSync(), isTrue);
  });
}
