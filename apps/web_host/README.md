# destiny2_web_host (DART-042 / DART-043 / DART-044)

Jaspr **client-mode** web shell for the multiplatform Destiny 2 Build Creator port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_web_host` |
| Path | `apps/web_host` |
| Mode | `jaspr.mode: client` (SPA) |
| Routing | `jaspr_router` single-page |
| Tokens | `destiny2_ui_tokens` → CSS custom properties |
| Database | Drift **WASM + OPFS** (DART-043), single-tab writer |
| Entities | **Prebuilt entity bundles** (DART-044) — no raw rebuild in browser |
| Next.js | **Not a dependency** |

## What this host includes

- App shell (header + main)
- Client routes: `/catalog` → offline **Catalog**; `/` and `/settings` → **Settings**
- Matte Flap Ledger design tokens as CSS (from pure package)
- **Local SQLite via Drift WASM** with OPFS when available
- **Single-tab writer lock**: second tab is **blocked** with UX banner
- **Prebuilt entity bundle** at `web/entities/prebuilt/bundle.json` → offline catalog facets
- Unit/component tests

## What is still later

- OAuth PKCE (DART-045)
- Compose / equip UI (DART-046+)
- Owned inventory filter on web (sync later)
- Production CDN channel for large entity bundles (fixture ships in-app)
- `CLIENT_SECRET` / confidential Bungie flow (never in this client)

## Prebuilt entity bundles (DART-044)

Web **does not** download raw Bungie tables or run isolate rebuild. Catalog loads:

```text
GET /entities/prebuilt/bundle.json
```

Parsed by `EntityBundleDocument` → `OfflineCatalog` → pure facet filter. Desktop full refresh remains Windows (DART-018).

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
