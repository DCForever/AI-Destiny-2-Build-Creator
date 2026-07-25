import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

/// Drift database for multiplatform app data (DART-013 schema baseline).
///
/// schemaVersion **1** = greenfield create-all matching product current columns.
/// Historical migrations: DART-014.
@DriftDatabase(
  tables: [
    Users,
    InventoryItems,
    InventorySyncMeta,
    Loadouts,
    Sets,
    SetTags,
    SetItems,
    Synergies,
    SynergyLinks,
    Builds,
    BuildTags,
    BuildVariants,
    BuildSynergyTypes,
    VariantSetAttachments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory DB for unit tests.
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// File-backed DB at [path] (e.g. [StorageRoot.appDbPath] from destiny2_storage).
  ///
  /// Creates parent directories if missing. Does not depend on path_provider.
  factory AppDatabase.file(String path) {
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return AppDatabase(NativeDatabase(file));
  }

  /// Convenience: join [baseDir] with `app.db` (same segment as StorageRoot).
  factory AppDatabase.inDirectory(String baseDir) {
    return AppDatabase.file(p.join(baseDir, 'app.db'));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Product client.ts: foreign_keys = ON
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Table names present in sqlite_master (type=table, non-internal).
  Future<List<String>> listUserTableNames() async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      readsFrom: {},
    ).get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  /// Index names for [table] via PRAGMA index_list.
  Future<List<String>> listIndexNames(String table) async {
    final rows = await customSelect(
      'PRAGMA index_list($table)',
      readsFrom: {},
    ).get();
    return rows.map((r) => r.read<String>('name')).toList();
  }
}
