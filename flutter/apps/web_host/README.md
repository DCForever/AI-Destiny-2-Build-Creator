# destiny2_web_host (DART-042 – DART-047)

Jaspr **client-mode** web shell for the multiplatform Destiny 2 Build Creator port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_web_host` |
| Path | `apps/web_host` |
| Mode | `jaspr.mode: client` (SPA) |
| Routing | `jaspr_router` single-page |
| Tokens | `destiny2_ui_tokens` → CSS custom properties |
| Database | Drift **WASM + OPFS** (DART-043), single-tab writer |
| Entities | **Hybrid entity channel** (DART-059) — ship-in-app prod + optional CDN; no raw rebuild |
| Auth | **Public + PKCE** (DART-045) — no `CLIENT_SECRET` |
| Compose | Builds / Sets / Synergies + hard/soft parity (DART-046) |
| Equip / DIM | Equip-ready + DIM jsonOnly + optional equip (DART-047) |
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
- **Production entity channel** at `web/entities/channel.json` + `web/entities/prod/bundle.json` → offline catalog facets (legacy demo: `prebuilt/bundle.json`)
- **Browser Public+PKCE** sign-in / sign-out (DART-045)
- **Compose spine** via `destiny2_app` use cases (DART-046)
- **Equip-ready** status + pin gaps; **Copy DIM JSON** (jsonOnly, equip-ready gated); **optional equip** Apply + step report (DART-047)
- Unit/component tests

## What is still later

- Owned inventory filter / full inventory sync UI on web
- dim.gg share
- Optimizer on web
- Full-size Destiny catalog extract (operators replace sample `prod/bundle.json`; channel schema fixed in DART-059)
- Confidential Bungie flow (never in this client)

## Compose spine (DART-046)

In-process library + compose against the **writer** `AppDatabase`:

1. **Sets** → create set → fill slot (hash/name)
2. **Synergies** → create designation (+ optional evidence link)
3. **Builds** → create with class + ≥1 synergy type → open compose
4. Create **non-default** variant → **attach** set → pins (wishlist/instance)
5. **Soft guidance** chips + soft stat targets (explicit save only)

Hard DBR gates stay hard. Soft never auto-applies and does not block legal attach.

## Equip + DIM (DART-047)

On Build compose when a variant is selected:

1. **Equip-ready** from domain `computeEquipReady` + local inventory pins
2. **Copy DIM JSON** → pure `buildJsonOnlyDimExport` → clipboard (blocked when not equip-ready)
3. **Optional equip** (signed-in + public API key): character pick → gaps confirm → `planEquipSteps` / `executeEquipPlan`

Same domain packages as Flutter. Soft never auto-applies. No `CLIENT_SECRET`. No dim.gg.

```powershell
cd apps\web_host
dart test
dart test test/equip_controller_test.dart test/dim_export_controller_test.dart
```

See `specs/dart-047-jaspr-equip-export/quickstart.md`.

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
