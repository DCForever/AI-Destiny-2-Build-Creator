# destiny2_mobile_host (DART-040 / DART-041 / DART-057)

**Flutter Android + iOS** shell for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- **Bottom navigation**: Builds | Settings (published surface matrix DART-057)
- **Focus Swap** (DESIGN.md): Builds list XOR detail route (nested navigator — not dual-pane)
- **Create build** via bottom sheet (FAB); optional name + class + synergy type
- **Linear compose** on detail: variants → attach set sheet → slot pins → soft guidance → finish-gap display
- Shared `destiny2_app` use cases (`createUserBuild`, attach, `queryVariantCoverage`, …)
- **Settings**: storage/DB path + manifest status + **mobile surface matrix**
- Matte Flap Ledger theme (`destiny2_ui_tokens`)
- **No CLIENT_SECRET**; soft guidance never auto-applies
- Mobile OAuth / catalog / equip / DIM: **N/A** (product matrix; use Windows/Jaspr)
- Optimizer: **deferred** (GAP-FEAT-01)

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
