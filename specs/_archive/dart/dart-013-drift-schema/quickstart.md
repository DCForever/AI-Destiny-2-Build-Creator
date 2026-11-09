# Quickstart: DART-013 Drift Schema

## Prerequisites

- Dart SDK ^3.5 (workspace uses 3.11.x)
- From repo root: `F:\Destiny2BuildCreator-multiplatform-dart`

## Resolve & test

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart test packages/db
```

If you edit table definitions, regenerate Drift code:

```powershell
cd packages/db
dart run build_runner build --delete-conflicting-outputs
```

## Open a database

```dart
import 'package:destiny2_db/destiny2_db.dart';

// Tests
final mem = AppDatabase.memory();

// Host (path from StorageRoot.appDbPath — DART-012)
final fileDb = AppDatabase.file(r'C:\fake\app-support\app.db');
// ...
await fileDb.close();
```

## PRAGMA notes (critical)

On open: `foreign_keys = ON`.

Critical uniques: see [data-model.md](./data-model.md) and `packages/db/lib/src/schema_notes.dart`.

## Pure packages

Do **not** add `drift` / `sqlite3` to `destiny2_domain` or `destiny2_sandbox_data`. Graph guard: `dart run tool/pure_package_graph_guard.dart`.
