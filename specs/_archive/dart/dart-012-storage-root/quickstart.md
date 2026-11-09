# Quickstart: DART-012 Storage Root

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
```

## Run storage tests

```powershell
dart test packages/storage
```

## Construct StorageRoot (Windows host pattern)

Flutter Windows (later DART-019) resolves the base via **path_provider**, then builds StorageRoot:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

Future<StorageRoot> openWindowsStorageRoot() async {
  final support = await getApplicationSupportDirectory();
  final root = StorageRoot.windowsAppSupport(support.path);
  await root.ensureLayout();
  return root;
}
```

**Do not** use `Directory.current` / repo `.cache` for Dart shells. That layout is Next.js legacy only (`src/lib/manifest/cachePaths.ts`).

## Layout (under StorageRoot.basePath)

| Path | Purpose |
| ---- | ------- |
| `app.db` | Primary SQLite database (Drift later) |
| `current-version.json` | Active manifest version pointer |
| `manifest/<versionDir>/<table>.json` | Raw Bungie tables |
| `entities/<versionDir>/<store>.json` | Derived entity stores |
| `entities/<versionDir>/meta.json` | Entity cache meta |
| `entities/<versionDir>/perk-weapon-index.json` | Perk–weapon index |
| `users/<membershipId>/preferences.json` | Per-user preferences |

`versionDir` = sanitized manifest version (`[^A-Za-z0-9._-]+` → `_`).

## Tests / fake FS

```dart
final root = StorageRoot(basePath: r'C:\fake\app-support');
expect(root.appDbPath, endsWith('app.db'));
```

## Pure packages

`destiny2_domain` / `destiny2_sandbox_data` must **not** depend on `destiny2_storage` or `path_provider`. P0 gate:

```powershell
dart run tool/p0_parity_gate.dart
```
