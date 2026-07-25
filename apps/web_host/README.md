# destiny2_web_host (DART-042 – DART-046)

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
| Compose | Builds / Sets / Synergies + hard/soft parity (DART-046) |
| Next.js | **Not a dependency** |

## What this host includes

- App shell (header + main)
- Client routes:
  - `/catalog` → offline **Catalog**
  - `/builds`, `/builds/:buildId` → **Builds** list + linear compose
  - `/sets` → **Sets** library
  - `/synergies` → **Synergies** library
  - `/` and `/settings` → **Settings** (DB status + Bungie account)
  - `/auth/callback` → OAuth PKCE callback
- Matte Flap Ledger design tokens as CSS (from pure package)
- **Local SQLite via Drift WASM** with OPFS when available
- **Single-tab writer lock**: second tab is **blocked** with UX banner; compose requires writer
- **Prebuilt entity bundle** at `web/entities/prebuilt/bundle.json` → offline catalog facets
- **Browser Public+PKCE** sign-in / sign-out (DART-045)
- **Compose spine** via `destiny2_app` use cases (DART-046)
- Unit/component tests

## What is still later

- Equip-ready / DIM / equip on web (DART-047)
- Owned inventory filter on web (sync later)
- Optimizer on web
- Production CDN channel for large entity bundles (fixture ships in-app)
- Confidential Bungie flow (never in this client)

## Compose spine (DART-046)

In-process library + compose against the **writer** `AppDatabase`:

1. **Sets** → create set → fill slot (hash/name)
2. **Synergies** → create designation (+ optional evidence link)
3. **Builds** → create with class + ≥1 synergy type → open compose
4. Create **non-default** variant → **attach** set → pins (wishlist/instance)
5. **Soft guidance** chips + soft stat targets (explicit save only)

Hard DBR gates stay hard. Soft never auto-applies and does not block legal attach.

```powershell
cd apps\web_host
dart test
```

See `specs/dart-046-jaspr-compose-spine/quickstart.md`.

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
