# destiny2_windows_host (DART-019…039)

**Flutter Windows** host for Destiny 2 Build Creator multiplatform port.

## What it does

- Resolves **StorageRoot** via path_provider application-support (not repo `.cache`)
- Opens a **single** Drift `AppDatabase` at `app.db`
- **Catalog** offline browse from entity stores + **All | Owned** scope after inventory sync (DART-026); instance projections on row select for pickers
- **Sets library** dual-pane (DART-030): create/edit sets via `destiny2_app` use cases; fill slots from catalog/owned picker
- **Armor optimizer workspace** on Sets detail for armor sets (DART-036): goals → **Find kits** (isolate/local optimize, never writes) → suggestions → **explicit confirm** apply-in-place or materialize; soft never auto-applies; never silent apply
- **Synergy library** dual-pane (DART-031): create synergies via `destiny2_app`; designation immutable after create; evidence links add/remove
- **Builds library** dual-pane (DART-032): create builds with class + synergy types + optional exotic/super identity pins via `destiny2_app` `createUserBuild`
- **Variant compose** on Builds detail (DART-033): list/create/select variants; attach/detach library sets; slot pins wishlist vs instance; hard conflicts (e.g. slot overlap) surfaced
- **Soft guidance** on Builds detail (DART-034): coverage chips (supported/weak/missing), soft stat targets with explicit save; **never auto-applies**; display-only soft path (**P3 phase gate**)
- **Equip / Apply** on Builds detail (DART-038): class-filtered character pick; equip-ready gate (wishlist/stale block Apply); empty combat **gaps confirm**; plan + best-effort execute (DART-037); **step report** (completed/failed). Soft never auto-applies. No CLIENT_SECRET.
- **DIM export** on Builds detail (DART-039): **Copy DIM JSON** (jsonOnly `{ loadout }` via pure `buildJsonOnlyDimExport`); clipboard write; **blocked when not equip-ready**. No dim.gg network; soft never auto-applies.
- **Settings**:
  - Public+PKCE **OAuth** (loopback; tokens in secure storage — not SQLite)
  - **Inventory sync** card (DART-025): Sync now → full-replace into Drift; busy/error UX; 60s freshness label
  - Manifest status (cached / remote / stale / entity cache)
- Matte Flap Ledger theme stub (DART-029)
- **No CLIENT_SECRET**

## Run

### Bungie OAuth (required for Sign in)

The Windows host uses **Public + PKCE** and a **loopback** callback. It is **not** the same as the Next.js Confidential app.

| | Next.js (product) | Flutter Windows host |
|--|-------------------|----------------------|
| Client type | **Confidential** | **Public** |
| Redirect | `https://127.0.0.1:3000/api/auth/callback` | `https://127.0.0.1:8765/callback` |
| Secret | `BUNGIE_CLIENT_SECRET` on server | **Never** ship a secret |

1. Create a **second** application at <https://www.bungie.net/en/Application> (or a dedicated Public app).
2. OAuth type: **Public**.
3. Redirect URL: **`https://127.0.0.1:8765/callback`** (exact string — **https**, not http).
4. Use that app’s **Client Id** and API key for `--dart-define` / `.env.windows.local`.
5. Do **not** reuse the Confidential Next redirect (`:3000/api/auth/callback`).
6. First browser visit may warn about a **self-signed certificate** (`certs/loopback-*.pem`). Choose Advanced → continue to 127.0.0.1 (local OAuth only).

### Launch

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter pub get
flutter run -d windows `
  --dart-define=BUNGIE_API_KEY=your_public_api_key `
  --dart-define=BUNGIE_CLIENT_ID=your_public_client_id `
  --dart-define=BUNGIE_REDIRECT_URI=https://127.0.0.1:8765/callback
```

Or fill gitignored `.env.windows.local` and run `.\run-windows.ps1`.

Then: Settings → confirm **Redirect URI** shows `https://127.0.0.1:8765/callback` → Sign in → accept cert warning if prompted → **Sync now** → Catalog / Sets / Synergies / Builds.

### Flutter Driver / agent screenshots (optional)

For [Dart MCP](https://docs.flutter.dev/ai/mcp-server#interact-with-a-running-app) / `/impeccable-flutter` (screenshot, tap, scroll):

**Preferred (agent):** MCP `launch_app` with `target=lib/main_mcp.dart` (enables Driver + returns DTD automatically). Host OAuth keys still load from `.env.windows.local` when present.

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
