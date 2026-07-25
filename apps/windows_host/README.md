# destiny2_windows_host (DART-019…025)

**Flutter Windows** host for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- **Catalog** offline browse from entity stores
- **Settings**:
  - Public+PKCE **OAuth** (loopback; tokens in secure storage — not SQLite)
  - **Inventory sync** card (DART-025): Sync now → full-replace into Drift; busy/error UX; 60s freshness label
  - Manifest status (cached / remote / stale / entity cache)
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

Then: Settings → Sign in → **Sync now**.

## Test

```powershell
flutter test
```

## Specs

- `specs/dart-019-flutter-windows-host-skeleton/`
- `specs/dart-023-flutter-windows-oauth/`
- `specs/dart-025-flutter-inventory-sync-ui/`
