/// Destiny 2 Build Creator — Drift SQLite schema + migrations + repos.
///
/// Core tables mirror product `src/lib/db`. Open via [AppDatabase.memory] or
/// [AppDatabase.file]. Ensure* upgrades (DART-014) heal partial schemas on open.
/// Library repositories (builds/sets/synergies/variants): DART-015.
/// Inventory full-replace + sync meta + busy lock: DART-016.
/// Legacy Next `.cache/app.db` → StorageRoot import (dry-run + apply): DART-048.
library;

export 'src/app_database.dart';
export 'src/ensure_upgrades.dart';
export 'src/legacy_import/legacy_db_import.dart';
export 'src/migration_version_table.dart';
export 'src/schema_notes.dart';
export 'src/tables.dart';
export 'src/repos/build_repository.dart';
export 'src/repos/inventory_busy_lock.dart';
export 'src/repos/inventory_records.dart';
export 'src/repos/inventory_repository.dart';
export 'src/repos/armor_set_stats.dart';
export 'src/repos/instance_projection.dart';
export 'src/repos/json_codec.dart';
export 'src/repos/library_records.dart';
export 'src/repos/set_item_repository.dart';
export 'src/repos/set_repository.dart';
export 'src/repos/synergy_repository.dart';
export 'src/repos/user_repository.dart';
export 'src/repos/variant_repository.dart';
export 'src/repos/roll_target_repository.dart';
