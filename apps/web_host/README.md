# destiny2_web_host (DART-042 / DART-043)

Jaspr **client-mode** web shell for the multiplatform Destiny 2 Build Creator port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_web_host` |
| Path | `apps/web_host` |
| Mode | `jaspr.mode: client` (SPA) |
| Routing | `jaspr_router` single-page |
| Tokens | `destiny2_ui_tokens` → CSS custom properties |
| Database | Drift **WASM + OPFS** (DART-043), single-tab writer |
| Next.js | **Not a dependency** |

## What this host includes

- App shell (header + main)
- Client routes: `/` and `/settings` → **Settings** page
- Matte Flap Ledger design tokens as CSS (from pure package)
- **Local SQLite via Drift WASM** with OPFS when available
- **Single-tab writer lock**: second tab is **blocked** with UX banner
- Unit/component tests

## What is still later

- Entity bundles (DART-044)
- OAuth PKCE (DART-045)
- Compose / equip UI (DART-046+)
- `CLIENT_SECRET` / confidential Bungie flow (never in this client)

## Web DB assets

```powershell
cd apps\web_host
powershell -File tool\fetch_drift_web_assets.ps1
```

Downloads `web/sqlite3.wasm` and `web/drift_worker.js`.

## Develop

```powershell
dart pub global activate jaspr_cli
cd apps\web_host
dart pub get
powershell -File tool\fetch_drift_web_assets.ps1
jaspr serve
```

Open `http://localhost:8080` — Settings with **Hello** + database role.

Open a **second tab** → blocked writer banner.

Optional COOP/COEP for best OPFS path — see [docs/multiplatform-dart-web-opfs-limits.md](../../docs/multiplatform-dart-web-opfs-limits.md).

## Test

```powershell
cd apps\web_host
dart test
```

## Architecture

See [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (Jaspr for web, not Flutter Web; pure Dart I/O; D-WEB-DB OPFS single-writer).
