# Implementation Plan: Exotic Loadouts by Type

**Branch**: `002-exotic-loadouts-by-type` | **Date**: 2026-06-29 | **Spec**: [specs/002-exotic-loadouts-by-type/spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-exotic-loadouts-by-type/spec.md` (Session 2026-06-21 clarifications: exact + slot modes for armor and weapons).

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Let signed-in users **filter and discover** their **saved loadouts** (`loadouts` table, `/loadouts` page) by exotic armor or weapon using two complementary modes: **exact** (specific manifest identity) and **slot/type** (any exotic in the same armor slot or weapon bucket). Contextual actions from an opened loadout sheet apply the same criteria without mutating data.

Technical approach: pure classification + filter logic over `SavedLoadout.resolvedSheet` in `src/lib/loadouts/` (co-located tests); enrich `GET /api/user/loadouts` with exotic projections and optional server-side query filters; extend **`LoadoutsPage`** and **`EditableBuildSheet`** for list filters and contextual discovery. No SQLite schema changes. Manifest `exotic-armor` / `exotic-weapons` stores supply slot and class metadata when hashes resolve.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, existing manifest entity cache (`src/lib/manifest`), iron-session auth

**Storage**: SQLite — existing `loadouts` table only (`resolved_sheet` JSON holds exotic armor + weapons). **No migration** for v1.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`

**Target Platform**: Local dev (`npm run dev`); signed-in Bungie user for `/loadouts` and `/api/user/loadouts`

**Project Type**: Full-stack Next.js — **production `/loadouts` UX** (unlike 001 debug-only iteration)

**Performance Goals**: Filter ≤50 loadouts in &lt;5s (SC-001); contextual discovery &lt;10s (SC-002); in-memory filter acceptable at household scale

**Constraints**: User-scoped loadouts only (FR-009); read-only discovery (no loadout mutation); class-aware armor slot filters (Titan helmet ≠ Hunter helmet); finer weapon sub-types out of scope; builds/sets APIs unchanged

**Scale/Scope**: 3 user stories (armor P1, weapon P2, contextual P3); single-user household; full list fetch (no pagination v1)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. P1 (armor exact + slot on `/loadouts`) is standalone MVP. P2 adds weapon filters. P3 adds sheet actions reusing P1/P2 logic.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). `classifyLoadoutExotics` / `filterLoadouts` tests before API/UI wiring.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per user-story checkpoint.
- IV–V. Co-Located Tests + Validation-First: **PASS**. zod for query params; manifest lookup for slot/class; graceful handling when exotic unresolved.

**Post-design re-check (Phase 1)**: **PASS**. Contracts define filter modes and projections; data model is derived view over existing `SavedLoadout`; no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/002-exotic-loadouts-by-type/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── loadouts/page.tsx              # existing route
│   └── api/user/loadouts/
│       └── route.ts                   # extend GET with filter query + exotic summary
├── components/
│   ├── LoadoutsPage.tsx               # filter bar, empty states, list labels
│   └── sheet/EditableBuildSheet.tsx   # contextual "same exotic" / "same slot" actions
└── lib/
    └── loadouts/
        ├── classifyExotics.ts         # extract armor/weapon identity from ResolvedBuildSheet
        ├── filterLoadouts.ts          # exact + slot matching (pure)
        ├── filterLoadouts.test.ts
        ├── schemas.ts                 # zod query + filter criteria
        └── types.ts                   # LoadoutExoticSummary, ExoticFilterCriteria
```

**Structure Decision**: New `src/lib/loadouts/` module; extend existing production loadouts surface. Reuse manifest slot enums from `src/lib/manifest/types/records.ts`. Do **not** conflate with `builds` table filtering (different domain).

## Delivery & Verification

| Concern | Decision |
|---------|----------|
| Primary UI | `/loadouts` — filter controls above list; exotic labels on each row when filtered |
| Contextual discovery | Actions on exotic armor/weapon rows in `EditableBuildSheet` → apply filter + scroll/highlight list |
| API | `GET /api/user/loadouts` returns `exoticSummary` per row; optional query params apply server filter (see contract) |
| Client filter | After initial fetch, client may re-filter in-memory for instant toggles (same pure functions) |
| Class scoping | Armor slot filter respects `buildRequest.className` vs exotic armor `classType` from manifest |
| Unresolved exotics | Exact match falls back to normalized `requestedName`; slot filter excludes loadout if slot cannot be resolved |
| Debug (optional) | `/debug/loadouts` thin page mirroring filter query params for API-only verification (not required for SC) |

See [research.md](./research.md) for classification rules, exact vs slot semantics, and manifest refresh behavior.

## Complexity Tracking

No constitution violations.
