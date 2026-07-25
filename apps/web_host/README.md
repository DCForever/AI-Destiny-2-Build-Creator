# destiny2_web_host (DART-042 – DART-045)

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
| Auth | **Public + PKCE** (DART-045) — no `CLIENT_SECRET` |
| Next.js | **Not a dependency** |

## What this host includes

- App shell (header + main)
- Client routes:
  - `/catalog` → offline **Catalog**
  - `/` and `/settings` → **Settings** (DB status + Bungie account)
  - `/auth/callback` → OAuth PKCE callback
- Matte Flap Ledger design tokens as CSS (from pure package)
- **Local SQLite via Drift WASM** with OPFS when available
- **Single-tab writer lock**: second tab is **blocked** with UX banner
- **Prebuilt entity bundle** at `web/entities/prebuilt/bundle.json` → offline catalog facets
- **Browser Public+PKCE** sign-in / sign-out (DART-045)
- Unit/component tests

## What is still later

- Compose / equip UI (DART-046+)
- Owned inventory filter on web (sync later)
- Production CDN channel for large entity bundles (fixture ships in-app)
- Confidential Bungie flow (never in this client)

## OAuth (DART-045)

Uses `destiny2_bungie` Public+PKCE only (DART-022). **Never** embed `BUNGIE_CLIENT_SECRET` or `SESSION_SECRET`.

| Concern | Strategy |
| ------- | -------- |
| Authorize / token | `BungieOAuthClient` + PKCE S256 |
| Redirect URI | `{origin}/auth/callback` (or `BUNGIE_REDIRECT_URI`) |
| Access / refresh tokens | Origin-scoped **`localStorage`** (not SQLite) |
| Pending PKCE verifier | **`sessionStorage`** for the redirect only |
| Config | `--dart-define=BUNGIE_CLIENT_ID=...` (public id) |

Register the HTTPS loopback or production callback on a Bungie **Public** application, e.g.:

- `https://127.0.0.1:8080/auth/callback`
- `https://your.production.origin/auth/callback`

```powershell
cd apps\web_host
jaspr serve --dart-define=BUNGIE_CLIENT_ID=your_public_client_id
```

Settings → **Sign in** → Bungie consent → `/auth/callback` → Settings signed-in.

See `specs/dart-045-jaspr-oauth-pkce/quickstart.md`.

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

Open the app origin — Settings with **Hello** + database role + account card.

Open a **second tab** → blocked writer banner.

Optional COOP/COEP for best OPFS path — see [docs/multiplatform-dart-web-opfs-limits.md](../../docs/multiplatform-dart-web-opfs-limits.md).

## Test

```powershell
cd apps\web_host
dart test
```

## Architecture

See [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (Jaspr for web, not Flutter Web; pure Dart I/O; D-WEB-AUTH Public+PKCE; D-WEB-DB OPFS single-writer).
