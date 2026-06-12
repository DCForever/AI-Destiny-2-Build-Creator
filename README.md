# Destiny 2 Build Creator

A local-first web app that generates and analyzes Destiny 2 builds. A local LLM
(Gemma 4 via Ollama) researches and composes the build using tool calls against
the real Bungie manifest plus optional web search (SearXNG); the app then
validates every item, perk, and stat against manifest data before rendering a
build sheet with DIM exports.

Built against the **Update 9.7.0 "Monument of Triumph"** (June 9, 2026) sandbox:
Anti-Champion 2.0, Armor 3.0 (12 archetypes, 0-200 stats with enhanced benefits
past 100), Artifacts 2.0 (seven permanent artifacts), and the final ability
economy.

## Stack

- Next.js (App Router) + TypeScript strict + Tailwind CSS
- Ollama native `/api/chat` (two-phase: tool-call research loop, then
  JSON-schema-constrained composition)
- Bungie API manifest (versioned disk cache, derived entity stores) and
  optional OAuth sign-in for character import
- zod (LLM output validation), fuse.js (fuzzy name resolution), iron-session
  (encrypted session cookie), vitest (unit tests)

## Getting started

```bash
npm install
cp .env.local.example .env.local   # fill in values, see below
npm run dev                        # http://localhost:3000
```

### Prerequisites

1. **Ollama** with a tool-capable model pulled, e.g. `ollama pull gemma4`
   (12B+ recommended for build quality).
2. **SearXNG** (optional, for live meta checks):
   `docker run -d -p 8888:8080 searxng/searxng`, then enable the JSON output
   format in its `settings.yml` (`search.formats: [html, json]`). Without it,
   the built-in curated meta pack covers meta questions.
3. **Bungie API app** (only needed for character import / analyzer sign-in):
   create one at <https://www.bungie.net/en/Application> with OAuth type
   *Confidential*, redirect `https://127.0.0.1:3000/api/auth/callback`, origin
   `https://127.0.0.1:3000`. Bungie requires HTTPS and refuses `localhost`, so
   use `npm run dev:https` and open `https://127.0.0.1:3000` when signing in.

### Environment

Copy `.env.local.example` to `.env.local`. All variables are optional except
when using the corresponding feature (Bungie keys for sign-in, `SESSION_SECRET`
for sessions).

## Scripts

| Script              | Purpose                                  |
| ------------------- | ---------------------------------------- |
| `npm run dev`       | Dev server (HTTP)                        |
| `npm run dev:https` | Dev server with local HTTPS (for OAuth)  |
| `npm run typecheck` | TypeScript check, no emit                |
| `npm run test`      | Vitest unit tests                        |
| `npm run lint`      | ESLint                                   |

## Project layout

- `src/lib/manifest/` — manifest download/cache, entity extractors, item
  resolver, perk validator
- `src/lib/llm/` — Ollama client, tool loop, tool definitions, build schema,
  prompts
- `src/lib/search/` — SearXNG JSON API client
- `src/lib/bungie/` — OAuth, session, profile import
- `src/lib/dim/` — wishlist lines, Loadout Optimizer parameters, dim.gg share
- `src/data/meta/` — curated 9.7.0 meta pack (with cached sources)
- `src/data/rules/` — deterministic sandbox rule tables (anti-champion mapping,
  armor archetypes, stat benefit curves, activity rules)
- `src/app/` — pages (`/` generator, `/analyze`, `/settings`) and API routes
