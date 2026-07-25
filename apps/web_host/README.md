# destiny2_web_host (DART-042)

Jaspr **client-mode** web shell for the multiplatform Destiny 2 Build Creator port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_web_host` |
| Path | `apps/web_host` |
| Mode | `jaspr.mode: client` (SPA) |
| Routing | `jaspr_router` single-page |
| Tokens | `destiny2_ui_tokens` → CSS custom properties |
| Next.js | **Not a dependency** |

## What this slice includes

- App shell (header + main)
- Client routes: `/` and `/settings` → **Hello Settings** page
- Matte Flap Ledger design tokens as CSS (from pure package)
- Unit/component tests

## What this slice excludes

- OPFS / Drift WASM (DART-043)
- Entity bundles (DART-044)
- OAuth PKCE (DART-045)
- Compose / equip UI (DART-046+)
- `CLIENT_SECRET` / confidential Bungie flow

## Develop

```powershell
dart pub global activate jaspr_cli
cd apps\web_host
dart pub get
jaspr serve
```

Open `http://localhost:8080` — Settings with **Hello** greeting.

## Test

```powershell
cd apps\web_host
dart test
```

## Architecture

See [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (Jaspr for web, not Flutter Web; pure Dart I/O).
