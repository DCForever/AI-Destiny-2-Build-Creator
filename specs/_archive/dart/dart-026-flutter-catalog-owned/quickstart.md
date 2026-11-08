# Quickstart: DART-026 Flutter Catalog Owned

## Verify pure helpers

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/manifest/test/owned_catalog_test.dart
dart test packages/manifest/test/filter_catalog_test.dart
dart test packages/db/test/instance_projection_test.dart
```

## Verify host UI

```powershell
cd apps/windows_host
flutter test test/catalog_owned_page_test.dart test/catalog_page_test.dart
```

## Manual (Windows)

1. Sign in (Public+PKCE) and **Sync now** inventory in Settings.
2. Open Catalog → toggle **Owned** → only owned definition hashes remain.
3. Select a row → instance list shows power / location / instanceId.
4. Toggle **All** → full catalog returns with ownership counts on owned rows.
