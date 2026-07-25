/// Destiny 2 Build Creator — Drift SQLite schema + migrations.
///
/// Core tables mirror product `src/lib/db`. Open via [AppDatabase.memory] or
/// [AppDatabase.file]. Ensure* upgrades (DART-014) heal partial schemas on open.
/// Repositories: DART-015+.
library;

export 'src/app_database.dart';
export 'src/ensure_upgrades.dart';
export 'src/migration_version_table.dart';
export 'src/schema_notes.dart';
export 'src/tables.dart';
