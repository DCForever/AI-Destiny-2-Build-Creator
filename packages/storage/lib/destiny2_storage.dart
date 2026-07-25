/// StorageRoot abstraction for multiplatform app-support layout (DART-012).
///
/// Windows hosts: resolve `getApplicationSupportDirectory()` via path_provider,
/// then `StorageRoot.windowsAppSupport(support.path)`. Never default to repo
/// `.cache` (Next.js legacy only).
library;

export 'src/storage_root.dart';
export 'src/version_dir.dart';
