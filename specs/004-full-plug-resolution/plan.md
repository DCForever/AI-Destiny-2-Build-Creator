# Implementation Plan: Full Inventory Plug Resolution

**Branch**: `004-full-plug-resolution` | **Date**: 2026-06-29 | **Spec**: [specs/004-full-plug-resolution/spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-full-plug-resolution/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Expand **read-time plug name resolution** for owned inventory instances so typical equipped plugs on weapons and armor resolve to human-readable names when manifest data exists. Keep the existing `ResolvedPlug` DTO and hash fallback. **No sync or schema changes** — enhance `buildPlugNameMap` / `loadInstanceListContext` with a **hybrid lookup**: merged entity stores plus batch `DestinyInventoryItemDefinition` fallback for plug hashes present in the user's inventory (pattern from `inventoryHashProjections.ts`). Applies automatically to instance list, detail, and `q` search (003 endpoints unchanged).

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: Next.js/React, zod, drizzle-orm + better-sqlite3, manifest entity cache + `ManifestService.loadRawTable`, iron-session auth

**Storage**: SQLite — read-only `inventory_items` (unchanged). Plug names resolved at request time only.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate`; fixture hashes documented in quickstart for SC-001

**Target Platform**: Local dev (`npm run dev`); signed-in Bungie user with manifest refresh + inventory sync

**Project Type**: Full-stack Next.js — **debug-first delivery** (no production inventory UI)

**Performance Goals**: Instance list/detail at household scale &lt;2s with manifest loaded; plug map build amortized per request (entity stores + batch lookup for unique plug hashes in user's equipment rows only)

**Constraints**: Preserve `ResolvedPlug` shape (FR-004); list all stored plug hashes (FR-005); auth unchanged (FR-010); no stat bars / kill counts UI (FR-011); no persist-at-sync (FR-009); ≥99% named plugs on quickstart fixtures (SC-001)

**Scale/Scope**: 4 user stories (P1 weapon + armor resolution, P2 search + debug verification); touch `resolvePlugs.ts`, `loadInstanceContext.ts`, instance API routes; optional alignment of `loadoutText` hash index — not required for acceptance

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: **PASS**. US1 (weapon plug map + tests) is MVP. US2 (armor — same code path). US3 (`q` search inherits map). US4 (debug — no API change).
- II. Test-First (NON-NEGOTIABLE): **PASS** (plan). Extend `resolvePlugs.test.ts` and add `buildPlugNameMap` integration tests with fixture hashes before wiring routes.
- III. Green Commit Checkpoints (NON-NEGOTIABLE): **PASS** (plan). Gate per user-story checkpoint after `/speckit-tasks`.
- IV–V. Co-Located Tests + Validation-First: **PASS**. Manifest lookups use `isUsable` / `projectBase`; unresolved plugs remain explicit (FR-006).

**Post-design re-check (Phase 1)**: **PASS**. Contract documents unchanged DTO with resolution coverage notes; data model adds derived `PlugNameMap` only; no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/004-full-plug-resolution/
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
├── app/api/user/inventory/instances/
│   ├── route.ts                          # pass inventory plug hashes into context builder
│   └── [instanceId]/route.ts           # same for single-instance
└── lib/
    ├── catalog/
    │   └── inventoryHashProjections.ts   # reuse / generalize for plug names
    └── inventory/instances/
        ├── resolvePlugs.ts               # buildPlugNameMap + resolvePlugs
        ├── loadInstanceContext.ts        # orchestrate hybrid map
        ├── filterInstances.ts            # q search (unchanged logic, richer map)
        ├── projectInstance.ts            # unchanged projection
        └── *.test.ts                     # fixtures incl. Ringing Nail hashes
```

**Structure Decision**: Single Next.js project. All resolution logic stays in `src/lib/inventory/instances/`; manifest fallback reuses catalog projection helpers. No new API routes.

## Delivery Mapping

| User Story | Domain | API | Debug |
|------------|--------|-----|-------|
| US1 Weapon plug names (P1) | `buildPlugNameMap`, manifest fallback | list + detail | catalog instance panel |
| US2 Armor plug names (P1) | same path | list + detail | same |
| US3 Perk search (P2) | `filterInstances` + expanded map | `q` param | search in debug panel |
| US4 Debug verification (P2) | quickstart fixtures | — | manual SC-001 check |

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
