# Destiny 2 Build Creator

A local-first web app that generates and analyzes Destiny 2 builds. A local LLM
researches and composes the build using tool calls against the real Bungie
manifest plus optional web search (SearXNG); the app then validates every item,
perk, and stat against manifest data before rendering a build sheet with DIM
exports.

Built against the **Update 9.7.0 "Monument of Triumph"** (June 9, 2026) sandbox:
Anti-Champion 2.0, Armor 3.0 (12 archetypes, 0-200 stats with enhanced benefits
past 100), Artifacts 2.0 (seven permanent artifacts), and the final ability
economy.

## Stack

- Next.js (App Router) + TypeScript strict + Tailwind CSS
- Local LLM via **OpenAI-compatible API** (default; LM Studio, vLLM, etc.),
  **Ollama**, or **Grok (xAI)** with optional auto-fallback to a local LLM —
  two-phase pipeline: tool-call research loop, then JSON-schema composition
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

1. **Local LLM** — one of:
   - **LM Studio** (recommended default): enable *Local Server*, load a
     tool-capable model, copy its model id into `LLM_MODEL`. Set
     `LLM_PROVIDER=openai` and `LLM_URL=http://127.0.0.1:1234/v1`.
   - **Ollama**: `ollama pull gemma4` (12B+ recommended), set
     `LLM_PROVIDER=ollama`, `OLLAMA_URL=http://127.0.0.1:11434`,
     `OLLAMA_MODEL=gemma4`.
   - **Grok (xAI)**: set `LLM_PROVIDER=grok` and `XAI_API_KEY` (or
     `LLM_API_KEY`) from [console.x.ai](https://console.x.ai). Defaults to
     `grok-4.3` at `https://api.x.ai/v1` (`LLM_MODEL_GROK` overrides the model).
     To auto-fallback to a local LLM when Grok is unavailable, also set
     `OLLAMA_URL`/`OLLAMA_MODEL` or a local `LLM_URL` + `LLM_MODEL` (e.g. LM Studio).
   - Any other **OpenAI-compatible** server on `/v1/chat/completions` with
     function/tool calling support.

   The model should support **tool/function calling** for Phase A (manifest
   research). Phase B prefers **JSON schema / structured output**; if your
   server rejects `response_format`, the app retries without it and validates
   with zod.

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

Copy `.env.local.example` to `.env.local`. Key LLM variables:

| Variable | Purpose |
| --- | --- |
| `LLM_PROVIDER` | `openai` (default), `ollama`, or `grok` |
| `LLM_URL` | Base URL — include `/v1` for OpenAI-compatible servers |
| `LLM_MODEL` | Model id for openai/ollama or local Grok fallback (LM Studio server tab) |
| `LLM_MODEL_GROK` | Grok model id when `LLM_PROVIDER=grok` (default `grok-4.3`) |
| `LLM_API_KEY` | Optional Bearer token if your server requires auth |
| `XAI_API_KEY` | xAI API key when `LLM_PROVIDER=grok` (alias for `LLM_API_KEY`) |
| `OLLAMA_URL` / `OLLAMA_MODEL` | Ollama config; also used as Grok fallback when set |

Other variables are optional except when using the corresponding feature
(Bungie keys for sign-in, `SESSION_SECRET` for sessions, `DIM_API_KEY` for
dim.gg shares).

## Using the app

1. **First run**: open **Settings** and click *Refresh manifest*. This
   downloads the Bungie manifest tables and builds the derived entity stores
   (requires `BUNGIE_API_KEY`). Generation refuses to run without them.
2. **Generator** (`/`): pick class/subclass/activity/playstyle, optionally pin
   an exotic or weapon, and generate. The model researches with manifest tools
   before composing; the app then resolves every name, flags fuzzy matches,
   illegal perks, and missing champion coverage, and renders the build sheet.
   *Regenerate* reruns the same request; *Try a Different Angle* asks for a
   different exotic and engine.
3. **Analyzer** (`/analyze`): paste your current loadout (or sign in with
   Bungie and import a character's equipped gear) and get an assessment,
   prioritized swaps, and an optimized build sheet.
4. **Exports**: every build sheet offers a DIM wishlist, Loadout Optimizer
   parameters, raw JSON, and — when signed in with Bungie and `DIM_API_KEY` is
   set — a dim.gg share link.

## Scripts

| Script              | Purpose                                  |
| ------------------- | ---------------------------------------- |
| `npm run dev`       | Dev server (HTTP)                        |
| `npm run dev:https` | Dev server with local HTTPS (for OAuth)  |
| `npm run typecheck` | TypeScript check, no emit                |
| `npm run test`      | Vitest unit tests                        |
| `npm run lint`      | ESLint                                   |
| `npm run build`     | Production build                         |

## Project layout

- `src/lib/manifest/` — manifest download/cache, entity extractors, item
  resolver, perk validator
- `src/lib/llm/` — LLM clients (OpenAI-compatible, Ollama, Grok with fallback),
  tool loop, build schema, prompts
- `src/lib/search/` — SearXNG JSON API client
- `src/lib/bungie/` — OAuth, session, profile import
- `src/lib/dim/` — wishlist lines, Loadout Optimizer parameters, dim.gg share
- `src/data/meta/` — curated 9.7.0 meta pack (with cached sources)
- `src/data/rules/` — deterministic sandbox rule tables (anti-champion mapping,
  armor archetypes, stat benefit curves, activity rules)
- `src/app/` — pages (`/` generator, `/analyze`, `/settings`) and API routes
