import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'migration_version_table.dart';

/// Minimal SQL surface for idempotent ensure* upgrades (DART-014).
///
/// Product parity: `src/lib/db/client.ts` ensure functions use PRAGMA table_info
/// and conditional ALTER / CREATE / rebuild.
abstract class EnsureUpgradeExecutor {
  /// Whether a user table exists.
  Future<bool> tableExists(String name);

  /// Column names from `PRAGMA table_info(table)`.
  Future<List<String>> columnNames(String table);

  /// Whether [column] has NOT NULL (PRAGMA notnull=1). Null if column missing.
  Future<bool?> columnIsNotNull(String table, String column);

  /// Execute raw SQL (may contain multiple statements separated by `;`).
  Future<void> exec(String sql);
}

/// Drift-backed executor used from [AppDatabase] `beforeOpen`.
class DriftEnsureUpgradeExecutor implements EnsureUpgradeExecutor {
  DriftEnsureUpgradeExecutor(this._db);

  final GeneratedDatabase _db;

  static final _ident = RegExp(r'^[a-z_][a-z0-9_]*$');

  void _assertIdent(String name) {
    if (!_ident.hasMatch(name)) {
      throw ArgumentError.value(name, 'name', 'expected safe SQL identifier');
    }
  }

  @override
  Future<bool> tableExists(String name) async {
    _assertIdent(name);
    final rows = await _db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
      readsFrom: {},
    ).get();
    return rows.isNotEmpty;
  }

  Future<List<QueryRow>> _tableInfo(String table) async {
    _assertIdent(table);
    return _db
        .customSelect(
          'PRAGMA table_info($table)',
          readsFrom: {},
        )
        .get();
  }

  @override
  Future<List<String>> columnNames(String table) async {
    final rows = await _tableInfo(table);
    return rows.map((r) => r.read<String>('name')).toList();
  }

  @override
  Future<bool?> columnIsNotNull(String table, String column) async {
    final rows = await _tableInfo(table);
    for (final r in rows) {
      if (r.read<String>('name') == column) {
        return r.read<int>('notnull') == 1;
      }
    }
    return null;
  }

  @override
  Future<void> exec(String sql) async {
    // Split multi-statement product rebuild scripts; sqlite3 allows one at a time
    // via Drift customStatement (single statement).
    final parts = sql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final part in parts) {
      await _db.customStatement(part);
    }
  }
}

/// Direct sqlite3 executor for unit tests / import tooling without Drift createAll.
class SqliteEnsureUpgradeExecutor implements EnsureUpgradeExecutor {
  SqliteEnsureUpgradeExecutor(this.db);

  final sqlite3.Database db;

  static final _ident = RegExp(r'^[a-z_][a-z0-9_]*$');

  void _assertIdent(String name) {
    if (!_ident.hasMatch(name)) {
      throw ArgumentError.value(name, 'name', 'expected safe SQL identifier');
    }
  }

  @override
  Future<bool> tableExists(String name) async {
    _assertIdent(name);
    final rows = db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [name],
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<String>> columnNames(String table) async {
    _assertIdent(table);
    final rows = db.select('PRAGMA table_info($table)');
    return rows.map((r) => r['name'] as String).toList();
  }

  @override
  Future<bool?> columnIsNotNull(String table, String column) async {
    _assertIdent(table);
    final rows = db.select('PRAGMA table_info($table)');
    for (final r in rows) {
      if (r['name'] == column) {
        return (r['notnull'] as int) == 1;
      }
    }
    return null;
  }

  @override
  Future<void> exec(String sql) async {
    final parts = sql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final part in parts) {
      db.execute(part);
    }
  }
}

/// Apply all product-mirroring ensure* upgrades (idempotent).
///
/// Order matches `runMigrations` ensure block in `src/lib/db/client.ts`.
/// Safe no-op when tables/columns already match current schema.
///
/// If a target table is missing, steps that would ALTER it are skipped
/// (safer than product for incomplete fixtures; greenfield uses createAll first).
Future<void> applyEnsureUpgrades(EnsureUpgradeExecutor ex) async {
  await _ensureSynergySubTypeColumn(ex);
  await _ensureStatValuesColumn(ex);
  await _ensureGearTierColumn(ex);
  await _ensureSocketPlugsColumn(ex);
  await _ensureSetItemInstanceIdColumn(ex);
  await _ensureBuildsIdentityColumns(ex);
  await _ensureVariantArtifactColumns(ex);
  await _ensureSoftStatTargetsColumn(ex);
  await _ensureSetOptimizerColumns(ex);
  await _ensureBuildSynergyTypesTable(ex);
}

Future<void> _addColumnIfMissing(
  EnsureUpgradeExecutor ex, {
  required String table,
  required String column,
  required String alterSql,
}) async {
  if (!await ex.tableExists(table)) return;
  final cols = await ex.columnNames(table);
  if (cols.contains(column)) return;
  await ex.exec(alterSql);
}

Future<void> _ensureSynergySubTypeColumn(EnsureUpgradeExecutor ex) async {
  await _addColumnIfMissing(
    ex,
    table: 'synergies',
    column: 'sub_type',
    alterSql: 'ALTER TABLE synergies ADD COLUMN sub_type TEXT',
  );
}

Future<void> _ensureStatValuesColumn(EnsureUpgradeExecutor ex) async {
  await _addColumnIfMissing(
    ex,
    table: 'inventory_items',
    column: 'stat_values',
    alterSql: 'ALTER TABLE inventory_items ADD COLUMN stat_values TEXT',
  );
}

Future<void> _ensureGearTierColumn(EnsureUpgradeExecutor ex) async {
  await _addColumnIfMissing(
    ex,
    table: 'inventory_items',
    column: 'gear_tier',
    alterSql: 'ALTER TABLE inventory_items ADD COLUMN gear_tier INTEGER',
  );
}

Future<void> _ensureSocketPlugsColumn(EnsureUpgradeExecutor ex) async {
  await _addColumnIfMissing(
    ex,
    table: 'inventory_items',
    column: 'socket_plugs',
    alterSql: 'ALTER TABLE inventory_items ADD COLUMN socket_plugs TEXT',
  );
}

Future<void> _ensureSetItemInstanceIdColumn(EnsureUpgradeExecutor ex) async {
  await _addColumnIfMissing(
    ex,
    table: 'set_items',
    column: 'instance_id',
    alterSql: 'ALTER TABLE set_items ADD COLUMN instance_id TEXT',
  );
}

Future<void> _ensureSoftStatTargetsColumn(EnsureUpgradeExecutor ex) async {
  // Product: if builds table missing (cols.length === 0) return
  await _addColumnIfMissing(
    ex,
    table: 'builds',
    column: 'soft_stat_targets',
    alterSql: 'ALTER TABLE builds ADD COLUMN soft_stat_targets TEXT',
  );
}

Future<void> _ensureSetOptimizerColumns(EnsureUpgradeExecutor ex) async {
  await _addColumnIfMissing(
    ex,
    table: 'sets',
    column: 'optimizer_constraints',
    alterSql: 'ALTER TABLE sets ADD COLUMN optimizer_constraints TEXT',
  );
  await _addColumnIfMissing(
    ex,
    table: 'sets',
    column: 'linked_mod_set_id',
    alterSql: 'ALTER TABLE sets ADD COLUMN linked_mod_set_id TEXT',
  );
}

Future<void> _ensureVariantArtifactColumns(EnsureUpgradeExecutor ex) async {
  if (!await ex.tableExists('build_variants')) return;
  final cols = await ex.columnNames('build_variants');
  if (!cols.contains('artifact_hash')) {
    await ex.exec(
      'ALTER TABLE build_variants ADD COLUMN artifact_hash INTEGER',
    );
    await ex.exec(
      'ALTER TABLE build_variants ADD COLUMN artifact_name TEXT',
    );
  }
  if (!cols.contains('artifact_config')) {
    // Re-read in case artifact_hash branch ran; config may still be missing alone
    final cols2 = await ex.columnNames('build_variants');
    if (!cols2.contains('artifact_config')) {
      await ex.exec(
        "ALTER TABLE build_variants ADD COLUMN artifact_config TEXT NOT NULL DEFAULT '[]'",
      );
    }
  }
}

Future<void> _ensureBuildsIdentityColumns(EnsureUpgradeExecutor ex) async {
  if (!await ex.tableExists('builds')) return;
  final cols = await ex.columnNames('builds');

  if (!cols.contains('exotic_weapon_hash')) {
    await ex.exec(
      'ALTER TABLE builds ADD COLUMN exotic_weapon_hash INTEGER',
    );
    await ex.exec(
      'ALTER TABLE builds ADD COLUMN exotic_weapon_name TEXT',
    );
  }
  if (!cols.contains('pinned_super')) {
    await ex.exec('ALTER TABLE builds ADD COLUMN pinned_super TEXT');
  }

  final armorNotNull = await ex.columnIsNotNull('builds', 'exotic_armor_hash');
  if (armorNotNull == true) {
    // Product rebuild: drop NOT NULL on exotic_armor_hash (and ship identity cols).
    // Note: product mig table omits soft_stat_targets; later ensure re-adds it.
    await ex.exec('''
CREATE TABLE builds_identity_mig (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  class_name TEXT NOT NULL,
  subclass TEXT NOT NULL,
  exotic_armor_hash INTEGER,
  exotic_armor_name TEXT,
  exotic_weapon_hash INTEGER,
  exotic_weapon_name TEXT,
  pinned_super TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO builds_identity_mig (
  id, user_id, name, class_name, subclass,
  exotic_armor_hash, exotic_armor_name,
  exotic_weapon_hash, exotic_weapon_name, pinned_super,
  created_at, updated_at
)
SELECT
  id, user_id, name, class_name, subclass,
  exotic_armor_hash, exotic_armor_name,
  exotic_weapon_hash, exotic_weapon_name, pinned_super,
  created_at, updated_at
FROM builds;
DROP TABLE builds;
ALTER TABLE builds_identity_mig RENAME TO builds;
''');
  }
}

Future<void> _ensureBuildSynergyTypesTable(EnsureUpgradeExecutor ex) async {
  if (!await ex.tableExists('build_synergy_types')) {
    await ex.exec('''
CREATE TABLE build_synergy_types (
  build_id TEXT NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  sub_type TEXT,
  attached_at TEXT NOT NULL,
  UNIQUE(build_id, type, sub_type)
)
''');
  }

  if (!await ex.tableExists('build_synergies')) return;

  await ex.exec('''
INSERT OR IGNORE INTO build_synergy_types (build_id, type, sub_type, attached_at)
SELECT DISTINCT bs.build_id, s.type, COALESCE(s.sub_type, ''), bs.attached_at
FROM build_synergies bs
INNER JOIN synergies s ON s.id = bs.synergy_id;
DROP TABLE build_synergies;
''');
}

/// Convenience: open a raw in-memory sqlite3 DB (tests / tools).
sqlite3.Database openSqliteMemory() => sqlite3.sqlite3.openInMemory();

/// Late columns that greenfield create-all must expose (spot-check list).
const lateColumnsByTable = <String, List<String>>{
  'synergies': ['sub_type'],
  'inventory_items': ['stat_values', 'gear_tier', 'socket_plugs'],
  'set_items': ['instance_id'],
  'builds': [
    'exotic_weapon_hash',
    'exotic_weapon_name',
    'pinned_super',
    'soft_stat_targets',
  ],
  'build_variants': [
    'artifact_hash',
    'artifact_name',
    'artifact_config',
  ],
  'sets': ['optimizer_constraints', 'linked_mod_set_id'],
};

/// Number of catalog steps (must match product ensure count).
int get ensureStepCount => ensureStepCatalog.length;
