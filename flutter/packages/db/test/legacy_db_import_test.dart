import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// Minimal Next-shaped product DB (partial columns OK — ensure* heals).
void _seedLegacyProductDb(String path) {
  final db = sqlite3.open(path);
  try {
    db.execute('PRAGMA foreign_keys = ON');
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
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        subclass TEXT NOT NULL,
        exotic_armor_hash INTEGER,
        exotic_armor_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    db.execute('''
      CREATE TABLE sets (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    // Intentionally omit set_items.instance_id and builds identity cols for ensure* heal.
    db.execute(
      "INSERT INTO users (bungie_membership_id, membership_type, display_name) "
      "VALUES ('m1', 3, 'Guardian')",
    );
    db.execute(
      "INSERT INTO builds (id, user_id, name, class_name, subclass, created_at, updated_at) "
      "VALUES ('b1', 1, 'Solar Titan', 'Titan', 'Solar', '2026-01-01', '2026-01-01')",
    );
    db.execute(
      "INSERT INTO sets (id, user_id, name, type, created_at, updated_at) "
      "VALUES ('s1', 1, 'Weapons A', 'weapons', '2026-01-01', '2026-01-01')",
    );
  } finally {
    db.close();
  }
}

void main() {
  late Directory temp;
  late LegacyDbImporter importer;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dart048_import_');
    importer = const LegacyDbImporter();
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  group('dryRun', () {
    test('valid product DB → canApply true with counts', () async {
      final source = p.join(temp.path, 'legacy.db');
      _seedLegacyProductDb(source);
      final target = p.join(temp.path, 'storage', 'app.db');

      final plan = await importer.dryRun(
        sourcePath: source,
        targetPath: target,
      );

      expect(plan.canApply, isTrue);
      expect(plan.errors, isEmpty);
      expect(plan.sourceExists, isTrue);
      expect(plan.sourceTableCounts['users'], 1);
      expect(plan.sourceTableCounts['builds'], 1);
      expect(plan.sourceTableCounts['sets'], 1);
      expect(plan.targetExists, isFalse);
      expect(plan.summaryText, contains('canApply: true'));
    });

    test('missing file → canApply false', () async {
      final plan = await importer.dryRun(
        sourcePath: p.join(temp.path, 'nope.db'),
        targetPath: p.join(temp.path, 'app.db'),
      );
      expect(plan.canApply, isFalse);
      expect(plan.errors, isNotEmpty);
    });

    test('empty SQLite without product tables → canApply false', () async {
      final source = p.join(temp.path, 'empty.db');
      final raw = sqlite3.open(source);
      raw.execute('CREATE TABLE foo (id INTEGER PRIMARY KEY)');
      raw.close();

      final plan = await importer.dryRun(
        sourcePath: source,
        targetPath: p.join(temp.path, 'app.db'),
      );
      expect(plan.canApply, isFalse);
      expect(
        plan.errors.any((e) => e.contains('users') || e.contains('content')),
        isTrue,
      );
    });

    test('source equals target → canApply false', () async {
      final source = p.join(temp.path, 'same.db');
      _seedLegacyProductDb(source);
      final plan = await importer.dryRun(
        sourcePath: source,
        targetPath: source,
      );
      expect(plan.canApply, isFalse);
      expect(plan.sourceEqualsTarget, isTrue);
    });

    test('non-SQLite file → canApply false', () async {
      final source = p.join(temp.path, 'notdb.txt');
      File(source).writeAsStringSync('hello');
      final plan = await importer.dryRun(
        sourcePath: source,
        targetPath: p.join(temp.path, 'app.db'),
      );
      expect(plan.canApply, isFalse);
      expect(plan.errors, isNotEmpty);
    });
  });

  group('apply', () {
    test('copies into target and opens with core data', () async {
      final source = p.join(temp.path, 'legacy.db');
      _seedLegacyProductDb(source);
      final targetDir = p.join(temp.path, 'app_support');
      final target = p.join(targetDir, 'app.db');

      final result = await importer.apply(
        sourcePath: source,
        targetPath: target,
      );

      expect(File(target).existsSync(), isTrue);
      expect(result.backupPath, isNull);
      expect(result.tableCountsAfter['users'], 1);
      expect(result.tableCountsAfter['builds'], 1);

      final db = AppDatabase.file(target);
      try {
        final tables = await db.listUserTableNames();
        expect(tables, containsAll(['users', 'builds', 'sets']));
        // ensure* should not throw; soft_stat_targets may be added if builds present
        final cols = await db
            .customSelect('PRAGMA table_info(builds)', readsFrom: {})
            .get();
        final names = cols.map((r) => r.read<String>('name')).toSet();
        expect(names, contains('soft_stat_targets'));
      } finally {
        await db.close();
      }
    });

    test('existing target is backed up', () async {
      final source = p.join(temp.path, 'legacy.db');
      _seedLegacyProductDb(source);
      final target = p.join(temp.path, 'storage', 'app.db');
      Directory(p.dirname(target)).createSync(recursive: true);
      // Seed a different existing target
      final existing = AppDatabase.file(target);
      await existing.customSelect('SELECT 1').get();
      await existing.into(existing.users).insert(
            UsersCompanion.insert(
              bungieMembershipId: 'old',
              membershipType: 1,
            ),
          );
      await existing.close();

      final result = await importer.apply(
        sourcePath: source,
        targetPath: target,
      );

      expect(result.backupPath, isNotNull);
      expect(File(result.backupPath!).existsSync(), isTrue);

      final db = AppDatabase.file(target);
      try {
        final rows = await db.select(db.users).get();
        expect(rows, hasLength(1));
        expect(rows.single.bungieMembershipId, 'm1');
      } finally {
        await db.close();
      }
    });

    test('refuses when dry-run fails', () async {
      expect(
        () => importer.apply(
          sourcePath: p.join(temp.path, 'missing.db'),
          targetPath: p.join(temp.path, 'app.db'),
        ),
        throwsA(isA<LegacyDbImportException>()),
      );
      expect(File(p.join(temp.path, 'app.db')).existsSync(), isFalse);
    });
  });
}
