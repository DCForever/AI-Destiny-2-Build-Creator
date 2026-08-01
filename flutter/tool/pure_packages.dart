// Shared config for P0 pure-package graph guard and parity suite.
// Keep this list intentional: do not auto-scan every packages/* entry
// (future Drift/Flutter packages must not be treated as pure).

/// Workspace-relative pure package directories (under repo root).
const purePackageDirs = <String>[
  'packages/domain',
  'packages/sandbox_data',
];

/// Exact runtime dependency names that pure packages must not declare.
const forbiddenRuntimeDependenciesExact = <String>{
  'flutter',
  'flutter_localizations',
  'flutter_test',
  'flutter_web_plugins',
  'jaspr',
  'jaspr_flutter_embed',
  'drift',
  'drift_flutter',
  'sqlite3',
  'sqlite3_flutter_libs',
  'sqflite',
  'sqflite_common',
  'sqflite_common_ffi',
  'http',
  'dio',
  'path_provider',
  'path_provider_windows',
  'path_provider_android',
  'path_provider_foundation',
  'path_provider_linux',
  'shared_preferences',
  'url_launcher',
  'file_picker',
  'win32',
  'ffi',
  'shelf',
  'shelf_router',
  'postgres',
  'mysql1',
};

/// Prefixes: any dependency whose name equals the prefix or starts with
/// `prefix` + `_` is forbidden (e.g. `flutter_riverpod`, `jaspr_router`).
const forbiddenRuntimeDependencyPrefixes = <String>[
  'flutter',
  'jaspr',
  'drift',
  'sqflite',
  'path_provider',
  'shared_preferences',
  'url_launcher',
];

/// Returns true if [packageName] is a forbidden pure-package runtime dependency.
bool isForbiddenRuntimeDependency(String packageName) {
  final name = packageName.trim();
  if (name.isEmpty) return false;
  if (forbiddenRuntimeDependenciesExact.contains(name)) return true;
  for (final prefix in forbiddenRuntimeDependencyPrefixes) {
    if (name == prefix || name.startsWith('${prefix}_')) return true;
  }
  return false;
}
