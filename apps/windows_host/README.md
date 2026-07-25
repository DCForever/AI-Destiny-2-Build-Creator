# destiny2_windows_host (DART-019…030)

**Flutter Windows** host for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- **Catalog** offline browse from entity stores + **All | Owned** scope after inventory sync (DART-026); instance projections on row select for pickers
- **Sets library** dual-pane (DART-030): create/edit sets via `destiny2_app` use cases; fill slots from catalog/owned picker
- **Settings**:
  - Public+PKCE **OAuth** (loopback; tokens in secure storage — not SQLite)
  - **Inventory sync** card (DART-025): Sync now → full-replace into Drift; busy/error UX; 60s freshness label
  - Manifest status (cached / remote / stale / entity cache)
- Matte Flap Ledger theme stub (DART-029)
- **No CLIENT_SECRET**

## Run

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter pub get
flutter run -d windows `
  --dart-define=BUNGIE_API_KEY=your_public_key `
  --dart-define=BUNGIE_CLIENT_ID=your_public_client_id
# optional: --dart-define=BUNGIE_REDIRECT_URI=http://127.0.0.1:8765/callback
```

Then: Settings → Sign in → **Sync now** → Catalog → **Owned**, or **Sets** → create set → Fill slot.

## Test

```powershell
flutter test
# Sets library slice:
flutter test test/set_slot_mapping_test.dart test/sets_library_page_test.dart
```

## Specs

- `specs/dart-019-flutter-windows-host-skeleton/`
- `specs/dart-020-flutter-catalog-offline/`
- `specs/dart-023-flutter-windows-oauth/`
- `specs/dart-025-flutter-inventory-sync-ui/`
- `specs/dart-026-flutter-catalog-owned/`
- `specs/dart-029-flutter-design-tokens/`
- `specs/dart-030-flutter-sets-library-ui/`
