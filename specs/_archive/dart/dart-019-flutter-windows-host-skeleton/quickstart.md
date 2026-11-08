# Quickstart: DART-019 Flutter Windows Host Skeleton

## Bootstrap monorepo

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
cd apps/windows_host
flutter pub get
```

## Run Windows host

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter run -d windows
# optional public API key for remote version check:
# flutter run -d windows --dart-define=BUNGIE_API_KEY=your_key
```

Storage lives under the Flutter application-support directory (path_provider), not repo `.cache`.

## Tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter test
```

## Build (smoke)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter build windows --debug
```

## What you should see

- Window opens to a **Settings** stub.
- Manifest status: cached version, remote version, stale flag, entity-cache note.
- No OAuth / sign-in.
- Single SQLite DB at `<app support>/app.db`.

## Related packages

| Package | Role |
| ------- | ---- |
| `destiny2_storage` | StorageRoot paths |
| `destiny2_db` | Drift AppDatabase |
| `destiny2_manifest` | WindowsManifestRefresh status |
