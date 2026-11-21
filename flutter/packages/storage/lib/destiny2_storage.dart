/// StorageRoot abstraction for multiplatform app-support layout (DART-012).
///
/// Windows hosts: resolve `getApplicationSupportDirectory()` via path_provider,
/// then `StorageRoot.windowsAppSupport(support.path)`. Never default to repo
/// `.cache` (Next.js legacy only).
library;

export 'src/dim_armor_csv_import.dart';
export 'src/dim_weapons_csv_import.dart';
export 'src/dim_loadouts/dim_loadouts_reader.dart';
export 'src/fill_in_missing_list_store.dart';
export 'src/optimize_build_store.dart';
export 'src/read_only_file.dart';
export 'src/storage_root.dart';
export 'src/test_temp_path_guard.dart';
export 'src/version_dir.dart';
export 'src/warlock_matrix_path.dart';
export 'src/warlock_matrix_path_setting.dart';
