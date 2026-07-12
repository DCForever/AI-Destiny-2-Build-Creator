# Tasks: Lookup-Only Fields

**Input**: Design documents from `/specs/025-lookup-only-fields/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Constitution requires test-first for new behavior. Prefer co-located Vitest helpers over RTL.

**Organization**: Tasks grouped by user story for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 / US2 / US3
- Include exact file paths

## Phase 1: Setup

**Purpose**: Shared vocabularies and helpers used by multiple stories

- [ ] T001 [P] Add known weapon type vocabulary module in `src/data/weaponTypes.ts`
- [ ] T002 [P] Add failing tests for weapon type vocabulary membership in `src/data/weaponTypes.test.ts`
- [ ] T003 [P] Add create-panel helpers (`defaultSubclassForClass`, class-change reset) in `src/lib/build/createBuildLookups.ts`
- [ ] T004 [P] Add failing tests for create-panel helpers in `src/lib/build/createBuildLookups.test.ts`

---

## Phase 2: Foundational

**Purpose**: Shared pick-only / super-lookup building blocks before UI stories

- [ ] T005 Implement `createBuildLookups` helpers so T004 passes
- [ ] T006 Implement `weaponTypes` vocabulary so T002 passes
- [ ] T007 [P] Add reusable pinned-super (ability) lookup component in `src/components/debug/PinnedSuperLookup.tsx` (search-then-pick via `buildSubclassSearchParams` + `/api/manifest/search`)
- [ ] T008 [P] Add pick-only list helpers for aspects/fragments in `src/lib/debug/pickOnlyList.ts` with tests in `src/lib/debug/pickOnlyList.test.ts`

**Checkpoint**: Helpers + vocabulary green; UI stories can proceed

---

## Phase 3: User Story 1 — Create Build With Lookups Only (P1) 🎯 MVP

**Goal**: Production `CreateBuildPanel` uses lookups for subclass, exotic armor, pinned super

**Independent Test**: Create build UI — no free-text subclass/exotic/super; save sends hash+name for exotic

### Tests for User Story 1

- [ ] T009 [P] [US1] Failing tests for create payload mapping (subclass vocabulary, exotic hash/name pair, pinned super from pick) in `src/lib/build/createBuildPayload.test.ts`
- [ ] T010 [US1] Implement `createBuildPayload` mapper in `src/lib/build/createBuildPayload.ts` so T009 passes

### Implementation for User Story 1

- [ ] T011 [US1] Update `src/components/build/CreateBuildPanel.tsx` — subclass select from `SUBCLASSES_BY_CLASS`, wire `ExoticArmorLookup` + `PinnedSuperLookup`, keep name free text
- [ ] T012 [US1] Update `src/components/build/BuildPage.tsx` `handleCreate` to pass `exoticArmorHash` from panel selection
- [ ] T013 [US1] Run `npm run gate`; commit US1 checkpoint

**Checkpoint**: Production create is lookup-only for game concepts

---

## Phase 4: User Story 2 — Debug Subclass Kit Pick-Only (P1)

**Goal**: `SubclassStructuredForm` commits abilities/aspects/fragments only via picks

**Independent Test**: Typing search text alone does not change stored values; pick does

### Tests for User Story 2

- [ ] T014 [P] [US2] Failing tests for pick-only assignment / clear incompatible flow in `src/lib/debug/subclassPickOnly.test.ts` (or extend `pickOnlyList` + `subclassScope` tests)

### Implementation for User Story 2

- [ ] T015 [US2] Refactor `src/components/debug/SubclassStructuredForm.tsx` — ability values read-only + clear; search commits only on pick; aspects/fragments add via pick only (remove free comma identity path); keep rationale free text
- [ ] T016 [US2] Ensure subclass change still clears incompatible selections via `clearIncompatibleSubclassSelections`
- [ ] T017 [US2] Run `npm run gate`; commit US2 checkpoint

**Checkpoint**: Debug subclass form is pick-only for kit identity

---

## Phase 5: User Story 3 — Generator Preferences Lookups (P2)

**Goal**: `BuildForm` preferred exotic/weapon and weapon types are lookups

**Independent Test**: Preferences payload only contains known weapon types and picked names

### Tests for User Story 3

- [ ] T018 [P] [US3] Failing tests for preference payload builder (weapon types ⊆ vocabulary; exotic/weapon names from selection) in `src/lib/llm/buildFormPreferences.test.ts`

### Implementation for User Story 3

- [ ] T019 [US3] Implement preference builder in `src/lib/llm/buildFormPreferences.ts` so T018 passes
- [ ] T020 [US3] Update `src/components/BuildForm.tsx` — exotic/weapon lookups; weapon type multi-select from `KNOWN_WEAPON_TYPES`; keep playstyle/notes free text
- [ ] T021 [US3] Run `npm run gate`; commit US3 checkpoint

**Checkpoint**: Generator preferences follow lookup rule

---

## Phase 6: Polish

- [ ] T022 [P] Align quickstart checklist notes in `specs/025-lookup-only-fields/quickstart.md` if paths drifted
- [ ] T023 Mark all tasks complete in `specs/025-lookup-only-fields/tasks.md`; final `npm run gate`

---

## Dependencies

```text
Phase 1 → Phase 2 → US1 (Phase 3) → US2 (Phase 4) → US3 (Phase 5) → Polish
T001/T002 ∥ T003/T004
T007 ∥ T008 after helpers
US2 can start after Phase 2 (does not require US1 UI) but gate commits stay sequential
US3 depends on T001/T006 vocabulary
```

## Parallel examples

```bash
# Phase 1
T001+T002 with T003+T004 in parallel

# Phase 2
T007 and T008 in parallel after T005/T006
```

## Implementation strategy

1. MVP = US1 production create lookups
2. US2 hardens debug subclass editor
3. US3 finishes generator preferences
4. Commit only when gate is green per story
