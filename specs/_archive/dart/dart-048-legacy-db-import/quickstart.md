# Quickstart: DART-048 Legacy DB Import

## Prerequisites

- Dart SDK (workspace root)
- Optional: Flutter for Windows Settings UX tests

## Run package tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\packages\db
dart test test/legacy_db_import_test.dart
```

## Run Windows host import tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter test test/legacy_db_import_controller_test.dart test/legacy_db_import_card_test.dart
```

## CLI dry-run / apply

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart run tool/legacy_db_import.dart --source path\to\.cache\app.db --target path\to\app_support\app.db
dart run tool/legacy_db_import.dart --source path\to\.cache\app.db --target path\to\app_support\app.db --apply
```

## In-app

Flutter Windows → **Settings** → **Data migration** → **Legacy DB import**.

Full path: [docs/multiplatform-dart-legacy-db-import.md](../../docs/multiplatform-dart-legacy-db-import.md)
