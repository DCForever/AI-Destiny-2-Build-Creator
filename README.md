# Destiny 2 Build Creator

Local-first web app for **assembling and maintaining Destiny 2 builds** on the final **9.7.0 / Edge of Fate** sandbox (Armor 3.0, set bonuses, artifacts, Anti-Champion 2.0).

Primary loop: **intent → compose → equip**.

You designate play-pattern intent (synergy types), compose a class-bound **Build** from reusable **Sets** and **Synergies** (with variants and soft guidance), then equip in-game or export to DIM when pins are owned-instance ready. Soft suggestions never auto-apply; illegal kits and exotic limits hard-block where the game does.

Optional LLM tooling exists for propose-for-confirm discovery and legacy generation paths. It is **not required** for core compose, and is not the primary product surface.

Product framing: [`PRODUCT.md`](./PRODUCT.md). Domain rules: [`specs/domain-business-rules.md`](./specs/domain-business-rules.md), [`specs/domain-acceptance-criteria.md`](./specs/domain-acceptance-criteria.md), [`specs/business-rules.md`](./specs/business-rules.md).

## Stack

- **Next.js** (App Router) + React 19 + TypeScript + Tailwind CSS
- **Bungie API** — manifest cache, OAuth, inventory sync, in-game equip
- **SQLite** (Drizzle + better-sqlite3) — builds, sets, synergies, inventory (`.cache/app.db`)
- **DIM** export / optional dim.gg share when configured
- Optional **OpenAI-compatible / Ollama / Grok** LLM and **SearXNG** for advanced/debug flows only
- **vitest** unit tests; `npm run gate` for typecheck + lint + test + build

## Getting started

```bash
npm install
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
| `npm run gate` | typecheck + lint + test + build |

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
| [`DEBUG.md`](./DEBUG.md) | `/debug/*` setup and API verification flows |
| [`DESIGN.md`](./DESIGN.md) | Design notes |
| [`AGENTS.md`](./AGENTS.md) | Agent / Spec Kit domain doc rules |
| [`specs/`](./specs/) | Domain and feature specifications |
