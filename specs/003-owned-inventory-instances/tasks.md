---
description: "Task list for Owned Inventory Instance Detail feature"
---

# Tasks: Owned Inventory Instance Detail

**Input**: Design documents from `/specs/003-owned-inventory-instances/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Tasks grouped by user story (P1–P2) for independent increments on debug catalog + instance API. US5 (stat/tracker/kills sort) deferred — no tasks.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US4)

## Path Conventions

- Single Next.js project: `src/`, co-located tests next to modules
- API: `src/app/api/user/inventory/instances/`
- Domain: `src/lib/inventory/instances/`
- Debug UI: `src/app/debug/catalog/CatalogDebugPage.tsx`
- Catalog extension: `src/app/api/catalog/weapons/route.ts`, `src/app/api/catalog/armor/route.ts`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Module scaffolding, types, and query schemas

- [x] T001 Create instances module directory `src/lib/inventory/instances/` per plan.md
- [x] T002 [P] Add `OwnedInstanceDetail`, `ResolvedPlug`, `InstanceFilterCriteria`, and related types in `src/lib/inventory/instances/types.ts` (data-model.md)
- [x] T003 [P] Add zod schemas for instance list query params (`itemHash`, `bucket`, `kind`, `q`) in `src/lib/inventory/instances/schemas.ts` (contract: `inventory-instances-contract.md`)
- [x] T004 [P] Add test fixtures for synced inventory rows in `src/lib/inventory/instances/__fixtures__/inventoryFixtures.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Plug resolution and instance projection — **blocks all user stories**

**⚠️ CRITICAL**: No user story implementation until this phase completes

- [x] T005 [P] Add failing `buildPlugNameMap` / `resolvePlugs` tests (weapon-perks, mods, origin-traits; unresolved hash fallback) in `src/lib/inventory/instances/resolvePlugs.test.ts`
- [x] T006 [P] Add failing `projectInstance` tests (all plugs listed, kind from bucket, power sort field presence) in `src/lib/inventory/instances/projectInstance.test.ts`
- [x] T007 Implement `buildPlugNameMap` and `resolvePlugs` in `src/lib/inventory/instances/resolvePlugs.ts` (FR-005, FR-006)
- [x] T008 Implement `projectInstance` in `src/lib/inventory/instances/projectInstance.ts` (FR-004 plug shape; extensible for future `socketType`)
- [x] T009 [P] Add `sortInstancesByPower` helper (power descending per FR-015) in `src/lib/inventory/instances/sortInstances.ts`

**Checkpoint**: Projection ready — filter, API, and UI work can begin

---

## Phase 3: User Story 1 — List Owned Copies (Priority: P1) 🎯 MVP

**Goal**: Authenticated instance list API with separate rows per copy, resolved plugs, sync-prompt empty state (FR-001, FR-004–FR-008, FR-015)

**Independent Test**: `GET /api/user/inventory/instances?itemHash=<hash>` returns N distinct instances with power, location, flags, plug names; never-synced user gets `syncPrompt: true` (quickstart Scenarios 1–2, 7)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation

- [x] T010 [P] [US1] Add failing `filterInstances` tests (kind, bucket, perk `q` AND, exclude non-weapon/armor buckets) in `src/lib/inventory/instances/filterInstances.test.ts`
- [x] T011 [P] [US1] Add failing `listUserInstances` orchestration tests (auth context, sync prompt, power desc sort) in `src/lib/inventory/instances/listUserInstances.test.ts`

### Implementation for User Story 1

- [x] T012 [US1] Implement `filterInstances` in `src/lib/inventory/instances/filterInstances.ts` (FR-003 perk text; catalog-first — no item-name param)
- [x] T013 [US1] Implement `listUserInstances` in `src/lib/inventory/instances/listUserInstances.ts` (read `inventory_items`; manifest plug map; FR-007, FR-015)
- [x] T014 [US1] Add `GET` handler with query validation in `src/app/api/user/inventory/instances/route.ts`
- [x] T015 [US1] Run `npm run gate` and validate quickstart Scenarios 1, 2, and 7 (API)

**Checkpoint**: User Story 1 complete — instance list API MVP shippable

---

## Phase 4: User Story 2 — Debug Catalog Drill-Down (Priority: P1)

**Goal**: Select owned catalog row → auto-fetch instance list; single-instance detail; character class + display name (FR-009, FR-004 character fields, clarified auto-fetch)

**Independent Test**: On `/debug/catalog` owned scope, select weapon + armor row → instance panel shows per-copy detail without leaving page (quickstart Scenario 3)

### Tests for User Story 2 ⚠️

- [x] T016 [P] [US2] Add failing `resolveCharacterLabels` tests (className + displayName; vault omits; roster miss degrades) in `src/lib/inventory/instances/resolveCharacterLabels.test.ts`
- [x] T017 [P] [US2] Add failing single-instance lookup tests in `src/lib/inventory/instances/listUserInstances.test.ts`

### Implementation for User Story 2

- [x] T018 [US2] Implement `resolveCharacterLabels` using Bungie character roster in `src/lib/inventory/instances/resolveCharacterLabels.ts` (research R9)
- [x] T019 [US2] Wire character enrichment into `projectInstance` / `listUserInstances` in `src/lib/inventory/instances/listUserInstances.ts`
- [x] T020 [P] [US2] Add `GET` handler in `src/app/api/user/inventory/instances/[instanceId]/route.ts`
- [x] T021 [US2] Extend `CatalogDebugPage.tsx`: owned row selection, instance panel, **auto-fetch** from `instancesHref` or `itemHash` query (FR-009)
- [x] T022 [US2] Run `npm run gate` and validate quickstart Scenario 3

**Checkpoint**: P1 stories complete — list API + debug drill-down

---

## Phase 5: User Story 3 — Query by Item Identity & Perk Search (Priority: P2)

**Goal**: Stable `itemHash` filter, empty-not-error when unowned, perk `q` search across inventory (FR-002, FR-003, FR-012; SC-004)

**Independent Test**: `itemHash` returns all copies or empty `200`; `?kind=weapons&q=frenzy` returns only matching rolls (quickstart Scenarios 4–6)

### Tests for User Story 3 ⚠️

- [x] T023 [P] [US3] Add failing `itemHash` empty-result and perk `q` tests to `src/lib/inventory/instances/filterInstances.test.ts`
- [x] T024 [P] [US3] Add failing API-level tests for `itemHash` + `q` params in `src/lib/inventory/instances/listUserInstances.test.ts`

### Implementation for User Story 3

- [x] T025 [US3] Harden `itemHash` filter and empty-state messaging in `src/lib/inventory/instances/listUserInstances.ts` (not sync-failure error)
- [x] T026 [P] [US3] Add direct instance API query controls (`itemHash`, `kind`, `q`) to `src/app/debug/catalog/CatalogDebugPage.tsx`
- [x] T027 [US3] Run `npm run gate` and validate quickstart Scenarios 4, 5, and 6

**Checkpoint**: Item identity and perk search independently testable

---

## Phase 6: User Story 4 — Catalog Instance Pointer (Priority: P2)

**Goal**: Optional `includeInstancePointer=1` on owned catalog adds `instancesHref` per row; no inline payloads (FR-011, SC-006)

**Independent Test**: Owned catalog without flag unchanged; with flag each owned row has `instancesHref`; debug auto-fetches on select (quickstart Scenario 8)

### Tests for User Story 4 ⚠️

- [x] T028 [P] [US4] Add failing `buildInstancesHref` tests in `src/lib/inventory/instances/instancesHref.test.ts`
- [x] T029 [P] [US4] Add failing catalog pointer tests in `src/lib/catalog/filterItems.test.ts` or dedicated `src/lib/inventory/instances/catalogPointer.test.ts`

### Implementation for User Story 4

- [x] T030 [P] [US4] Implement `buildInstancesHref` helper in `src/lib/inventory/instances/instancesHref.ts`
- [x] T031 [US4] Add `includeInstancePointer` query param and `instancesHref` on owned rows in `src/app/api/catalog/weapons/route.ts`
- [x] T032 [P] [US4] Add `includeInstancePointer` and `instancesHref` in `src/app/api/catalog/armor/route.ts`
- [x] T033 [US4] Update `CatalogDebugPage.tsx` to use `instancesHref` from catalog response when present
- [x] T034 [US4] Run `npm run gate` and validate quickstart Scenario 8

**Checkpoint**: All in-scope user stories complete

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Full validation and documentation alignment

- [x] T035 Run full `specs/003-owned-inventory-instances/quickstart.md` validation (all scenarios)
- [x] T036 [P] Align `specs/003-owned-inventory-instances/plan.md` delivery table with `includeInstancePointer` naming if drift remains
- [x] T037 [P] Verify `find_weapons_with_perk` owned path remains compatible with new instance `instanceId` shape (no regression in `src/lib/llm/tools.ts`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **blocks all user stories**
- **US1 (Phase 3)**: Depends on Foundational — **MVP**
- **US2 (Phase 4)**: Depends on Foundational + US1 list API; adds character enrichment and debug UI
- **US3 (Phase 5)**: Depends on US1 filter/list pipeline; extends tests and debug API panel
- **US4 (Phase 6)**: Depends on US1 `instancesHref` target + US2 debug select flow
- **Polish (Phase 7)**: After desired user stories complete

### User Story Dependencies

| Story | Depends on | Independent test surface |
|-------|------------|--------------------------|
| US1 (P1) | Phase 2 | `GET /api/user/inventory/instances` |
| US2 (P1) | Phase 2, US1 API | `/debug/catalog` owned drill-down |
| US3 (P2) | US1 | `itemHash` + perk `q` API filters |
| US4 (P2) | US1, US2 | Catalog `includeInstancePointer=1` |
| US5 (P3) | — | **Deferred** (no tasks) |

### Parallel Opportunities

- **Phase 1**: T002 ∥ T003 ∥ T004
- **Phase 2**: T005 ∥ T006; T009 after T008
- **US1**: T010 ∥ T011 → T012–T014
- **US2**: T016 ∥ T017; T020 ∥ T018 (after T019)
- **US3**: T023 ∥ T024
- **US4**: T028 ∥ T029; T031 ∥ T032 (after T030)
- **Polish**: T036 ∥ T037

### Parallel Example: User Story 1

```bash
# Tests first (parallel):
T010 filterInstances tests in src/lib/inventory/instances/filterInstances.test.ts
T011 listUserInstances tests in src/lib/inventory/instances/listUserInstances.test.ts

# Then implementation:
T012 filterInstances → T013 listUserInstances → T014 API route
```

---

## Implementation Strategy

### MVP First (User Story 1 + US2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (instance list API)
4. Complete Phase 4: User Story 2 (debug drill-down)
5. **STOP and VALIDATE**: quickstart Scenarios 1–3, 7 + `npm run gate`
6. Demo `/debug/catalog` owned instance drill-down

### Incremental Delivery

1. Setup + Foundational → projection ready
2. US1 → instance list API (MVP)
3. US2 → debug catalog auto-fetch panel (P1 complete)
4. US3 → itemHash + perk search hardening
5. US4 → catalog `instancesHref` pointer
6. Polish → full quickstart

---

## Notes

- No SQLite migration — read `inventory_items` JSON columns only
- Do not trigger re-sync on instance or catalog search (FR-013)
- Catalog item **name** search stays on owned catalog browse; instance API uses `itemHash` / perk `q` (clarified Session 2026-06-28)
- v1 lists **all** plug hashes; `socketType` deferred
- Instance sort: power descending (FR-015); kills-then-acquired deferred (US5)
- US5 stat bars / kill tracker — **no tasks** in v1
