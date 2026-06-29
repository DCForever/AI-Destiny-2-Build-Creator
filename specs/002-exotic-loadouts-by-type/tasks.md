---
description: "Task list for Exotic Loadouts by Type feature"
---

# Tasks: Exotic Loadouts by Type

**Input**: Design documents from `/specs/002-exotic-loadouts-by-type/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Tasks grouped by user story (P1–P3) for independent increments on `/loadouts` production UI.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US3)

## Path Conventions

- Single Next.js project: `src/`, co-located tests next to modules
- API: extend `src/app/api/user/loadouts/route.ts`
- UI: `src/components/LoadoutsPage.tsx`, `src/components/LoadoutDiscoveryOverlay.tsx`, `src/components/sheet/EditableBuildSheet.tsx`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Module scaffolding and shared types/schemas

- [X] T001 Create loadouts module directory `src/lib/loadouts/` per plan.md
- [X] T002 [P] Add `LoadoutExoticSummary`, `ExoticFilterCriteria`, and related types in `src/lib/loadouts/types.ts`
- [X] T003 [P] Add zod schemas for filter criteria and `GET` query params (`armorMode`, `weaponMode`, slots, hashes) in `src/lib/loadouts/schemas.ts` (contract: `loadout-exotic-filter-contract.md`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Exotic classification from `resolvedSheet` — **blocks all user stories**

**⚠️ CRITICAL**: No user story implementation until this phase completes

- [X] T004 [P] Add failing `classifyLoadoutExotics` tests (armor hash/slot/class, weapon exotic detection, null when absent, unresolved fallback) in `src/lib/loadouts/classifyExotics.test.ts`
- [X] T005 [P] Add failing name-normalization tests in `src/lib/loadouts/normalizeExoticName.test.ts`
- [X] T006 Implement `normalizeExoticName` helper in `src/lib/loadouts/normalizeExoticName.ts`
- [X] T007 Implement `classifyLoadoutExotics` with manifest `exotic-armor` / `exotic-weapons` lookup in `src/lib/loadouts/classifyExotics.ts` (FR-008)
- [X] T008 [P] Add `summarizeLoadouts` batch helper (map loadout id → summary) in `src/lib/loadouts/summarizeLoadouts.ts`

**Checkpoint**: Classification ready — filter and API work can begin

---

## Phase 3: User Story 1 — Filter Loadouts by Exotic Armor (Priority: P1) 🎯 MVP

**Goal**: Exact exotic armor and armor slot-type filters on `/loadouts` list with row labels (FR-001, FR-002)

**Independent Test**: Filter exact "Crown of Tempests" and slot "Helmet"; class-scoped; clear restores full list (spec US1, quickstart Scenario 1)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T009 [P] [US1] Add failing armor-only `filterLoadouts` tests (exact hash, exact name fallback, slot + class match, exclude missing armor, exclude cross-class) in `src/lib/loadouts/filterLoadouts.test.ts`
- [X] T010 [P] [US1] Add failing `parseLoadoutFilterQuery` tests for armor query params and `INVALID_FILTER` cases in `src/lib/loadouts/parseFilterQuery.test.ts`

### Implementation for User Story 1

- [X] T011 [US1] Implement `filterLoadouts` armor dimension in `src/lib/loadouts/filterLoadouts.ts`
- [X] T012 [P] [US1] Implement `parseLoadoutFilterQuery` from URL search params in `src/lib/loadouts/parseFilterQuery.ts`
- [X] T013 [P] [US1] Add failing GET `/api/user/loadouts` armor filter tests in `src/lib/loadouts/loadoutListApi.test.ts`
- [X] T014 [US1] Extend `GET` handler: `exoticSummary` on each row + armor query filter in `src/app/api/user/loadouts/route.ts`
- [X] T015 [P] [US1] Create armor filter controls (exact picker + slot select + clear) in `src/components/loadouts/LoadoutExoticFilterBar.tsx`
- [X] T016 [US1] Integrate armor filter bar, client-side re-filter, and exotic armor labels on rows in `src/components/LoadoutsPage.tsx`
- [X] T017 [US1] Run `npm run gate` and validate quickstart Scenario 1 on `/loadouts`

**Checkpoint**: User Story 1 complete — armor filtering MVP shippable

---

## Phase 4: User Story 2 — Filter Loadouts by Exotic Weapon (Priority: P2)

**Goal**: Exact exotic weapon and weapon slot-type filters; AND when armor + weapon both set (FR-003, FR-006)

**Independent Test**: Filter exact weapon and slot Kinetic/Power; combined helmet + kinetic AND; exclude loadouts without exotic weapon (spec US2, quickstart Scenarios 2 & 4)

### Tests for User Story 2 ⚠️

- [X] T018 [P] [US2] Add failing weapon + combined AND tests to `src/lib/loadouts/filterLoadouts.test.ts` (exact, slot, exclude missing weapon, FR-006 AND)
- [X] T019 [P] [US2] Extend `parseLoadoutFilterQuery` weapon tests in `src/lib/loadouts/parseFilterQuery.test.ts`

### Implementation for User Story 2

- [X] T020 [US2] Extend `filterLoadouts` weapon dimension and AND semantics in `src/lib/loadouts/filterLoadouts.ts`
- [X] T021 [P] [US2] Extend GET route weapon query params and combined filter response in `src/app/api/user/loadouts/route.ts`
- [X] T022 [P] [US2] Add weapon filter controls to `src/components/loadouts/LoadoutExoticFilterBar.tsx`
- [X] T023 [US2] Wire weapon filters, combined AND, and weapon row labels in `src/components/LoadoutsPage.tsx`
- [X] T024 [US2] Run `npm run gate` and validate quickstart Scenarios 2 and 4

**Checkpoint**: User Stories 1 and 2 independently functional

---

## Phase 5: User Story 3 — Contextual Discovery Overlay (Priority: P3)

**Goal**: From opened loadout sheet, discover other loadouts by exact exotic or slot via overlay; sheet stays open (FR-004, FR-007)

**Independent Test**: From Crown loadout, exact overlay shows Crown-only; slot overlay shows all helmets; empty state when alone (spec US3, quickstart Scenario 3)

### Tests for User Story 3 ⚠️

- [X] T025 [P] [US3] Add failing tests for overlay match list + empty state using `filterLoadouts` in `src/components/LoadoutDiscoveryOverlay.test.tsx`

### Implementation for User Story 3

- [X] T026 [P] [US3] Implement `LoadoutDiscoveryOverlay` panel/modal (title, match list, dismiss, exotic labels) in `src/components/LoadoutDiscoveryOverlay.tsx`
- [X] T027 [US3] Add per-exotic discovery actions ("this exotic", "same slot type") in `src/components/sheet/EditableBuildSheet.tsx`
- [X] T028 [US3] Wire overlay open/close state from sheet actions in `src/components/LoadoutsPage.tsx` (sheet remains open behind overlay)
- [X] T029 [US3] Run `npm run gate` and validate quickstart Scenarios 3 and 5

**Checkpoint**: All three user stories complete

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Optional debug surface and full validation

- [X] T030 [P] Add optional `/debug/loadouts` filter query form page in `src/app/debug/loadouts/page.tsx` (plan: optional API verification)
- [X] T031 Run full `specs/002-exotic-loadouts-by-type/quickstart.md` validation (all scenarios)
- [X] T032 [P] Verify manifest re-resolve path still compatible with hash-first exact match in `src/components/LoadoutsPage.tsx` `reResolveIfStale` flow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **blocks all user stories**
- **US1 (Phase 3)**: Depends on Foundational — **MVP**
- **US2 (Phase 4)**: Depends on Foundational; extends US1 filter module and UI (weapon dimension additive)
- **US3 (Phase 5)**: Depends on Foundational + `filterLoadouts`; reuses classification; overlay independent of list filter bar state
- **Polish (Phase 6)**: After desired user stories complete

### User Story Dependencies

| Story | Depends on | Independent test surface |
|-------|------------|--------------------------|
| US1 (P1) | Phase 2 | Armor filters on `/loadouts` list only |
| US2 (P2) | Phase 2, US1 filter bar shell | Weapon + AND filters on list |
| US3 (P3) | Phase 2, `filterLoadouts` | Overlay from opened sheet |

### Parallel Opportunities

- **Phase 1**: T002 ∥ T003
- **Phase 2**: T004 ∥ T005; T008 after T007
- **US1**: T009 ∥ T010; T015 ∥ T013 (after T011–T012)
- **US2**: T018 ∥ T019; T022 ∥ T021 (after T020)
- **US3**: T026 ∥ T025 (tests first per constitution)
- **Polish**: T030 ∥ T032

### Parallel Example: User Story 1

```bash
# Tests first (parallel):
T009 filterLoadouts armor tests in src/lib/loadouts/filterLoadouts.test.ts
T010 parseFilterQuery tests in src/lib/loadouts/parseFilterQuery.test.ts

# Then implementation:
T011 filterLoadouts armor → T014 API route
T015 LoadoutExoticFilterBar → T016 LoadoutsPage integration
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (armor filters)
4. **STOP and VALIDATE**: quickstart Scenario 1 + `npm run gate`
5. Demo `/loadouts` armor filtering

### Incremental Delivery

1. Setup + Foundational → classification ready
2. US1 → armor list filters (MVP)
3. US2 → weapon filters + AND
4. US3 → contextual overlay discovery
5. Polish → optional debug page + full quickstart

---

## Notes

- No SQLite migration — read `resolvedSheet` JSON only
- Do not modify `builds` table APIs — loadouts domain only
- Contextual discovery uses **overlay** (Session 2026-06-29), not list scroll
- Commit at each checkpoint after green gate (constitution III)
