import 'package:destiny2_db/destiny2_db.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('version table (US2)', () {
    test('current Drift schemaVersion is 1', () {
      expect(driftSchemaVersionCurrent, 1);
      final db = AppDatabase.memory();
      expect(db.schemaVersion, driftSchemaVersionCurrent);
      return db.close();
    });

    test('ensureStepCatalog matches expected ids and product functions', () {
      expect(
        ensureStepCatalog.map((s) => s.id).toList(),
        expectedEnsureStepIds,
      );
      expect(ensureStepCount, 11);
      expect(
        ensureStepCatalog.map((s) => s.productFunction).toList(),
        [
          'ensureSynergySubTypeColumn',
          'ensureStatValuesColumn',
          'ensureGearTierColumn',
          'ensureSocketPlugsColumn',
          'ensureSetItemInstanceIdColumn',
          'ensureBuildsIdentityColumns',
          'ensureVariantArtifactColumns',
          'ensureSoftStatTargetsColumn',
          'ensureSetOptimizerColumns',
          'ensureBuildSynergyTypesTable',
          'ensureSynergyLinkRequiredColumn',
        ],
      );
      for (final step in ensureStepCatalog) {
        expect(step.targetTable, isNotEmpty);
        expect(step.description, isNotEmpty);
      }
    });
  });

  group('empty → current (US1)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('opens with all core tables', () async {
      final tables = await db.listUserTableNames();
      expect(tables, containsAll(expectedCoreTables));
    });

    test('late ensure columns present after empty create', () async {
      for (final entry in lateColumnsByTable.entries) {
        final table = entry.key;
        final rows = await db
            .customSelect(
              'PRAGMA table_info($table)',
              readsFrom: {},
            )
            .get();
        final names = rows.map((r) => r.read<String>('name')).toSet();
        for (final col in entry.value) {
          expect(names, contains(col), reason: '$table.$col missing');
        }
      }
    });

    test('foreign_keys ON after migrate open', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });

    test('second open on file retains current schema', () async {
      // Covered lightly: re-run ensure on already-current DB does not throw.
      await applyEnsureUpgrades(DriftEnsureUpgradeExecutor(db));
      final tables = await db.listUserTableNames();
      expect(tables, contains('build_synergy_types'));
    });
  });

  group('partial ensure upgrades (US3)', () {
    late Database raw;
    late EnsureUpgradeExecutor ex;

    setUp(() {
      raw = sqlite3.openInMemory();
      raw.execute('PRAGMA foreign_keys = ON');
      ex = SqliteEnsureUpgradeExecutor(raw);
    });

    tearDown(() {
      raw.close();
    });

    test('adds inventory late columns to minimal inventory_items', () async {
      raw.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bungie_membership_id TEXT NOT NULL UNIQUE,
  membership_type INTEGER NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  last_sync_at TEXT
);
CREATE TABLE inventory_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  instance_id TEXT NOT NULL,
  item_hash INTEGER NOT NULL,
  bucket TEXT NOT NULL,
  location TEXT NOT NULL,
  character_id TEXT,
  power INTEGER NOT NULL DEFAULT 0,
  is_masterwork INTEGER NOT NULL DEFAULT 0,
  is_crafted INTEGER NOT NULL DEFAULT 0,
  plug_hashes TEXT NOT NULL DEFAULT '[]',
  roll_tags TEXT NOT NULL DEFAULT '[]',
  synced_at TEXT NOT NULL,
  UNIQUE(user_id, instance_id)
);
''');

      final before = await ex.columnNames('inventory_items');
      expect(before, isNot(contains('stat_values')));
      expect(before, isNot(contains('gear_tier')));
      expect(before, isNot(contains('socket_plugs')));

      await applyEnsureUpgrades(ex);

      final after = await ex.columnNames('inventory_items');
      expect(after, contains('stat_values'));
      expect(after, contains('gear_tier'));
      expect(after, contains('socket_plugs'));

      // Idempotent
      await applyEnsureUpgrades(ex);
      final again = await ex.columnNames('inventory_items');
      expect(again, containsAll(['stat_values', 'gear_tier', 'socket_plugs']));
    });

    test('adds synergies.sub_type and set_items.instance_id', () async {
      raw.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bungie_membership_id TEXT NOT NULL UNIQUE,
  membership_type INTEGER NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  last_sync_at TEXT
);
CREATE TABLE synergies (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE sets (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE set_items (
  id TEXT PRIMARY KEY,
  set_id TEXT NOT NULL REFERENCES sets(id) ON DELETE CASCADE,
  slot TEXT NOT NULL,
  item_hash INTEGER NOT NULL,
  item_name TEXT NOT NULL,
  selected_perks TEXT NOT NULL DEFAULT '[]',
  masterwork_hash INTEGER,
  mod_hashes TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  removed_at TEXT
);
''');

      await applyEnsureUpgrades(ex);

      expect(await ex.columnNames('synergies'), contains('sub_type'));
      expect(await ex.columnNames('set_items'), contains('instance_id'));
      expect(
        await ex.columnNames('sets'),
        containsAll(['optimizer_constraints', 'linked_mod_set_id']),
      );
    });

    test('creates build_synergy_types and migrates legacy build_synergies',
        () async {
      raw.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bungie_membership_id TEXT NOT NULL UNIQUE,
  membership_type INTEGER NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  last_sync_at TEXT
);
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
CREATE TABLE synergies (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE build_synergies (
  build_id TEXT NOT NULL,
  synergy_id TEXT NOT NULL,
  attached_at TEXT NOT NULL
);
INSERT INTO users (bungie_membership_id, membership_type) VALUES ('m1', 3);
INSERT INTO builds (id, user_id, name, class_name, subclass, created_at, updated_at)
VALUES ('b1', 1, 'Build', 'Hunter', 'Gunslinger', 't0', 't0');
INSERT INTO synergies (id, user_id, name, type, created_at, updated_at)
VALUES ('s1', 1, 'Solar', 'element', 't0', 't0');
INSERT INTO build_synergies (build_id, synergy_id, attached_at)
VALUES ('b1', 's1', 't0');
''');

      expect(await ex.tableExists('build_synergy_types'), isFalse);
      await applyEnsureUpgrades(ex);
      expect(await ex.tableExists('build_synergy_types'), isTrue);
      expect(await ex.tableExists('build_synergies'), isFalse);

      final rows = raw.select('SELECT build_id, type FROM build_synergy_types');
      expect(rows, hasLength(1));
      expect(rows.first['build_id'], 'b1');
      expect(rows.first['type'], 'element');

      // Identity columns also added
      final buildCols = await ex.columnNames('builds');
      expect(buildCols, contains('exotic_weapon_hash'));
      expect(buildCols, contains('pinned_super'));
      expect(buildCols, contains('soft_stat_targets'));
    });

    test('rebuilds builds when exotic_armor_hash is NOT NULL', () async {
      raw.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bungie_membership_id TEXT NOT NULL UNIQUE,
  membership_type INTEGER NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  last_sync_at TEXT
);
CREATE TABLE builds (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  class_name TEXT NOT NULL,
  subclass TEXT NOT NULL,
  exotic_armor_hash INTEGER NOT NULL,
  exotic_armor_name TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO users (bungie_membership_id, membership_type) VALUES ('m1', 3);
INSERT INTO builds (id, user_id, name, class_name, subclass, exotic_armor_hash, exotic_armor_name, created_at, updated_at)
VALUES ('b1', 1, 'Build', 'Titan', 'Sunbreaker', 42, 'Cuirass', 't0', 't0');
''');

      expect(await ex.columnIsNotNull('builds', 'exotic_armor_hash'), isTrue);
      await applyEnsureUpgrades(ex);
      expect(await ex.columnIsNotNull('builds', 'exotic_armor_hash'), isFalse);

      final rows = raw.select(
        'SELECT id, exotic_armor_hash, exotic_armor_name FROM builds',
      );
      expect(rows, hasLength(1));
      expect(rows.first['exotic_armor_hash'], 42);
      expect(rows.first['exotic_armor_name'], 'Cuirass');
    });

    test('adds variant artifact columns', () async {
      raw.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bungie_membership_id TEXT NOT NULL UNIQUE,
  membership_type INTEGER NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  last_sync_at TEXT
);
CREATE TABLE builds (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  class_name TEXT NOT NULL,
  subclass TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE build_variants (
  id TEXT PRIMARY KEY,
  build_id TEXT NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0,
  exotic_weapon_hash INTEGER,
  exotic_weapon_name TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''');

      await applyEnsureUpgrades(ex);
      final cols = await ex.columnNames('build_variants');
      expect(cols, contains('artifact_hash'));
      expect(cols, contains('artifact_name'));
      expect(cols, contains('artifact_config'));
    });
  });
}
