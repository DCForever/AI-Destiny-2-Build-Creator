# destiny2_windows_host (DART-019)

Minimal **Flutter Windows** host for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- Shows a **Settings** stub with **manifest status only** (cached / remote / stale / entity cache)
- **No OAuth**, no CLIENT_SECRET, no inventory sync UI

## Run

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter pub get
flutter run -d windows
# optional:
# flutter run -d windows --dart-define=BUNGIE_API_KEY=your_public_key
```

## Test

```powershell
flutter test
```

## Spec

`specs/dart-019-flutter-windows-host-skeleton/`
