# Destiny 2 Build Creator

Local-first web app for **assembling and maintaining Destiny 2 builds** on the final **9.7.0 / Edge of Fate** sandbox (Armor 3.0, set bonuses, artifacts, Anti-Champion 2.0).

Primary loop: **intent → compose → equip**.

You designate play-pattern intent (synergy types), compose a class-bound **Build** from reusable **Sets** and **Synergies** (with variants and soft guidance), then equip in-game or export to DIM when pins are owned-instance ready. Soft suggestions never auto-apply; illegal kits and exotic limits hard-block where the game does.

Optional LLM tooling exists for propose-for-confirm discovery and legacy generation paths. It is **not required** for core compose, and is not the primary product surface.

Product framing: [`PRODUCT.md`](./PRODUCT.md). Product descriptions (domains + areas): **Obsidian** ProjectTracker under `Projects/Destiny 2 Build Creator/` — git pointer [`docs/products/`](./docs/products/). Domain rules: [`specs/domain-business-rules.md`](./specs/domain-business-rules.md), [`specs/domain-acceptance-criteria.md`](./specs/domain-acceptance-criteria.md), [`specs/business-rules.md`](./specs/business-rules.md).

**Product map / App Atlas** (UI structure, flows, Draw.io, screenshots, multi-platform stubs): [`docs/product-map/README.md`](./docs/product-map/README.md). Open the unified viewer with `npm run product-map:view`.

## Stack

- **Next.js** (App Router) + React 19 + TypeScript + Tailwind CSS
- **Bungie API** — manifest cache, OAuth, inventory sync, in-game equip
- **SQLite** (Drizzle + better-sqlite3) — builds, sets, synergies, inventory (`.cache/app.db`)
- **DIM** export / optional dim.gg share when configured
- Optional **OpenAI-compatible / Ollama / Grok** LLM and **SearXNG** for advanced/debug flows only
- **vitest** unit tests; `npm run gate` for product-map CI + typecheck + lint + test + build

### Multiplatform Dart port (in progress)

Parallel workstream on `feature/multiplatform-dart` (this worktree). Pure Dart packages and Flutter/Jaspr hosts live under [`flutter/`](./flutter/) (Melos 7+ / pub workspace; see [`flutter/packages/README.md`](./flutter/packages/README.md)). Run Dart commands from `flutter/` (`cd flutter` then `dart pub get`). Domain package has **no** Flutter/Jaspr/IO deps. Slice roadmap: [`docs/multiplatform-dart-slice-roadmap.md`](./docs/multiplatform-dart-slice-roadmap.md).

## Monorepo layout

- `web/NextJS/` — Next.js app (run `cd web/NextJS` or use root `npm run dev` proxy)
- `flutter/` — Dart/Flutter/Jaspr multiplatform workspace
- `docs/`, `specs/` — shared product docs and Spec Kit

## Getting started

```bash
cd web/NextJS
npm install
# or from monorepo root: npm run dev (after npm install in web/NextJS)
cp .env.local.example .env.local   # fill in values — see Environment
npm run dev                        # http://localhost:3000 → redirects to /build
```

### Prerequisites

1. **Bungie API app** (required for manifest, sign-in, inventory, equip):
   - Create at <https://www.bungie.net/en/Application>
   - OAuth type **Confidential**
   - Redirect: `https://127.0.0.1:3000/api/auth/callback`
   - Origin: `https://127.0.0.1:3000`
   - Bungie requires HTTPS and refuses `localhost`. For sign-in use:
     ```bash
     npm run dev:https
     ```
     then open `https://127.0.0.1:3000`.

2. **Session secret** — 32+ character random string in `SESSION_SECRET` (cookie encryption).

3. **First-run data** (in the app):
   1. **Settings** → **Refresh manifest** (needs `BUNGIE_API_KEY`). Builds derived entity stores used by catalog, sets, and composition.
   2. **Sign in with Bungie**, then refresh manifest again (or sync inventory) so owned instances are available for pins, optimizer, and equip.
   3. Start on **Build** (`/build`): create or open a build, attach sets, fill slots, work variants toward equip-ready.

4. **Optional**
   - `DIM_API_KEY` — dim.gg share links (see [DIM API](https://github.com/DestinyItemManager/dim-api#get-an-api-key)).
   - LLM / SearXNG — only if you use optional generation or `/debug/llm-propose`. See [Optional LLM](#optional-llm) below.

### Environment

Copy `.env.local.example` to `.env.local`.

| Variable | Required for | Purpose |
| --- | --- | --- |
| `BUNGIE_API_KEY` | Manifest, API | Bungie application API key |
| `BUNGIE_CLIENT_ID` / `BUNGIE_CLIENT_SECRET` | OAuth | Confidential client credentials |
| `SESSION_SECRET` | Sign-in | iron-session cookie encryption (32+ chars) |
| `DIM_API_KEY` | dim.gg shares | Optional DIM Sync API key |
| `LLM_*` / `OLLAMA_*` / `XAI_API_KEY` / `SEARXNG_URL` | Optional LLM | See [Optional LLM](#optional-llm); not needed for compose |

### SQLite

Builds, sets, synergies, and inventory live in `.cache/app.db`. Preferences may also use `.cache/users/{id}/`.

**Deployment constraint:** single-process local use only (`npm run dev` or `npm start`). Do not run multiple Node workers against the same DB file, and do not deploy to Edge/serverless. If the dev DB corrupts after hot reload, delete `.cache/app.db` and re-sync inventory from Bungie.

## Using the app

Primary nav (production shell):

| Route | Role |
| --- | --- |
| [`/build`](./src/app/build) | **Home.** Compose builds: identity (synergy types, exotic/super pins), variants, set attachments, slot pins, soft guidance, equip / DIM export |
| [`/sets`](./src/app/sets) | Library of Weapon / Armor / Mod / Pair / Fashion sets; slot fill from catalog/owned; armor optimizer paths |
| [`/synergy`](./src/app/synergy) | Curated Type+Object synergies with evidence links; reusable play-pattern library |
| [`/catalog`](./src/app/catalog) | Multi-facet browse (all / owned) as a composition aid for filling sets and slots |
| [`/loadouts`](./src/app/loadouts) | In-game / legacy loadout list surfaces |
| [`/settings`](./src/app/settings) | Manifest refresh, Bungie auth, inventory sync, preferences |

`/` redirects to `/build`. **Analyze** (`/analyze`) remains available as an adjacent tool; it is not the primary compose job.

Typical session:

1. Refresh manifest (and sign in + inventory when you need owned pins).
2. Optionally curate **Synergies** and **Sets**, or create them in-flow from Build.
3. On **Build**, set class-bound identity and designated synergy types, attach sets, pin instances, review soft coverage/stat guidance.
4. When the active variant is equip-ready, equip via Bungie or export to DIM.

Soft guidance and optimizer suggestions are **suggest-then-confirm** — nothing mutates silently.

Operator / API verification UI lives under **`/debug/*`** (non-production, signed-in). See **[DEBUG.md](./DEBUG.md)**.

## Scripts

| Script | Purpose |
| --- | --- |
| `npm run dev` | Dev server (HTTP) |
| `npm run dev:https` | Dev server with local HTTPS (Bungie OAuth) |
| `npm run typecheck` | TypeScript check, no emit |
| `npm run test` | Vitest unit tests |
| `npm run lint` | ESLint |
| `npm run build` | Production build |
| `npm run start` | Production server |
| `npm run gate` | Quality gate: **product-map:ci** → typecheck → lint → test → build (`scripts/gate.mjs`) |
| `npm run gate:bash` | Same sequence via `scripts/gate.sh` (Unix / Git Bash) |

### Product map / Atlas / Draw.io

Structure lives under [`docs/product-map/`](./docs/product-map/) (surfaces, flows, platforms). Rule **wording** stays in `specs/`. Full guide: [product-map README](./docs/product-map/README.md).

| Script | Purpose |
| --- | --- |
| `npm run product-map:view` | Unified viewer (Flows · Screens · Map · Rules · Export) at http://127.0.0.1:4174 |
| `npm run ui-rules:view` | Same as `product-map:view` |
| `npm run product-map:sync` | Validate hub → generate Draw.io / Atlas paths / inventory projection → drift check |
| `npm run product-map:ci` | CI bundle: generate, dirty-check committed outputs, orphan-rules report, Flutter parity |
| `npm run product-map:check` | Route coverage / missing surface refs (warnings; errors fail) |
| `npm run product-map:check-dirty` | Fail if hub generate would change committed projections |
| `npm run product-map:orphan-rules` | List DBR/DAC/BR not attached on any surface/flow |
| `npm run product-map:add-surface` / `add-flow` | Scaffold hub entries |
| `npm run product-map:seed-flutter` / `parity` | Flutter Windows stubs + parity report |
| `npm run atlas:view` | Atlas-only screenshot/journey UI at http://127.0.0.1:4173 |
| `npm run atlas:capture` | Playwright captures into `docs/atlas/screenshots/` (see [Atlas README](./docs/atlas/README.md)) |

After hub edits, run `product-map:sync` and **commit hub + generated files** together (`ui-map.drawio`, `inventory.yaml`, Atlas manifest/links). Escape hatch: `GATE_SKIP_PRODUCT_MAP=1 npm run gate`.

GitHub Actions (`.github/workflows/ci.yml`) runs **product-map:ci** then typecheck, lint, test, build on PRs and pushes to `main`/`master` (Node 22, `npm ci`). Requires Node `>=20 <25` (`package.json` `engines`).

## Project layout

- `src/app/` — routes: `build`, `sets`, `synergy`, `catalog`, `loadouts`, `analyze`, `settings`, `debug/*`, and API routes
- `src/components/` — production UI (build, sets, synergy, catalog, sheet, Matte Flap Ledger primitives under `ui/`)
- `src/lib/builds/`, `sets/`, `synergies/` — domain services for composition and libraries
- `src/lib/manifest/` — manifest download/cache, extractors, resolution
- `src/lib/bungie/` — OAuth, session, profile, inventory sync, equip
- `src/lib/catalog/`, `inventory/`, `optimizer/`, `dim/` — browse, owned instances, armor optimizer, export
- `src/lib/db/` — SQLite schema and repositories
- `src/lib/llm/` — optional generation / propose pipelines (not the primary path)
- `src/data/` — meta pack, sandbox rule tables, synergy vocabulary
- `specs/` — domain rules (`DBR-*` / `DAC-*` / `BR-*`) and feature slices `00N-*`
- `docs/product-map/` — **UI structure SSoT** (surfaces, flows, platforms); checklist + Flutter parity
- `docs/ui-rules/` — generated Draw.io + inventory projection; unified companion server
- `docs/atlas/` — screenshot captures, Atlas viewer, generated manifest/links
- `scripts/product-map/`, `scripts/ui-rules/` — map generate, hub write, rule parse/write-back
- `PRODUCT.md`, `DEBUG.md`, `DESIGN.md`, `docs/` — product and operator docs

## Optional LLM

LLM is **optional**. Core Build / Sets / Synergy / Catalog work without a model.

When configured (see `.env.local.example`):

- OpenAI-compatible local servers (LM Studio, vLLM, …), Ollama, or Grok (xAI) with optional local fallback
- Optional multi-pass generation (`LLM_MULTI_PASS_ENABLED`) — experimental
- Optional SearXNG for live meta search
- Propose-for-confirm synergy/evidence flows under debug (e.g. `/debug/llm-propose`) — **nothing becomes canonical without user confirmation**

Generator-style multi-pass LLM is **not** restored as a primary nav tab. Prefer compose surfaces for day-to-day work; use LLM only when you want assisted discovery.

## Related docs

| Doc | Contents |
| --- | --- |
| [`PRODUCT.md`](./PRODUCT.md) | Purpose, positioning, capabilities, constraints |
| [`docs/product-map/README.md`](./docs/product-map/README.md) | Product map hub, viewer, sync, CI |
| [`docs/product-map/CHECKLIST.md`](./docs/product-map/CHECKLIST.md) | Same-change checklist for UI work |
| [`docs/product-map/FLUTTER.md`](./docs/product-map/FLUTTER.md) | Flutter Windows platform stubs / parity |
| [`docs/ui-rules/README.md`](./docs/ui-rules/README.md) | Draw.io + companion (projections of the hub) |
| [`docs/atlas/README.md`](./docs/atlas/README.md) | Screenshot capture and Atlas-only browse |
| [`DEBUG.md`](./DEBUG.md) | `/debug/*` setup and API verification flows |
| [`DESIGN.md`](./DESIGN.md) | Design notes |
| [`AGENTS.md`](./AGENTS.md) | Monorepo agent rules (domain + product-map); points at stack guides |
| [`web/NextJS/AGENTS.md`](./web/NextJS/AGENTS.md) | Next.js app agent rules |
| [`flutter/AGENTS.md`](./flutter/AGENTS.md) | Dart / Flutter / Jaspr agent rules |
| [`specs/`](./specs/) | Domain and feature specifications |
