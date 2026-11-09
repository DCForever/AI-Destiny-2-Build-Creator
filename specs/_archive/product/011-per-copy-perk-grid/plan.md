# Implementation Plan: Per-Copy Weapon Perk Grid

**Branch**: `011-per-copy-perk-grid` | **Date**: 2026-07-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-per-copy-perk-grid/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for workflow.

## Summary

Replace the weapon-**type** perk approximation from [010-instance-disambiguation](../010-instance-disambiguation/spec.md) (`GET /catalog/weapons/perk-options` over `WeaponRecord.perkColumns`) with a **DIM-style per-column perk grid driven by real per-copy data**. When the user selects one owned weapon copy in the debug Sets carousel, the UI loads **`GET /api/user/inventory/instances/:instanceId/perk-grid`**, which projects that copy's equipped plugs plus alternates grouped into labeled columns (barrel, magazine, trait columns, intrinsic/frame, origin, masterwork, catalyst when present). The equipped perk is marked and preselected; overrides plus `instanceId` persist through the existing `PUT /user/sets/:id/items` path.

Technical approach: extend inventory sync to capture **Bungie component 310** (`DestinyItemReusablePlugsComponent`) per instance and resolve randomized/profile/character plug-set sources at sync time; persist a **JSON per-socket structure** on `inventory_items` (additive nullable column); add **`resolveInstancePerkGrid`** to classify sockets into columns via manifest socket categories (reusing extractor patterns from `weapons.ts` / `common.ts`), label enhanced variants, and degrade to equipped-only when capture is incomplete; wire the debug Sets perk step to the new endpoint with **one automatic re-sync** when a stale copy lacks capture data (FR-018), then poll until complete or fall back.

## Technical Context

**Language/Version**: TypeScript 5+, Next.js 16.2 (App Router, React 19)

**Primary Dependencies**: `better-sqlite3` + `drizzle-orm` (app DB), Bungie profile sync (`src/lib/bungie/profile.ts`, `syncInventory.ts`), manifest entity cache (`weapons`, `exotic-weapons`, `weapon-perks`, `origin-traits`, `mods`), zod route validation, existing owned-inventory instance pipeline (003) and set-item attachment (010)

**Storage**: SQLite via drizzle. **One additive nullable migration**: `inventory_items.socket_plugs` (JSON text) capturing per-socket `{ socketIndex, equippedPlugHash, reusablePlugHashes[], columnKind, columnLabel }[]` plus a derived **`perkCaptureComplete`** flag (or infer from JSON shape / sync version). Existing `plug_hashes` flat list remains for backward compatibility and carousel equipped display.

**Testing**: vitest co-located `*.test.ts`; gate = `npm run gate` (typecheck + lint + test + build)

**Target Platform**: Local dev (`npm run dev`); signed-in + synced inventory; debug Sets surface only (non-production)

**Project Type**: Full-stack Next.js — **debug-first delivery** (`/debug/sets`, reusing 010 carousel + perk-selection shell)

**Performance Goals**: Perk grid fetched lazily only when a weapon copy is selected (one instance at a time); auto re-sync at most **once per copy per picker session**; user can compare copies and record a roll in < 90s (SC-006)

**Constraints**: Grid scoped to **one selected weapon copy**; MUST NOT show weapon-type roll pool (FR-002, FR-015); non-perk sockets excluded (FR-021); enhanced variants labeled separately (FR-017); exotics use same grid layout (FR-016); auto re-sync must not loop indefinitely or block carousel (FR-018); set attachment reuses existing `instanceId` + `selectedPerks` write path (FR-020)

**Scale/Scope**: 3 user stories; ~18–22 source files across `src/lib/bungie/` (sync + parse), `src/lib/inventory/instances/`, `src/lib/db/`, one new API route, debug Sets page changes; plus `DEBUG.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Small Testable Increments**: **PASS**. Vertical slices: US1a (sync capture + schema) → US1b (grid resolver + column classification) → US1c (perk-grid API) → US1d (debug UI grid) → US3 (auto re-sync + degradation) → US2 regression (selection persistence). Each independently testable.
- **II. Test-First (NON-NEGOTIABLE)**: **PASS** (plan). Failing tests precede: reusable-plug parse, socket-plugs persistence migration, `classifyWeaponSocket`, `resolveInstancePerkGrid` (including enhanced labels + exotic columns), perk-grid route, auto-resync session dedupe, Sets debug integration smoke, and set-item persistence regression.
- **III. Green Commit Checkpoints (NON-NEGOTIABLE)**: **PASS** (plan). Gate at each user-story checkpoint after `/speckit-tasks`.
- **IV. Co-Located Tests**: **PASS**. New `*.test.ts` beside each new/changed module; extend existing profile/instance tests.
- **V. Validation-First External Data**: **PASS**. Bungie 310 + plug-set payloads parsed with typed helpers and range guards; grid DTO validated at route boundary; degradation explicit (`captureStatus`, never silent type-pool fallback).

**Post-design re-check (Phase 1)**: **PASS**. Contracts fix DTO shapes and degradation rules; data model defines capture lifecycle; nullable JSON column is backward compatible; auto re-sync bounded by client session dedupe + server `captureStatus`; no constitution violations. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/011-per-copy-perk-grid/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── instance-perk-grid-contract.md
│   └── sync-socket-plugs-contract.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
src/
├── app/
│   ├── api/
│   │   ├── bungie/sync/route.ts                    # (unchanged handler) invoked by auto re-sync
│   │   └── user/inventory/instances/
│   │       ├── [instanceId]/route.ts               # (optional) embed captureStatus hint
│   │       └── [instanceId]/perk-grid/route.ts     # NEW GET per-copy perk grid
│   └── debug/sets/
│       └── SetsDebugPage.tsx                       # swap perk-options → perk-grid; auto re-sync UX
├── lib/
│   ├── bungie/
│   │   ├── profile.ts                              # +310 parse; +profile/character plug sets; socket parse
│   │   ├── profile.test.ts                         # extend fixtures
│   │   └── syncInventory.ts                        # persist socketPlugs on upsert
│   ├── inventory/instances/
│   │   ├── types.ts                                # + InstancePerkGrid DTO on detail or separate type
│   │   ├── classifyWeaponSocket.ts                 # NEW socket → columnKind/label (manifest-driven)
│   │   ├── resolveInstancePerkGrid.ts              # NEW per-copy grid projection
│   │   ├── perkGridRefresh.ts                      # NEW client/server refresh dedupe helpers
│   │   └── *.test.ts                               # extend + new co-located tests
│   └── db/
│       ├── schema.ts                               # + inventoryItems.socketPlugs
│       ├── types.ts                                # + UserInventoryItem.socketPlugs, captureComplete
│       ├── client.ts                               # + ensureSocketPlugsColumn
│       └── schema.test.ts                          # migration smoke
└── ...
DEBUG.md                                            # update per debug-docs rule (perk-grid, auto re-sync)
```

**Structure Decision**: Single Next.js project. **Compose over 010**: carousel, candidate session, `instanceId`/`selectedPerks` attachment unchanged; replace the data source for perk selection from catalog type-pool to instance perk-grid. Sync/schema change is the main new surface (010 deliberately deferred R2). The existing `GET /catalog/weapons/perk-options` route stays for backward compatibility but is **not** used by Sets debug after this feature.

## Delivery Mapping

| User Story | Domain / data work | API / surface | UI |
|------------|--------------------|---------------|-----|
| US1 Per-copy grid (P1) | Extend sync: component 310 + plug-set resolution; `socket_plugs` column; `classifyWeaponSocket`; `resolveInstancePerkGrid` | `GET /user/inventory/instances/:instanceId/perk-grid` | Replace dropdown data source; column labels; equipped marker |
| US2 Save selection (P1) | (reuse) `setItemInputSchema`, `upsertSetItem` | `PUT /user/sets/:id/items` unchanged | Map grid selection → `selectedPerks` array in column order |
| US3 Degrade + auto re-sync (P2) | `captureStatus` on grid response; `perkGridRefresh` dedupe | Grid returns `pending`/`complete`/`unavailable`; client calls `POST /bungie/sync` once | Loading indicator; equipped-only fallback message; no type-pool fallback |

### Instance perk grid → data sources

| Grid element | Source | Availability / degradation |
|--------------|--------|----------------------------|
| Column grouping (barrel, mag, traits, intrinsic, origin, MW, catalyst) | Manifest item socket categories + plug category identifiers (`classifyWeaponSocket`) | Unknown socket → omitted (FR-021) |
| Equipped perk per column | Component 305 `plugHash` on enabled sockets (existing `plugHashes` / socket row) | always when copy synced |
| Alternate perks per column | Component 310 reusable plugs + profile/character plug sets for randomized sockets | `captureStatus: complete`; else equipped-only |
| Enhanced label | Manifest plug metadata (`isEnhanced` heuristic on plug item) | Both base + enhanced shown when both in column options (FR-017) |
| Perk names | Existing plug name map (`weapon-perks`, `origin-traits`, `mods`) | unresolved → hash string (FR-011) |
| Stale copy | Row missing/incomplete `socket_plugs` | Auto re-sync once (FR-018) → `pending` → re-fetch grid |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | — | — |
