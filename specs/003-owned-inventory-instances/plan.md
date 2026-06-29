# Implementation Plan: Owned Inventory Instance Detail

**Branch**: `003-owned-inventory-instances` | **Date**: 2026-06-28 | **Spec**: [specs/003-owned-inventory-instances/spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-owned-inventory-instances/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Expose **per-copy owned inventory** (not collapsed `ownedCount`) for signed-in users with synced inventory. Each instance returns power, location, masterwork/crafted flags, roll tags, and **resolved plug names** (hash fallback when manifest lookup fails). Deliver via **`GET /api/user/inventory/instances`** (filter by item hash, bucket, perk text) and **debug catalog drill-down** on `/debug/catalog` (auto-fetch from catalog row `instancesHref`). Optionally add **`instancesHref` pointer** on owned catalog rows (`includeInstancePointer=1`) — no inline copy payloads. **No sync pipeline or schema changes** — read existing `inventory_items` table.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, manifest entity cache (`weapon-perks`, `mods`, `origin-traits`), iron-session auth

**Storage**: SQLite — existing `inventory_items` + `inventory_sync_meta` tables. **No migration** for v1.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`

**Target Platform**: Local dev (`npm run dev`); signed-in Bungie user with manual inventory sync

**Project Type**: Full-stack Next.js — **debug-first delivery** (production inventory browser out of scope)

**Performance Goals**: Instance list for one item hash &lt;2s at household scale (SC-001); plug name resolution ≥95% with manifest loaded (SC-002)

**Constraints**: Auth required (FR-008); empty + sync prompt when never synced (FR-007); no pagination v1; no re-sync on search (FR-013); no stat bars / kill tracker / ornaments (FR-014); preserve existing catalog browse fields (FR-010); optional instance **pointer** on catalog rows with debug auto-fetch (FR-011); character labels from Bungie roster at projection time (FR-004)

**Scale/Scope**: 4 user stories (P1 list + debug drill-down, P2 query by identity, P2 optional catalog summary, P3 deferred); full user inventory list acceptable v1

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 (list + resolve + debug panel) is standalone MVP. US3 (filter by item hash) builds on projection. US4 (catalog summary) is additive optional flag.
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). `projectInstance` / `resolvePlugs` / `filterInstances` tests before API and debug UI.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per user-story checkpoint after `/speckit-tasks`.
- IV–V. Co-Located Tests + Validation-First: **PASS**. zod query schemas; manifest plug map validated at boundary; unresolved plugs degrade to hash display (FR-006).

**Post-design re-check (Phase 1)**: **PASS**. Contracts define instance DTO and query params; data model is projection over `UserInventoryItem`; no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-owned-inventory-instances/
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
│   ├── api/
│   │   ├── catalog/
│   │   │   ├── weapons/route.ts          # optional includeInstances on owned scope
│   │   │   └── armor/route.ts
│   │   └── user/inventory/instances/
│   │       ├── route.ts                  # GET list + filters
│   │       └── [instanceId]/route.ts     # GET single instance detail
│   └── debug/catalog/
│       └── CatalogDebugPage.tsx          # owned row → instance panel
└── lib/
    └── inventory/
        └── instances/
            ├── types.ts                  # OwnedInstanceDetail, ResolvedPlug, filters
            ├── resolvePlugs.ts             # hash → name from manifest stores
            ├── projectInstance.ts          # UserInventoryItem → DTO
            ├── filterInstances.ts          # bucket, itemHash, perk text q
            ├── listUserInstances.ts        # db + manifest orchestration
            └── *.test.ts
```

**Structure Decision**: Single Next.js project. Domain logic in `src/lib/inventory/instances/` (parallel to `src/lib/loadouts/` from 002). APIs under `/api/user/inventory/instances`. Debug UI extends existing `CatalogDebugPage` — no new production route.

## Delivery Mapping

| User Story | API | Domain | Debug UI |
|------------|-----|--------|----------|
| US1 List owned copies (P1) | `GET /instances` | `listUserInstances`, `projectInstance` | Catalog owned search → instance list panel |
| US2 Debug drill-down (P1) | same + `GET /instances/:id` | detail projection | Select catalog row → fetch instances by hash |
| US3 Query by item identity (P2) | `itemHash` filter | `filterInstances` | Direct API call from debug JSON panel |
| US4 Catalog pointer (P2) | `includeInstancePointer=1` on catalog | `instancesHref` on row | Auto-fetch on row select |
| US5 Stat/tracker (P3) | — | deferred | — |

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
