/// Destiny 2 Build Creator — Drift SQLite schema + migrations + library repos.
///
/// Core tables mirror product `src/lib/db`. Open via [AppDatabase.memory] or
/// [AppDatabase.file]. Ensure* upgrades (DART-014) heal partial schemas on open.
/// Library repositories (builds/sets/synergies/variants): DART-015.
library;

export 'src/app_database.dart';
export 'src/ensure_upgrades.dart';
export 'src/migration_version_table.dart';
export 'src/schema_notes.dart';
export 'src/tables.dart';
export 'src/repos/build_repository.dart';
export 'src/repos/json_codec.dart';
export 'src/repos/library_records.dart';
export 'src/repos/set_item_repository.dart';
export 'src/repos/set_repository.dart';
export 'src/repos/synergy_repository.dart';
export 'src/repos/user_repository.dart';
export 'src/repos/variant_repository.dart';
