---
description: "Task list for Build Sets and Synergies feature"
---

# Tasks: Build Sets and Synergies

**Input**: Design documents from `/specs/001-build-sets-synergies/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Tasks grouped by user story (P1–P6) for independent increments.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US6)

## Path Conventions

- Single Next.js project: `src/`, co-located tests next to modules
- API routes: `src/app/api/user/...`
- UI: `src/components/{sets,builds,synergies}/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Module scaffolding and shared types used across stories

- [ ] T001 Create sets module directory structure per plan in `src/lib/sets/`, `src/lib/synergies/`, `src/lib/builds/`, `src/lib/suggestions/`
- [ ] T002 [P] Add equipment slot and set-type enums plus zod schemas in `src/lib/sets/schemas.ts` (import `conceptTagIdsSchema` from `src/data/conceptTags.ts`)
- [ ] T002b [P] Add `GET /api/concept-tags` route returning vocabulary grouped by facet in `src/app/api/concept-tags/route.ts` (source: `src/data/conceptTags.ts`)
- [ ] T003 [P] Add build/variant/synergy zod schemas in `src/lib/builds/schemas.ts` and `src/lib/synergies/schemas.ts`
- [ ] T004 [P] Add shared API error codes enum matching contracts in `src/lib/api/errors.ts`
- [ ] T005 Add feature route stubs (empty pages) in `src/app/sets/page.tsx`, `src/app/builds/page.tsx`, `src/app/synergies/page.tsx`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database tables, migration runner, and auth patterns — **blocks all user stories**

**⚠️ CRITICAL**: No user story implementation until this phase completes

- [ ] T006 Extend Drizzle schema with `sets`, `set_items`, `set_tags`, `synergies`, `builds`, `build_tags`, `build_variants`, `build_synergies`, `variant_set_attachments` in `src/lib/db/schema.ts` (no `category` column; unique on `user_id+type+name`)
- [ ] T007 Add SQL migration DDL for new tables and indexes in `src/lib/db/client.ts` `runMigrations()`
- [ ] T008 [P] Add co-located migration smoke test in `src/lib/db/schema.test.ts`
- [ ] T009 [P] Create authenticated user helper for new API routes reusing loadout pattern in `src/lib/api/requireUser.ts`
- [ ] T010 [P] Add manifest item hash validation helper in `src/lib/sets/validateItem.ts`
- [ ] T011 Implement slot-to-bucket mapping utility in `src/lib/builds/slotMap.ts`
- [ ] T012 Add co-located failing tests for slot mapping in `src/lib/builds/slotMap.test.ts`

**Checkpoint**: Foundation ready — user story work can begin

---

## Phase 3: User Story 1 — Create and Manage Categorized Item Sets (Priority: P1) 🎯 MVP

**Goal**: CRUD for typed Sets with concept tags, 0–1 per slot, replace-with-confirmation, roll storage, deletion guard, tag AND-filter

**Independent Test**: Create Weapon Set named `Solar PVE` with tags `[Solar, PVE]`; replace primary with confirm; delete item and see roll history; block delete when attached; reject duplicate name within type; reject invalid tag (spec US1)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation

- [ ] T013 [P] [US1] Add failing set service tests (slot cardinality, replace confirm, unique name per type, tag validation) in `src/lib/sets/setService.test.ts`
- [ ] T014 [P] [US1] Add failing set repository tests in `src/lib/db/repositories/setRepository.test.ts`
- [ ] T014b [P] [US1] Add failing `listByTags` AND intersection tests in `src/lib/db/repositories/setRepository.test.ts`

### Implementation for User Story 1

- [ ] T015 [P] [US1] Implement `setRepository` CRUD in `src/lib/db/repositories/setRepository.ts`
- [ ] T016 [P] [US1] Implement set item CRUD with slot rules and soft-remove roll history in `src/lib/sets/setItemService.ts`
- [ ] T017 [US1] Implement `setService` orchestration (delete guard, name uniqueness per type, tag validation, `listByTags` AND) in `src/lib/sets/setService.ts`
- [ ] T018 [P] [US1] Implement roll-alternatives matcher stub using manifest perks in `src/lib/sets/rollAlternatives.ts`
- [ ] T019 [P] [US1] Add `GET`/`POST` routes in `src/app/api/user/sets/route.ts` (`GET` supports `?tags=solar,melee&type=armor` AND filter)
- [ ] T020 [P] [US1] Add `GET`/`PATCH`/`DELETE` routes in `src/app/api/user/sets/[id]/route.ts`
- [ ] T021 [US1] Add set item routes with `SLOT_OCCUPIED` + confirm in `src/app/api/user/sets/[id]/items/route.ts`
- [ ] T022 [P] [US1] Build `SetList` with `TagFilterBar` in `src/components/sets/SetList.tsx`
- [ ] T022b [P] [US1] Build shared `ConceptTagPicker` and `TagFilterBar` in `src/components/tags/ConceptTagPicker.tsx` and `src/components/tags/TagFilterBar.tsx`
- [ ] T023 [P] [US1] Build `SetEditor` with per-type slot pickers + `ConceptTagPicker` in `src/components/sets/SetEditor.tsx`
- [ ] T024 [US1] Build replace-confirmation dialog in `src/components/sets/SlotReplaceConfirm.tsx`
- [ ] T025 [US1] Wire sets management page in `src/app/sets/page.tsx`
- [ ] T026 [US1] Run `npm run gate` and validate quickstart Scenario 1 in `specs/001-build-sets-synergies/quickstart.md`

**Checkpoint**: User Story 1 complete — Sets MVP shippable

---

## Phase 4: User Story 2 — View and Filter All Weapons and Armor (Priority: P2)

**Goal**: Browse full manifest catalog and owned inventory with fast fuse.js filtering

**Independent Test**: Filter all weapons by type; switch to My Weapons after sync; instant search (spec US2)

### Tests for User Story 2 ⚠️

- [ ] T027 [P] [US2] Add failing catalog filter tests in `src/lib/catalog/filterItems.test.ts`

### Implementation for User Story 2

- [ ] T028 [P] [US2] Implement fuse-indexed catalog filter service in `src/lib/catalog/filterItems.ts`
- [ ] T029 [P] [US2] Add catalog API route in `src/app/api/catalog/weapons/route.ts`
- [ ] T030 [P] [US2] Add catalog API route in `src/app/api/catalog/armor/route.ts`
- [ ] T031 [P] [US2] Build `ItemBrowser` with all/my toggle in `src/components/catalog/ItemBrowser.tsx`
- [ ] T032 [US2] Add weapons browse page in `src/app/items/weapons/page.tsx`
- [ ] T033 [US2] Add armor browse page in `src/app/items/armor/page.tsx`
- [ ] T034 [US2] Run `npm run gate` and validate quickstart Scenario 2

**Checkpoint**: User Stories 1 and 2 independently functional

---

## Phase 5: User Story 3 — Attach Sets to Builds (Priority: P3)

**Goal**: Build + default variant with shared exotic armor; attach sets live/snapshot; synergy designation; slot conflict + pair armor validation; suggestions hook

**Independent Test**: Create build with synergy + exotic armor; attach live/snapshot sets; filter attach list by Solar+Melee (FR-032); pair match/mismatch; conflict blocks save (spec US3)

### Tests for User Story 3 ⚠️

- [ ] T035 [P] [US3] Add failing build/variant service tests in `src/lib/builds/buildService.test.ts`
- [ ] T036 [P] [US3] Add failing slot resolution + conflict tests in `src/lib/builds/resolveVariant.test.ts`
- [ ] T037 [P] [US3] Add failing attachment mode tests in `src/lib/builds/attachmentService.test.ts`

### Implementation for User Story 3

- [ ] T038 [P] [US3] Implement `buildRepository` in `src/lib/db/repositories/buildRepository.ts`
- [ ] T039 [P] [US3] Implement `variantRepository` and `attachmentRepository` in `src/lib/db/repositories/variantRepository.ts`
- [ ] T040 [US3] Implement variant slot resolution + `SLOT_CONFLICT` / `PAIR_ARMOR_MISMATCH` in `src/lib/builds/resolveVariant.ts`
- [ ] T041 [US3] Implement live vs snapshot attachment logic in `src/lib/builds/attachmentService.ts`
- [ ] T042 [US3] Implement `buildService` (save guards FR-022/024/025) in `src/lib/builds/buildService.ts`
- [ ] T043 [P] [US3] Add builds list/create API in `src/app/api/user/builds/route.ts` (`GET` supports `?tags=` AND filter)
- [ ] T044 [P] [US3] Add build detail/patch/delete API in `src/app/api/user/builds/[id]/route.ts` (patch includes `tagIds`)
- [ ] T045 [US3] Add variant patch + resolved equipment API in `src/app/api/user/builds/[id]/variants/[variantId]/route.ts`
- [ ] T046 [P] [US3] Build `BuildEditor` with exotic armor, synergy multi-select, and `ConceptTagPicker` in `src/components/builds/BuildEditor.tsx`
- [ ] T047 [P] [US3] Build `SetAttachPicker` with live/snapshot toggle + `TagFilterBar` + empty state in `src/components/builds/SetAttachPicker.tsx`
- [ ] T048 [US3] Build slot conflict panel in `src/components/builds/SlotConflictPanel.tsx`
- [ ] T049 [US3] Wire builds page in `src/app/builds/page.tsx`
- [ ] T050 [P] [US3] Add rule-based set suggestion stub in `src/lib/suggestions/suggestSets.ts`
- [ ] T051 [US3] Run `npm run gate` and validate quickstart Scenario 3

**Checkpoint**: User Story 3 complete — set-based builds work

---

## Phase 6: User Story 4 — Define and Manage Synergies (Priority: P4)

**Goal**: Synergy CRUD by type; associate with items/sets; filter catalog

**Independent Test**: Create Melee synergy; filter by Grenade type; surface tags on sets (spec US4)

### Tests for User Story 4 ⚠️

- [ ] T052 [P] [US4] Add failing synergy service tests in `src/lib/synergies/synergyService.test.ts`

### Implementation for User Story 4

- [ ] T053 [P] [US4] Implement `synergyRepository` in `src/lib/db/repositories/synergyRepository.ts`
- [ ] T054 [US4] Implement `synergyService` in `src/lib/synergies/synergyService.ts`
- [ ] T055 [P] [US4] Add synergies API routes in `src/app/api/user/synergies/route.ts` and `src/app/api/user/synergies/[id]/route.ts`
- [ ] T056 [P] [US4] Build `SynergyCatalog` list/filter UI in `src/components/synergies/SynergyCatalog.tsx`
- [ ] T057 [US4] Build `SynergyEditor` in `src/components/synergies/SynergyEditor.tsx`
- [ ] T058 [US4] Wire synergies page in `src/app/synergies/page.tsx`
- [ ] T059 [US4] Integrate synergy tags into `src/components/sets/SetList.tsx`
- [ ] T060 [US4] Run `npm run gate` and validate quickstart Scenario 4

**Checkpoint**: Synergies independently usable (integrates with US3 build form)

---

## Phase 7: User Story 5 — Suggest Weapon Rolls for Sets and Synergies (Priority: P5)

**Goal**: Roll suggestions from set/synergy/build context; owned vs unowned distinction

**Independent Test**: Request roll suggestions for a set; see ≥2 valid perk combos; owned flagged (spec US5, SC-006)

### Tests for User Story 5 ⚠️

- [ ] T061 [P] [US5] Add failing roll suggestion tests in `src/lib/suggestions/suggestRolls.test.ts`

### Implementation for User Story 5

- [ ] T062 [US5] Implement equal-weight synergy merge for suggestions in `src/lib/suggestions/mergeSynergyContext.ts`
- [ ] T063 [US5] Implement roll suggestion service using manifest + inventory in `src/lib/suggestions/suggestRolls.ts`
- [ ] T064 [P] [US5] Add explicit suggest-rolls API in `src/app/api/user/suggestions/rolls/route.ts`
- [ ] T065 [P] [US5] Build `RollSuggestionsPanel` in `src/components/suggestions/RollSuggestionsPanel.tsx`
- [ ] T066 [US5] Integrate auto/explicit roll suggestions into `src/components/builds/BuildEditor.tsx` and `src/components/sets/SetEditor.tsx`
- [ ] T067 [US5] Run `npm run gate` and validate quickstart Scenario 5

**Checkpoint**: Roll suggestions deliverable

---

## Phase 8: User Story 6 — Create Variant Builds Using Different Sets (Priority: P6)

**Goal**: Multiple variants per build; shared exotic armor; per-variant exotic weapon + sets; compare and filter

**Independent Test**: Duplicate variant; swap sets and exotic weapon; compare view; filter by exotic armor (spec US6)

### Tests for User Story 6 ⚠️

- [ ] T068 [P] [US6] Add failing variant duplicate/compare tests in `src/lib/builds/variantService.test.ts`

### Implementation for User Story 6

- [ ] T069 [US6] Implement variant create/duplicate with snapshot defaults in `src/lib/builds/variantService.ts`
- [ ] T070 [US6] Implement variant compare diff in `src/lib/builds/compareVariants.ts`
- [ ] T071 [P] [US6] Add variant create/delete API in `src/app/api/user/builds/[id]/variants/route.ts`
- [ ] T072 [P] [US6] Add variant compare API in `src/app/api/user/builds/[id]/compare/route.ts`
- [ ] T073 [P] [US6] Build `VariantTabs` in `src/components/builds/VariantTabs.tsx`
- [ ] T074 [US6] Build `VariantCompare` view in `src/components/builds/VariantCompare.tsx`
- [ ] T075 [US6] Add exotic-armor, exotic-weapon, and concept tag filters to builds list in `src/components/builds/BuildList.tsx`
- [ ] T076 [US6] Run `npm run gate` and validate quickstart Scenario 6

**Checkpoint**: Full variant workflow complete

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: LLM explicit suggestions, navigation, export, full quickstart validation

- [ ] T077 [P] Wire explicit LLM goal suggestions into `src/lib/suggestions/suggestSets.ts` using existing LLM pipeline in `src/lib/llm/`
- [ ] T078 [P] Add nav links for Sets, Builds, Synergies, Items in `src/components/layout/Nav.tsx` (or existing header component)
- [ ] T079 Extend build sheet export to include attachments in `src/components/sheet/` (resolved variant equipment)
- [ ] T080 [P] Add integration test for end-to-end set attach flow in `src/lib/builds/buildFlow.integration.test.ts`
- [ ] T081 Run full `specs/001-build-sets-synergies/quickstart.md` validation checklist
- [ ] T082 Run `npm run gate` final polish checkpoint

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → **User Stories (Phases 3–8)** → **Polish (Phase 9)**
- Foundational **blocks** all user stories

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|-------|
| US1 (P1) | Phase 2 | MVP — no other stories required |
| US2 (P2) | Phase 2 | Independent of US1 (catalog only) |
| US3 (P3) | US1 + US4 synergies for full form | Minimal path: US1 sets required; synergies can be stubbed until US4 |
| US4 (P4) | Phase 2 | Independent CRUD; enhances US3 when integrated |
| US5 (P5) | US1, US4 | Roll context needs sets + synergies |
| US6 (P6) | US3 | Variants require build/attach foundation |

### Within Each User Story

1. Tests first (fail)
2. Repositories / services
3. API routes
4. UI components
5. Gate + quickstart scenario

### Parallel Opportunities

- **Phase 1**: T002, T003, T004 in parallel
- **Phase 2**: T008, T009, T010 in parallel after T006–T007
- **US1**: T013–T014 tests parallel; T015–T016 repos parallel; T022–T023 UI parallel
- **US2**: T027–T033 mostly parallel after T028
- **US3**: T035–T037 tests parallel; T043–T044 API parallel
- **US4–US6**: repository + API tasks marked [P] within each phase
- **Cross-story**: US1 and US2 can run in parallel after Phase 2

---

## Parallel Example: User Story 1

```bash
# Tests first (parallel):
T013: src/lib/sets/setService.test.ts
T014: src/lib/db/repositories/setRepository.test.ts

# Then repos (parallel):
T015: src/lib/db/repositories/setRepository.ts
T016: src/lib/sets/setItemService.ts

# UI (parallel after services):
T022: src/components/sets/SetList.tsx
T023: src/components/sets/SetEditor.tsx
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T005)
2. Complete Phase 2: Foundational (T006–T012)
3. Complete Phase 3: User Story 1 (T013–T026)
4. **STOP and VALIDATE**: quickstart Scenario 1 + `npm run gate`
5. Demo Sets CRUD

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 Sets → MVP
3. US2 Catalog browse (parallel-friendly)
4. US3 Build attach → core overhaul value
5. US4 Synergies → enriches suggestions
6. US5 Rolls → hunt-for value
7. US6 Variants → multi-loadout-per-exotic-armor
8. Polish → LLM + nav + export

### Suggested MVP Scope

**User Story 1 only** (Phase 1 + 2 + 3): typed Sets with slot rules, roll storage, and management UI — independently valuable per spec.

---

## Notes

- Co-locate all tests as `*.test.ts` next to implementation (constitution IV)
- Validate all API inputs with zod (constitution V)
- Commit only after story checkpoint passes `npm run gate` (constitution III)
- Fashion sets: persist but exclude from `resolveVariant.ts` functional path
- Concept tags: vocabulary in `src/data/conceptTags.ts`; junction tables `set_tags` / `build_tags`; AND filter via tag intersection (FR-031/032)
- `INVALID_TAG` error when tag id not in vocabulary (FR-029)
- Pair sets: enforce `PAIR_ARMOR_MISMATCH` in `attachmentService.ts` per FR-028
