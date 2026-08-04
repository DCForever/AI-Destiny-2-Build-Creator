# destiny2_windows_host (DART-019…039)

**Flutter Windows** host for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- **Shell (UX rebuild):** **Catalog** + **Settings** in the nav. Loadouts, Build, Synergy, and Sets return area-by-area via the redesign workflows (`area-ux-redesign` → `area-implement`). See monorepo `docs/ux-redesign/README.md`.
- **Settings** (active production surface):
  - Public+PKCE **OAuth** (loopback; tokens in secure storage — not SQLite)
  - **Inventory sync** card: Sync now → full-replace into Drift; busy/error UX; 60s freshness label
  - Manifest status (cached / remote / stale / entity cache)
  - Theme (Neon void / Cool technical)
- Design system: `destiny2_ui_tokens` + `destiny2_ui_flutter` (unchanged during strip)
- Legacy area page code may still exist under `lib/` for rebuild reference / direct page tests; it is **not** mounted in the shell
- **No CLIENT_SECRET**

## Run

### Bungie OAuth (required for Sign in)

The Windows host uses **Public + PKCE** and a **loopback** callback. It is **not** the same as the Next.js Confidential app.

| | Next.js (product) | Flutter Windows host |
|--|-------------------|----------------------|
| Client type | **Confidential** | **Public** |
| Redirect | `https://127.0.0.1:3000/api/auth/callback` | `https://127.0.0.1:8765/callback` |
| Secret | `BUNGIE_CLIENT_SECRET` on server | **Never** ship a secret |
| Refresh token | Yes (~90 days) — DIM-like multi-day session | **No** (Bungie Public policy) — live access ~1h |
| After access expires | Silent refresh | Re-sign-in for **Sync / live API** only; **Catalog Owned uses local DB** |

**Why not like DIM?** DIM uses a **Confidential** Bungie app (server-held secret + refresh). This host is Public+PKCE by design (no secret on device). That is not a mapping bug — Bungie docs state Public clients do not receive `refresh_token`.

**Potential switch to Confidential desktop:** implications (secret risk, gates, UX) and Flutter implementation options (operator env secret vs local helper vs BFF) are recorded in monorepo [`docs/flutter-confidential-desktop-oauth-note.md`](../../../docs/flutter-confidential-desktop-oauth-note.md). Not the default path; ADR required before shipping.

1. Create a **second** application at <https://www.bungie.net/en/Application> (or a dedicated Public app).
2. OAuth type: **Public**.
3. Redirect URL: **`https://127.0.0.1:8765/callback`** (exact string — **https**, not http).
4. Use that app’s **Client Id** and API key for `--dart-define` / `.env.windows.local`.
5. Do **not** reuse the Confidential Next redirect (`:3000/api/auth/callback`).
6. First browser visit may warn about a **self-signed certificate** (`certs/loopback-*.pem`). Choose Advanced → continue to 127.0.0.1 (local OAuth only).
7. `.\run-windows.ps1` auto-generates missing `certs/loopback-cert.pem` + `loopback-key.pem` via `openssl` + `certs/loopback.cnf` (Git for Windows openssl is fine). The private key is gitignored.

### Launch

```powershell
cd F:\Destiny2BuildCreator\flutter\apps\windows_host
flutter pub get
flutter run -d windows `
  --dart-define=BUNGIE_API_KEY=your_public_api_key `
  --dart-define=BUNGIE_CLIENT_ID=your_public_client_id `
  --dart-define=BUNGIE_REDIRECT_URI=https://127.0.0.1:8765/callback
```

Or fill gitignored `.env.windows.local` (Public app client id + API key; **no** secret required) and run `.\run-windows.ps1`.

Then: **Catalog** (weapons) or Settings → confirm **Redirect URI** shows `https://127.0.0.1:8765/callback` → Sign in → accept cert warning if prompted → **Sync now**.

### Windows path length (worktrees)

Deep paths under `.grok/worktrees/...` can break MSBuild for plugins (e.g. `flutter_secure_storage_windows` `MSB3491` / missing `.tlog`). Prefer a **short junction** to the Melos root:

```powershell
# One-time (admin not required for junction)
cmd /c mklink /J C:\d2f C:\Users\Owner\.grok\worktrees\destiny2buildcreator\flutter-ui-rebuild-2\flutter
cd C:\d2f\apps\windows_host
flutter clean
cd C:\d2f
dart pub get
cd C:\d2f\apps\windows_host
flutter run -d windows
# or: flutter build windows --debug
```

Building from the long worktree path may fail even when `dart analyze` / `flutter test` pass.

### Flutter Driver / agent screenshots (required for area-implement Verify)

Used by [Dart MCP](https://docs.flutter.dev/ai/mcp-server#interact-with-a-running-app), `/impeccable-flutter`, and **`area-implement` Capture** so implementation PNGs land beside mockups under `docs/ux-redesign/<area>/implementation-shots/`.

**Preferred (agent):** MCP `launch_app` with `target=lib/main_mcp.dart` (enables Driver + returns DTD automatically). Then `flutter_driver` · `screenshot` per scenario. Host OAuth keys still load from `.env.windows.local` when present.

**Manual shell:**

```powershell
.\run-windows.ps1 -EnableFlutterDriver
# or:
flutter run -d windows `
  --dart-define=ENABLE_FLUTTER_DRIVER=true `
  --dart-define=BUNGIE_API_KEY=... `
  --dart-define=BUNGIE_CLIENT_ID=...
```

- Everyday entrypoint: `lib/main.dart` (driver **off** unless `ENABLE_FLUTTER_DRIVER=true`).
- Agent entrypoint: `lib/main_mcp.dart` (driver **on**).
- When driver is on, real keyboard typing may be emulated — automation only, not everyday play.

## Test

```powershell
flutter test
# Sets library slice:
flutter test test/set_slot_mapping_test.dart test/sets_library_page_test.dart
# Synergy library slice:
flutter test test/synergy_designation_test.dart test/synergies_library_page_test.dart
# Builds identity + variant compose + soft guidance:
flutter test test/build_identity_format_test.dart test/builds_library_page_test.dart
flutter test test/variant_compose_format_test.dart test/variant_compose_page_test.dart
flutter test test/soft_guidance_format_test.dart test/soft_guidance_page_test.dart
# Armor optimizer workspace (DART-036):
flutter test test/optimizer_format_test.dart test/optimizer_workspace_test.dart
# Equip UI (DART-038):
flutter test test/equip_format_test.dart test/equip_panel_test.dart
# DIM export UI (DART-039):
flutter test test/dim_export_format_test.dart test/dim_export_panel_test.dart
```

## Specs

- `specs/dart-019-flutter-windows-host-skeleton/`
- `specs/dart-020-flutter-catalog-offline/`
- `specs/dart-023-flutter-windows-oauth/`
- `specs/dart-025-flutter-inventory-sync-ui/`
- `specs/dart-026-flutter-catalog-owned/`
- `specs/dart-029-flutter-design-tokens/`
- `specs/dart-030-flutter-sets-library-ui/`
- `specs/dart-031-flutter-synergy-library-ui/`
- `specs/dart-032-flutter-build-identity-ui/`
- `specs/dart-033-flutter-variant-compose-ui/`
- `specs/dart-034-flutter-soft-guidance-ui/`
- `specs/dart-036-flutter-optimizer-ui/`
- `specs/dart-038-flutter-equip-ui/`
- `specs/dart-039-flutter-dim-export-ui/`
