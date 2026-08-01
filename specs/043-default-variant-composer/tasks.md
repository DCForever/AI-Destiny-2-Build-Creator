---
description: "Task list for Default Variant Composer implementation"
---

# Tasks: Default Variant Composer

**Input**: Design documents from `/specs/043-default-variant-composer/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Constitution requires Test-First for new pure helpers and testable behavior. Co-located Vitest (`*.test.ts`) written and confirmed failing before implementation; commit only after green `npm run gate`.

**Organization**: Phases by user story (US1–US8) after setup/foundation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable (different files, no incomplete deps)
- **[Story]**: US1–US8 map to spec user stories
- Paths are repo-root relative

## Path Conventions

- App UI: `src/components/build/`
- Helpers: `src/lib/builds/`
- Spec docs: `specs/043-default-variant-composer/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold composer module paths and export surface without behavior change yet

- [x] T001 Create directory `src/components/build/composer/` and barrel `src/components/build/composer/index.ts` exporting placeholders for tab components
- [x] T002 [P] Add stub files `src/components/build/DefaultVariantComposer.tsx`, `src/components/build/composer/GeneralTab.tsx`, `src/components/build/composer/SubclassTab.tsx`, `src/components/build/composer/ArmorModSetTab.tsx`, `src/components/build/composer/WeaponSetTab.tsx`, `src/components/build/composer/FinishTab.tsx` (minimal valid React client components)
- [x] T003 [P] Confirm UI mock exists at `docs/ui-mocks/default-variant-composer.html` and link it from `specs/043-default-variant-composer/plan.md` Structure section if missing

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure access/gating helpers and composer session types required by every story

**⚠️ CRITICAL**: No user story UI work until this phase completes

- [x] T004 [P] Write failing tests for tab gating in `src/lib/builds/composerTabAccess.test.ts` covering General/Finish always, Subclass needs class+subclass, Armor/Weapon need class (per `contracts/default-variant-composer-contract.md`)
- [x] T005 Implement `composerTabAccess` in `src/lib/builds/composerTabAccess.ts` until T004 passes
- [x] T006 [P] Write failing tests for finish missing-reason copy in `src/lib/builds/finishMissingReasons.test.ts` using fixtures from `finishGaps` shapes
- [x] T007 Implement `finishMissingReasons` in `src/lib/builds/finishMissingReasons.ts` until T006 passes
- [x] T008 Define shared composer types/session props in `src/components/build/composer/types.ts` (`ComposerTab`, draft|live mode, `buildId`/`variantId`, sub-path enums) per `data-model.md`
- [x] T009 Implement tab strip + panel host shell (no domain save yet) in `src/components/build/DefaultVariantComposer.tsx` using `composerTabAccess` and `types.ts` (Finish always listed; blocked tabs non-activatable with reason)

**Checkpoint**: Foundation ready — shell can render with mocked props; helpers tested

---

## Phase 3: User Story 1 - Tabbed Default Variant Shell (Priority: P1) 🎯 MVP

**Goal**: New build and existing default variant open the tabbed shell (General · Subclass · Armor · Weapon · Finish) with FR-022 locks and no CreateBuildPanel primary path

**Independent Test**: New build → composer on General; locked tabs until class/subclass; Finish visible; no standalone Create build panel

### Tests for User Story 1

- [x] T010 [P] [US1] Extend or add unit coverage that BuildPage “New build” path does not mount `CreateBuildPanel` (component test or thin pure flag helper under `src/components/build/` / co-located test preferred)

### Implementation for User Story 1

- [x] T011 [US1] Wire `BuildPage.tsx` so **New build** opens `DefaultVariantComposer` in draft mode on General (remove/stop primary `creating` → `CreateBuildPanel` flow)
- [x] T012 [US1] Wire existing build + variant edit entry in `BuildPage.tsx` to open `DefaultVariantComposer` in live mode with `build`/`variant` props (replace or wrap `VariantEditPanel` call site)
- [x] T013 [US1] Ensure tab switches in `DefaultVariantComposer.tsx` preserve in-session form state (single mounted shell; no remount reset of General draft fields)
- [x] T014 [US1] Keep hard-block messaging path available in shell (surface existing save errors; no domain rule changes) in `DefaultVariantComposer.tsx` / Finish stub area

**Checkpoint**: US1 independently demoable — shell + New build entry + locks

---

## Phase 4: User Story 2 - General Tab (Priority: P1)

**Goal**: Intent, identity, artifact on General; first save creates build from draft

**Independent Test**: Designate synergies + class/subclass; save creates build; zero synergies → NO_SYNERGY; pickers scoped per 042

### Tests for User Story 2

- [x] T015 [P] [US2] Reuse/adapt create payload tests if needed in `src/lib/build/createBuildPayload` related tests; add any draft→payload helper tests under `src/lib/build/` or `src/lib/builds/` when new helpers appear

### Implementation for User Story 2

- [x] T016 [US2] Implement General form UI in `src/components/build/composer/GeneralTab.tsx` (name, class, subclass, synergy types, pinned super, exotic armor; include shared exotic weapon **only if** already on create/edit identity—else skip)
- [x] T017 [US2] Wire 042-scoped `ManifestSearchPicker` usage in `GeneralTab.tsx` (class exotic; class+subclass super)
- [x] T018 [US2] Implement draft **Save general** → `POST /api/user/builds` using `createBuildPayload` / kit sourcing patterns from `CreateBuildPanel.tsx`; transition composer to live mode with returned ids in `DefaultVariantComposer.tsx`
- [x] T019 [US2] Add artifact + perk configuration on General for live mode in `GeneralTab.tsx` (port from `VariantEditPanel.tsx` artifact section)
- [x] T020 [US2] Surface soft guidance read-only on General in `GeneralTab.tsx`: locate existing coverage/guidance UI first; if absent, minimal read-only placeholder from existing guidance APIs; never auto-apply

**Checkpoint**: Draft create + identity edit works from General alone

---

## Phase 5: User Story 3 - Subclass Tab (Priority: P1)

**Goal**: Grouped subclass kit pickers on one tab with capacity/legality preserved

**Independent Test**: With class+subclass set, Subclass tab unlocks; abilities/aspects/fragments editable and save via existing variant/build PATCH paths

### Tests for User Story 3

- [x] T021a [P] [US3] Add/extend unit coverage that subclass tab remains disallowed without subclass via `composerTabAccess` cases in `src/lib/builds/composerTabAccess.test.ts` (manual kit UI OK after)

### Implementation for User Story 3

- [x] T021 [US3] Port abilities / aspects / fragments pickers from `VariantEditPanel.tsx` into grouped layout in `src/components/build/composer/SubclassTab.tsx`
- [x] T022 [US3] Wire Subclass save/PATCH and exotic-ability checks into `SubclassTab.tsx` / `DefaultVariantComposer.tsx` (preserve `evaluateSubclassKit` / capacity behavior)
- [x] T023 [US3] Enforce Subclass tab lock until subclass set via `composerTabAccess` in `DefaultVariantComposer.tsx`

**Checkpoint**: Legal kit editable on Subclass tab only when gated open

---

## Phase 6: User Story 4 - Armor Reuse + optional Improve (Priority: P1)

**Goal**: Armor Reuse lists, live attach, optional Improve kit

**Independent Test**: Attach class-compatible armor set; Improve optional; detach works; empty library → Create still available

### Tests for User Story 4

- [x] T024a [P] [US4] Document/assert mutation-disabled-without-buildId behavior in `composerTabAccess` comments or a small pure helper test if extracted (manual attach E2E in quickstart)

### Implementation for User Story 4

- [x] T024 [US4] Implement Armor **Reuse | Create** sub-path chrome in `src/components/build/composer/ArmorModSetTab.tsx`
- [x] T025 [US4] Integrate class-constrained armor + mod set attach UI (reuse `SetAttachPicker` / list patterns) in `ArmorModSetTab.tsx` with live attach + detach via existing merge/remove attachment helpers
- [x] T026 [US4] After successful armor attach, show skippable **Improve kit** entry mounting `FinishArmorOptimizeWorkspace.tsx` (suggest-then-confirm only) in `ArmorModSetTab.tsx`
- [x] T027 [US4] Disable attach/create/improve-apply when `buildId` null even if Armor tab is navigable (FR-022 nav vs mutation); show “save General to continue” in `ArmorModSetTab.tsx`

**Checkpoint**: Reuse attach + optional Improve without Create path

---

## Phase 7: User Story 5 - Armor Create / Optimize / tags (Priority: P1)

**Goal**: Create path with optimize, generated name, concept tags from synergies

**Independent Test**: Create/optimize confirm yields named set with concept tags; no auto-apply; can create without optimize

### Tests for User Story 5

- [x] T028 [P] [US5] Write failing tests for synergy→conceptTag mapping + default set name helper in `src/lib/builds/` (e.g. `synergyConceptTags.test.ts` / extend `createSetAndAttach.test.ts`)
- [x] T029 [US5] Implement mapping/name helpers and extend `src/lib/builds/createSetAndAttach.ts` (and route if needed under `src/app/api/user/builds/[id]/create-set-attach/`) until T028 passes

### Implementation for User Story 5

- [x] T030 [US5] Implement Armor **Create** UI in `ArmorModSetTab.tsx` using **existing** optimizer goals/bonuses UI from `FinishArmorOptimizeWorkspace.tsx` (no new bonus domain model) + Optimize workspace + result confirm
- [x] T031 [US5] On confirm, call create-set-attach / materialize with name + conceptTags inheritance; live-attach to variant from `ArmorModSetTab.tsx`
- [x] T032 [US5] Support mod set attach/create after armor chosen (library pick or save-from-pieces patterns already in product) in `ArmorModSetTab.tsx`

**Checkpoint**: Create path matches FR-009–011 without forced optimize

---

## Phase 8: User Story 6 - Weapon Set Reuse / Create (Priority: P1)

**Goal**: Weapon Reuse attach; Create Primary/Secondary/Heavy with synergy-first ranking

**Independent Test**: Attach weapon set; Create shows P/S/H searches; matching weapons indicated first

### Tests for User Story 6

- [x] T033 [P] [US6] Write failing tests for `weaponSynergyRank` in `src/lib/builds/weaponSynergyRank.test.ts`
- [x] T034 [US6] Implement `src/lib/builds/weaponSynergyRank.ts` until T033 passes

### Implementation for User Story 6

- [x] T035 [US6] Implement Weapon **Reuse | Create** chrome and Reuse attach in `src/components/build/composer/WeaponSetTab.tsx`
- [x] T036 [US6] Implement Create Primary/Secondary/Heavy slot-constrained catalog search in `WeaponSetTab.tsx` applying `weaponSynergyRank` + match indicator chips
- [x] T037 [US6] Preserve wishlist vs equip-ready pin behavior on weapon saves (no domain change) via existing variant/slot fill hosts from `WeaponSetTab.tsx`

**Checkpoint**: Weapon compose path complete

---

## Phase 9: User Story 7 - Finish Tab (Priority: P2)

**Goal**: Always-visible Finish with missing reasons; equip/DIM gated on completeness + equip-ready

**Independent Test**: Incomplete → Finish open, actions disabled + reasons; complete equip-ready → actions work

### Tests for User Story 7

- [x] T038a [P] [US7] Extend `finishMissingReasons.test.ts` for incomplete vs complete copy; equip button enablement stays pure-function composed in tests if extracted

### Implementation for User Story 7

- [x] T038 [US7] Implement `src/components/build/composer/FinishTab.tsx` using `evaluateFinishGapsFromVariant` / `finishGaps` + `finishMissingReasons` + `computeEquipReady`
- [x] T039 [US7] Port equip / DIM actions from `BuildActions.tsx` into FinishTab with disable rules (complete ∧ equipReady); clear pin/wishlist status copy
- [x] T040 [US7] Remove dependency on opening `FinishBuildWalkthrough` as primary path from `BuildPage.tsx` (walkthrough may remain unused or debug-only)
- [x] T041 [US7] Ensure Finish never required for set create (no dead-ends forcing Finish for armor/weapons) — verify Armor/Weapon tabs remain the create paths

**Checkpoint**: Finish matches clarify B + FR-017

---

## Phase 10: User Story 8 - Non-default full tabs (Priority: P2)

**Goal**: Same full tab set for non-default variants; light edits allowed

**Independent Test**: Non-default opens same tabs; weapon-only save; equip-with-gaps unchanged

### Tests for User Story 8

- [x] T042a [P] [US8] Assert tab id list for non-default equals default (shared constant test in `src/components/build/composer/types.ts` or adjacent `*.test.ts`)

### Implementation for User Story 8

- [x] T042 [US8] Confirm `DefaultVariantComposer` receives any variant (default or not) from `BuildPage.tsx` without reduced tab strip
- [x] T043 [US8] Soften any default-only forced create rituals on Armor/Weapon for non-default (allow partial combat; keep DAC-VAR-001 equip-with-gaps via existing actions)
- [x] T044 [US8] Adjust Finish completeness messaging for non-default (equip-with-gaps path) in `FinishTab.tsx` without hiding Finish

**Checkpoint**: One shell for all variants

---

## Phase 11: Polish & Cross-Cutting

**Purpose**: Cleanup, gate, docs

- [x] T045 [P] Thin or delete obsolete primary usage of `CreateBuildPanel.tsx` / reduce `VariantEditPanel.tsx` to re-export of `DefaultVariantComposer` if fully superseded
- [x] T046 [P] Remove dead `FinishBuildWalkthrough` imports from production paths in `BuildPage.tsx` once FinishTab covers gaps/optimize entry points
- [x] T047 Run `specs/043-default-variant-composer/quickstart.md` unit commands and manual checklist; fix failures
- [x] T048 Run `npm run gate` and fix typecheck/lint/test/build issues
- [x] T049 [P] Update `docs/ui-polish-tracker.md` or operator notes only if needed for pure UI notes (no domain DAC change unless product rule shipped)
- [x] T050 Verify no domain rule regressions (NO_SYNERGY, exotic limits, soft guidance never auto-applies) via existing tests + spot check
- [x] T051 [P] Process check for FR-019: if implementation intentionally deviates from `docs/build-composer-flow - Future direction.excalidraw`, update `specs/043-default-variant-composer/spec.md` in the same change (no runtime code)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup** → no deps
- **Phase 2 Foundational** → after Setup; **blocks all stories**
- **US1** → after Foundational (MVP shell)
- **US2** → after US1 (needs shell + New build entry)
- **US3** → after US2 (needs class/subclass persisted gates)
- **US4** → after US2 (needs `buildId` for attach); can parallel US3 after US2
- **US5** → after US4 (same Armor tab)
- **US6** → after US2; can parallel US4/US5 after US2
- **US7** → after US2 minimum (gaps meaningful after armor/weapon better); ideally after US4–US6
- **US8** → after US1 shell; finalize after US7
- **Polish** → after desired stories

### User Story Dependencies

| Story | Depends on |
|-------|------------|
| US1 Shell | Foundation |
| US2 General | US1 |
| US3 Subclass | US2 |
| US4 Armor Reuse | US2 |
| US5 Armor Create | US4 |
| US6 Weapons | US2 |
| US7 Finish | US2 (+ US4–6 for full demo) |
| US8 Non-default | US1 (+ US2–7 for parity) |

### Parallel Opportunities

- T004/T006 tests in parallel; T002 stubs in parallel
- After US2: US3 ∥ US4 ∥ US6 (different tab files)
- T028/T033 tests in parallel before their implementations
- T045/T046 cleanup in parallel

### Within Each Story

- Tests first (fail) → implement → gate green → commit checkpoint

---

## Parallel Example: After US2

```text
# Parallel tab workstreams
US3: SubclassTab.tsx
US4: ArmorModSetTab.tsx (Reuse)
US6: WeaponSetTab.tsx + weaponSynergyRank.ts
```

---

## Parallel Example: Foundation helpers

```text
Task T004+T005: composerTabAccess
Task T006+T007: finishMissingReasons
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Phase 1–2 foundation  
2. US1 shell + New build  
3. US2 General draft→create  
4. **STOP**: validate New build identity path without CreateBuildPanel  
5. Then US3–US6 compose tabs  
6. US7 Finish  
7. US8 non-default polish  

### Incremental Delivery

Each US phase is a vertical demo slice; do not block armor work on Finish polish.

### Suggested MVP scope

**US1 + US2** (shell + General create). Armor/Weapon/Finish follow as next increments.

---

## Notes

- Do not invent new domain hard blocks
- Capture-from-gear is not primary chrome
- Canonical UX: `docs/build-composer-flow - Future direction.excalidraw`
- Contract: `contracts/default-variant-composer-contract.md`
- Commit only on green gate (constitution III)
- Run `npm run gate` after each user-story checkpoint before commit (not only T048)
- FR-019 is process-only (T051); Excalidraw board remains canonical IA
- Analyze remediations 2026-07-24 applied: buildId mutation guard, exotic scope, optimizer bonuses, FR-019 task, extra test hooks US3/4/7/8
