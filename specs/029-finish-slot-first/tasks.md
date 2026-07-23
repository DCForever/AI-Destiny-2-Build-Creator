# Tasks: Finish Slot-First Chrome

**Input**: Design documents from `/specs/029-finish-slot-first/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md  
**Tests**: Constitution requires test-first for new pure helpers (co-located vitest).  
**Organization**: By user story for independent delivery.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Parallelizable (different files, no incomplete deps)
- **[Story]**: US1–US5 from spec.md

## Phase 1: Setup

- [ ] T001 Verify specs/029-finish-slot-first/plan.md paths match repo (FinishBuildWalkthrough.tsx, CreateSetAttachForm.tsx, CaptureSetsFromBuild.tsx, BuildSlotFillHost.tsx, VariantEditPanel.tsx, create-set-attach route, finishGaps.ts)
- [ ] T002 [P] Confirm contracts/finish-one-tap-create-contract.md and contracts/finish-slot-first-ui-contract.md align with createSetAndAttach name default when name omitted

---

## Phase 2: Foundational (BLOCKS stories)

**Purpose**: Pure slot-cursor helpers all Finish stories share

- [ ] T003 [P] Add finishNextSlot helpers in src/lib/builds/finishNextSlot.ts (firstEmptyRequiredSlot from FinishGap.emptySlots; resolvePostMutationStep for needs_fill → fill / satisfied → overview|next; categoryType mapping armor|weapon|mod)
- [ ] T004 [P] Add failing then passing unit tests in src/lib/builds/finishNextSlot.test.ts (weapon empty order primary→special→heavy; armor five-slot order; no empty → no fill step; snapshot needs_fill does not auto-fill)
- [ ] T005 Confirm createSetAndAttach inherits `${build.name} ${TypeLabel}` when name omitted via existing src/lib/builds/createSetAndAttach.test.ts (extend only if coverage missing)

**Checkpoint**: finishNextSlot green; npm run gate on new tests

---

## Phase 3: US1 — One-tap create then fill (P1) 🎯 MVP

**Goal**: Finish category Create is one button (type fixed, no name/tags); after success open first empty required slot  
**Independent Test**: No Weapons Set → Finish → Weapons → Create → live-attached inherited name → first empty weapon slot fill UI

### Tests

- [ ] T006 [P] [US1] Extend or add tests proving finishNextSlot after synthetic needs_fill gap returns fillSlot emptySlots[0] in src/lib/builds/finishNextSlot.test.ts

### Implementation

- [ ] T007 [US1] In src/components/build/FinishBuildWalkthrough.tsx replace CreateSetAttachForm on category step with one-tap Create button that POSTs `/api/user/builds/${build.id}/create-set-attach` with `{ variantId, type: categoryType, attachNow: true }` only (no name/tagIds)
- [ ] T008 [US1] After create success: show set.name message (FR-013), await refresh/loadResolved, call finishNextSlot; if fill target set step fill + fillSlot; else overview/next
- [ ] T009 [US1] Update Finish subtitle copy to create/capture then fill (not “link” as primary) in src/components/build/FinishBuildWalkthrough.tsx
- [ ] T010 [US1] Busy/error handling for one-tap create (signed-out / API error callouts)

**Checkpoint**: US1 independent test; gate

---

## Phase 4: US2 — Slot-first fill loop (P1)

**Goal**: After covering Set exists, advance empty required slots in order without re-showing create chrome  
**Independent Test**: Empty live Weapons Set → Finish fill primary → next empty opens automatically

### Tests

- [ ] T011 [P] [US2] Unit cases for successive emptySlots shrink after fills in src/lib/builds/finishNextSlot.test.ts

### Implementation

- [ ] T012 [US2] In src/components/build/FinishBuildWalkthrough.tsx on BuildSlotFillHost onFilled: refresh, re-evaluate active gap, open next empty via finishNextSlot or leave fill when category satisfied
- [ ] T013 [US2] When opening category with status needs_fill + live covering, auto-enter first empty slot (or single primary Fill CTA that opens first empty) — do not require Create
- [ ] T014 [US2] Keep snapshot needs_fill guard (no library fill); retain Skip for now / Back

**Checkpoint**: US2 independent test; gate

---

## Phase 5: US3 — Capture preferred without form chrome (P1)

**Goal**: Capture remains preferred above Create; after capture enter fill loop or satisfy  
**Independent Test**: Resolved weapon claims, no Weapons Set → Capture preferred → attach → fill remaining or done

### Implementation

- [ ] T015 [US3] Ensure CaptureSetsFromBuild renders above one-tap Create when activeGap.canCapture in src/components/build/FinishBuildWalkthrough.tsx; preferred labeling/copy
- [ ] T016 [US3] Capture onDone: refresh + finishNextSlot same as create (fill first empty or overview)
- [ ] T017 [US3] Do not show Capture when canCapture false; do not claim mods captured when skipped

**Checkpoint**: US3 quickstart capture path; gate

---

## Phase 6: US4 — Finish hides advanced chrome; Sets tab keeps it (P2)

**Goal**: No link picker/tags/attach-mode in Finish; VariantEditPanel retains create form + attach  
**Independent Test**: Finish has no SetAttachPicker; Sets tab still links/creates with name

### Implementation

- [ ] T018 [US4] Remove SetAttachPicker and “Or link an existing Set” block from Finish category step in src/components/build/FinishBuildWalkthrough.tsx (delete unused attachExisting if dead)
- [ ] T019 [US4] Verify src/components/build/VariantEditPanel.tsx still mounts CreateSetAttachForm and SetAttachPicker (fix only if regressed)
- [ ] T020 [US4] Smoke: after Sets-tab link with empty slots, Finish opens fill_loop not create form

**Checkpoint**: US4 independent test

---

## Phase 7: US5 — Armor simplified chrome; optimizer deferred (P2)

**Goal**: Armor uses same one-tap + fill path; no optimizer UI  
**Independent Test**: Finish → Armor → Create → first empty armor slot; no kit compare

### Implementation

- [ ] T021 [US5] Confirm armor category uses same one-tap Create type armor and finishNextSlot path in src/components/build/FinishBuildWalkthrough.tsx (no armor-only optimizer branch)
- [ ] T022 [US5] Optional short comment near armor create/fill in FinishBuildWalkthrough.tsx noting 031 may replace post-create destination later

**Checkpoint**: US5 independent test

---

## Phase 8: Polish

- [ ] T023 [P] Note BR-BLD-007 follow-on or BR-BLD-008 slot-first Finish chrome in specs/business-rules.md if product rule not already captured
- [ ] T024 [P] Align docs/ui-mocks/finish-build-slot-first.html weapons one-tap path with shipped Finish chrome if drifted
- [ ] T025 Run npm run gate; fix failures
- [ ] T026 Manual smoke per specs/029-finish-slot-first/quickstart.md

---

## Dependencies & Execution Order

### Phase dependencies

- Setup → Foundational → US1 → US2 → US3 → US4 → US5 → Polish
- US2 builds on US1 fill entry; US3 reuses same post-mutation path as US1
- US4 is mostly removal/verify; can start after US1 once Finish no longer needs picker
- US5 is parity check after US1–US2

### User story dependencies

- **US1 (P1)**: After Foundational — MVP
- **US2 (P1)**: After US1 create→fill entry
- **US3 (P1)**: After Foundational; ideally after US1 post-mutation helper wiring
- **US4 (P2)**: After US1 (strip link safely)
- **US5 (P2)**: After US1–US2 armor path works

### Parallel opportunities

```text
T001 || T002
T003 || T004 (write tests first then implement T003 until green)
T006 with T011 after T003 API stable
T018 removal after T007 one-tap exists
```

---

## Parallel example: Foundational + US1

```text
T004 finishNextSlot tests (fail)
T003 finishNextSlot impl (pass)
T007 one-tap Create UI
T008 post-create → first empty slot
```

---

## Implementation strategy

### MVP

Ship Foundational + **US1** (one-tap Create → first empty slot). Validate SC-001.

### Incremental

1. US2 fill loop  
2. US3 Capture preferred polish  
3. US4 strip Finish link; confirm Sets tab  
4. US5 Armor parity note  
5. Polish + gate + quickstart  

### Notes

- Do not add optimizer UI (031) or classType API (030).
- CreateSetAttachForm remains for Sets tab only.
- Commit only at green checkpoints (constitution).
