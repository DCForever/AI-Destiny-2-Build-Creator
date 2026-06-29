# Implementation Plan: Build Sets and Synergies

**Branch**: `001-build-sets-synergies` | **Date**: 2026-06-28 | **Spec**: [specs/001-build-sets-synergies/spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-build-sets-synergies/spec.md` (Session 2026-06-22 set/build/variant model; Session 2026-06-28 concept tags; Session 2026-06-28 **Debug/Service UI only** — no production UX this iteration).

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add user-created **Sets** (Weapon, Armor, Mod, Pair, Fashion) with per-type slot cardinality, **concept tags** (`src/data/conceptTags.ts`), **Synergies** with manifest links, and **Builds** with **variants**. Build-level fields (subclass, aspects, exotic armor, designated synergies, tags) are shared; variants differ in attached sets, exotic weapon, and optional notes. Attachments support live reference or snapshot. Tag filters use AND semantics.

**This iteration delivers domain logic via REST/internal APIs and a **Debug/Service UI** at `/debug/*` only** (HTML forms + JSON panels). Production user-facing UI is deferred (FR-033).

Weapon SetItems store full roll data; stale manifest hashes are flagged, not purged. Pair Sets must match build exotic armor. Save guards: ≥1 equipment slot per variant, ≥1 designated synergy per build. Slot replace uses `SLOT_OCCUPIED` → `confirmReplace: true`.

Technical approach: extend SQLite/Drizzle schema; add `src/lib/{sets,synergies,builds,suggestions,catalog}` with co-located tests; expose `/api/user/*` and `/api/catalog/*`; minimal `/debug/*` pages for manual verification (auth required; 404 in production).

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, fuse.js, bungie-api-ts, iron-session, manifest entity stores (`src/lib/manifest`); LLM clients optional (Phase 9 polish)

**Storage**: SQLite (`.cache/app.db`) — tables: `sets`, `set_items`, `set_tags`, `synergies`, `synergy_links`, `builds`, `build_tags`, `build_variants` (`notes` nullable), `build_synergies`, `variant_set_attachments`; existing `loadouts`/`inventory_items`/`users` unchanged initially.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate` (typecheck + lint + test + build)

**Target Platform**: Local dev (`npm run dev`); signed-in user for `/debug/*` and `/api/user/*`; `/debug/*` disabled when `NODE_ENV=production`

**Project Type**: Full-stack Next.js — **API-first + debug pages** (no production UX components)

**Performance Goals**: Sub-100ms attach/conflict checks; sub-5s catalog filter (SC-002); full-list responses acceptable for ≤30 sets / 20 synergies (SC-007; no pagination v1)

**Constraints**: Single-process SQLite; manifest refresh required; fashion excluded from resolution; Pair armor match (FR-028); slot conflicts block save (FR-026); US3 needs minimal synergy read/seed (FR-024); **no production UI**; **no `/debug/*` in production**

**Scale/Scope**: Single user; 6 user stories as **API + debug-verifiable** increments; production UI deferred

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. Each user story verifiable via API tests + `/debug/*` page without production UX. P1 (Sets API + `/debug/sets`) is MVP.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Failing tests before services; debug pages after APIs.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per story checkpoint.
- IV–V. Co-Located Tests + Validation-First: **PASS**. zod at API boundary; manifest validation; stale flag on unresolved hashes.

**Post-design re-check (Phase 1)**: **PASS**. Contracts cover API + debug access; data model includes stale projection and `confirmReplace`; no constitution violations. Debug-only UI is an explicit scope reduction, not a testability shortcut.

## Project Structure

### Documentation (this feature)

```text
specs/001-build-sets-synergies/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 (by /speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── api/
│   │   ├── user/sets|synergies|builds|suggestions/   # domain CRUD + suggest
│   │   └── catalog/weapons|armor/                    # manifest + owned scope
│   └── debug/                                        # FR-033: service UI only
│       ├── layout.tsx                                # auth + production guard
│       ├── sets/page.tsx
│       ├── builds/page.tsx
│       ├── synergies/page.tsx
│       ├── catalog/page.tsx
│       └── suggestions/page.tsx
├── lib/
│   ├── sets/                   # CRUD, slot rules, roll storage, stale detection
│   ├── synergies/              # CRUD, link validation
│   ├── builds/                 # variant resolution, conflicts
│   ├── catalog/                # filterItems + inventory intersection
│   ├── suggestions/            # rules (+ optional LLM polish)
│   ├── db/schema.ts
│   └── db/repositories/
```

**Structure Decision**: Extend existing Next.js app. **No** `src/components/{sets,builds,synergies}` production components in this iteration. Debug pages use plain HTML forms calling the same APIs quickstart scenarios exercise. Builds remain separate from loadout JSON blobs.

## Complexity Tracking

No constitution violations. Debug-only delivery reduces UI surface while preserving testable vertical slices via API + `/debug/*`.
