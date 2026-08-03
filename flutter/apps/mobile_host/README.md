# destiny2_mobile_host (DART-040 / DART-041 / DART-057)

**Flutter Android + iOS** shell for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- **Shell (UX rebuild baseline):** **Settings only** (full body). No bottom nav until a second area lands (Material `NavigationBar` requires ≥2 destinations). Builds, Catalog, and other areas return via the redesign workflows (`docs/ux-redesign/README.md`)
- **Settings**: storage/DB path + manifest status + **mobile surface matrix** (areas marked deferred during rebuild)
- Design system: Neon void / Cool technical via `destiny2_ui_tokens` / `destiny2_ui_flutter`
- Legacy Builds page code may remain under `lib/builds/` for rebuild reference / page-level tests; not mounted in shell
- **No CLIENT_SECRET**

## Run

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\mobile_host
flutter pub get
flutter run -d <android-device>
```

## Test

```powershell
flutter test
```

## Debug installable build (Android)

```powershell
flutter build apk --debug
# artifact: build/app/outputs/flutter-apk/app-debug.apk
```

iOS project lives under `ios/` (codesigned install requires macOS/Xcode).

## Specs

- `specs/dart-040-flutter-mobile-shell-nav/`
- `specs/dart-041-flutter-mobile-compose/`
- `specs/dart-057-mobile-compose-equip-polish/`
