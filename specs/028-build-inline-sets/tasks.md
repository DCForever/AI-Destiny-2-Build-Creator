# Tasks: Build Inline Sets

**Input**: Design documents from `/specs/028-build-inline-sets/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md  
**Tests**: Constitution requires test-first for new behavior (co-located vitest).  
**Organization**: By user story for independent delivery.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Parallelizable (different files, no incomplete deps)
- **[Story]**: US1–US5 from spec.md

## Phase 1: Setup

- [x] T001 Verify feature docs and src paths in specs/028-build-inline-sets/plan.md match repo layout (BuildPage, VariantEditPanel, create-sets, SlotFillPanel)
- [x] T002 [P] Confirm clarifications (guided walkthrough, Armor→Weapons→Mods, satisfied=Set+fills, Skip for now, Capture preferred) reflected in specs/028-build-inline-sets/plan.md Delivery Mapping

---

## Phase 2: Foundational (BLOCKS stories)

- [x] T003 [P] Create FinishCategory/FinishGap types + evaluateFinishGaps pure function in src/lib/builds/finishGaps.ts per contracts/finish-gaps-contract.md
- [x] T004 [P] Create finishGaps unit tests in src/lib/builds/finishGaps.test.ts (order, satisfied both conditions, capture_available, empty attached needs_fill) — fail first
- [x] T005 Implement createSetAndAttach in src/lib/builds/createSetAndAttach.ts (unique name, create set, replace-by-type live attach)
- [x] T006 Create createSetAndAttach tests in src/lib/builds/createSetAndAttach.test.ts
- [x] T007 [P] Optional thin helper mapBuildDetailToFinishInput in src/lib/builds/finishGapsFromDetail.ts if build detail payload needs shaping for evaluateFinishGaps

**Checkpoint**: Domain gaps + create-and-attach green; npm run gate on new tests

---

## Phase 3: US1 — Create and attach Set from Builds (P1)

**Goal**: Create empty combat Set from Builds and live-attach without Sets library  
**Independent Test**: Create Armor Set from variant Sets UI; appears attached live

- [x] T008 [P] [US1] CreateSetAttachForm UI in src/components/build/CreateSetAttachForm.tsx (name, type armor/weapon/mod, optional tags)
- [x] T009 [US1] Wire create empty + attach on VariantEditPanel Sets tab in src/components/build/VariantEditPanel.tsx using createSetAndAttach or client POST /api/user/sets + replace attach
- [x] T010 [US1] Success feedback naming created set + refresh build/variant detail after attach
- [x] T011 [US1] Sign-in / busy / error handling for create-attach path

**Checkpoint**: US1 independent test

---

## Phase 4: US2 — Fill slots from Builds (P1)

**Goal**: Fill/replace slots on live-attached Sets from Builds  
**Independent Test**: Empty armor set attached; fill helmet from Builds; resolved loadout updates

- [x] T012 [US2] Host SlotFillPanel (or fill entry) from Builds for a selected attached live set/slot in src/components/build/VariantEditPanel.tsx or src/components/build/BuildSlotFillHost.tsx
- [x] T013 [US2] Snapshot guard: block library fill mutation on snapshot-only cover; prompt live path (FR-012)
- [x] T014 [US2] Refresh attachments/resolved equipment after onFilled

**Checkpoint**: US2 independent test

---

## Phase 5: US3 — Capture current gear (P1)

**Goal**: Production create-from-build (capture) with attach-now  
**Independent Test**: Resolved armor, no set → Capture creates Armor Set live-attached

- [x] T015 [US3] Capture current gear control calling POST /api/user/builds/[id]/create-sets with categories + attachNow in src/components/build/CaptureSetsFromBuild.tsx
- [x] T016 [US3] Surface skippedCategories / NOTHING_TO_CREATE clearly; do not claim mods created when skipped
- [x] T017 [US3] Wire capture on VariantEditPanel / build detail and refresh after success

**Checkpoint**: US3 quickstart capture path

---

## Phase 6: US4 — Guided finish walkthrough (P1)

**Goal**: Primary Finish build walkthrough Armor→Weapons→Mods with create/link/capture/fill/skip  
**Independent Test**: Incomplete default variant → Finish build → two gaps → exit/resume

- [x] T018 [US4] FinishBuildWalkthrough shell in src/components/build/FinishBuildWalkthrough.tsx (progress, overview/category/fill/done, Skip for now, Exit)
- [x] T019 [US4] Drive steps from evaluateFinishGaps; session skippedKeys client-only; never mark skip as satisfied
- [x] T020 [US4] Category step actions: prefer Capture when canCapture; Create empty; Link existing (SetAttachPicker + replace-by-type)
- [x] T021 [US4] Fill step lists emptySlots and opens US2 fill host
- [x] T022 [US4] Finish build primary CTA on incomplete default variant in src/components/build/BuildPage.tsx or Build detail component
- [x] T023 [US4] Re-evaluate gaps after each mutation; done success vs remaining skips summary

**Checkpoint**: US4 guided path + SC-006 style smoke

---

## Phase 7: US5 — Pair when needed (P3)

**Goal**: Pair type on create path; Fashion not in primary finish types  
**Independent Test**: Create Pair from create form; Fashion absent from walkthrough types

- [x] T024 [US5] Allow type pair on CreateSetAttachForm / walkthrough create; exclude fashion from primary finish type list
- [x] T025 [US5] Pair attach validation messages reuse existing pair/exotic mismatch errors

**Checkpoint**: US5 independent test

---

## Phase 8: Polish

- [x] T026 [P] Note BR for build finish walkthrough in specs/business-rules.md if not captured (e.g. BR-BLD-finish or BR-SET attach-from-build)
- [x] T027 Run npm run gate; fix failures
- [x] T028 Manual smoke per specs/028-build-inline-sets/quickstart.md
- [x] T029 [P] Align plan/quickstart if implementation drift

---

## Dependencies

- Setup → Foundational → US1 → US2 → US3 → US4 → US5 → Polish
- US4 integrates US1–US3; MVP = Foundational + US1 (create+attach), then US4 for full guided value
- US3 can parallelize with US2 after US1 attach exists

## Parallel examples

```text
T003+T004 finishGaps
T005+T006 createSetAndAttach after T003 types stable
T008 CreateSetAttachForm || T015 Capture component skeletons
```

## MVP

Ship Foundational + US1 (create empty Set + live attach from Builds). Then US2 fill, US3 capture, US4 walkthrough shell as the product finish path.

