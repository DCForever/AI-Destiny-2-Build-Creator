# Quickstart: DART-014 Drift Migrations

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/db
```

## Open a DB (greenfield)

```dart
import 'package:destiny2_db/destiny2_db.dart';

final db = AppDatabase.memory();
// onCreate createAll + beforeOpen FK + ensure upgrades
final tables = await db.listUserTableNames();
await db.close();
```

## Version table

```dart
import 'package:destiny2_db/destiny2_db.dart';

print(driftSchemaVersionCurrent); // 1
for (final step in ensureStepCatalog) {
  print('${step.id} ← ${step.productFunction}');
}
```

## Manual ensure (import prep)

`applyEnsureUpgrades` is invoked from `beforeOpen`. For tests or tooling, call it with an executor that talks to the same SQLite handle.

## Product parity source

`src/lib/db/client.ts` — `runMigrations` + `ensure*` functions.
