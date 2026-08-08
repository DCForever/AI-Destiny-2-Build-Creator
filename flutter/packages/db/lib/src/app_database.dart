import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'connection/open.dart';
import 'ensure_upgrades.dart';
import 'migration_version_table.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Drift database for multiplatform app data.
///
/// schemaVersion **[driftSchemaVersionCurrent]** (1) = greenfield create-all
/// matching product current columns (DART-013). Historical ensure* upgrades
/// run on open (DART-014) so partial / import-shaped DBs heal to current.
///
/// **Opening:**
/// - Native: [AppDatabase.memory] / [AppDatabase.file] / [AppDatabase.inDirectory]
/// - Web (DART-043): construct with executor from `WasmDatabase.open` — do not
///   import `package:drift/native.dart` from web entrypoints.
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
    WeaponRollTargets,
    WeaponRollTargetActive,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory DB for unit tests (native / VM only).
  factory AppDatabase.memory() => AppDatabase(openMemoryExecutor());

  /// File-backed DB at [path] (e.g. [StorageRoot.appDbPath] from destiny2_storage).
  ///
  /// Creates parent directories if missing. Does not depend on path_provider.
  /// Not available on web — use WasmDatabase + [AppDatabase.new].
  factory AppDatabase.file(String path) => AppDatabase(openFileExecutor(path));

  /// Convenience: join [baseDir] with `app.db` (same segment as StorageRoot).
  factory AppDatabase.inDirectory(String baseDir) {
    return AppDatabase(openFileExecutor(p.join(baseDir, 'app.db')));
  }

  @override
  int get schemaVersion => driftSchemaVersionCurrent;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // schemaVersion is still 1 (DART-014). No stepped Drift upgrades yet.
          // Future bumps: add versioned steps here. Column heals for import /
          // partial files also run via applyEnsureUpgrades in beforeOpen.
        },
        beforeOpen: (details) async {
          // Product client.ts: foreign_keys = ON
          await customStatement('PRAGMA foreign_keys = ON');
          // Product runMigrations always runs ensure* after CREATE IF NOT EXISTS.
          await applyEnsureUpgrades(DriftEnsureUpgradeExecutor(this));
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
