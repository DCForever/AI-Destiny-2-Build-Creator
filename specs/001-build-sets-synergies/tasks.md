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
- UI: `src/app/debug/` — Debug/Service pages only (FR-033); no production components

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Module scaffolding and shared types used across stories

- [X] T001 Create sets module directory structure per plan in `src/lib/sets/`, `src/lib/synergies/`, `src/lib/builds/`, `src/lib/suggestions/`
- [X] T002 [P] Add equipment slot and set-type enums plus zod schemas in `src/lib/sets/schemas.ts` (import `conceptTagIdsSchema` from `src/data/conceptTags.ts`)
- [X] T002b [P] Add `GET /api/concept-tags` route returning vocabulary grouped by facet in `src/app/api/concept-tags/route.ts` (source: `src/data/conceptTags.ts`)
- [X] T003 [P] Add build/variant/synergy zod schemas in `src/lib/builds/schemas.ts` and `src/lib/synergies/schemas.ts` (`buildVariantSchema` includes optional `notes: string | null`)
- [X] T004 [P] Add shared API error codes enum matching contracts in `src/lib/api/errors.ts`
- [X] T005 Add `/debug` layout (auth + production 404 guard) and route stubs in `src/app/debug/{sets,builds,synergies,catalog,suggestions}/page.tsx` (FR-033)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database tables, migration runner, and auth patterns — **blocks all user stories**

**⚠️ CRITICAL**: No user story implementation until this phase completes

- [X] T006 Extend Drizzle schema with `sets`, `set_items`, `set_tags`, `synergies`, `synergy_links`, `builds`, `build_tags`, `build_variants` (`notes` text nullable), `build_synergies`, `variant_set_attachments` in `src/lib/db/schema.ts` (no `category` column; unique on `user_id+type+name`)
- [X] T007 Add SQL migration DDL for new tables and indexes in `src/lib/db/client.ts` `runMigrations()`
- [X] T008 [P] Add co-located migration smoke test in `src/lib/db/schema.test.ts` (assert `build_variants.notes` column exists)
- [X] T009 [P] Create authenticated user helper for new API routes reusing loadout pattern in `src/lib/api/requireUser.ts`
- [X] T010 [P] Add manifest item hash validation helper in `src/lib/sets/validateItem.ts`
- [X] T010b [P] Add `validateSynergyLink` + set-bonus resolver using `set-bonuses` / `origin-traits` stores in `src/lib/synergies/validateSynergyLink.ts`
- [X] T011 Implement slot-to-bucket mapping utility in `src/lib/builds/slotMap.ts`
- [X] T012 Add co-located failing tests for slot mapping in `src/lib/builds/slotMap.test.ts`

**Checkpoint**: Foundation ready — user story work can begin

---

## Phase 3: User Story 1 — Create and Manage Categorized Item Sets (Priority: P1) 🎯 MVP

**Goal**: CRUD for typed Sets with concept tags, 0–1 per slot, replace-with-confirmation, roll storage, deletion guard, tag AND-filter

**Independent Test**: Create Weapon Set named `Solar PVE` with tags `[Solar, PVE]`; replace primary with confirm; delete item and see roll history; block delete when attached; reject duplicate name within type; reject invalid tag (spec US1)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T013 [P] [US1] Add failing set service tests (slot cardinality, replace confirm, unique name per type, tag validation, mod-encourage visibility on empty armor mod slots, delete blocked with `SET_IN_USE` + `{ buildIds, variantIds }`) in `src/lib/sets/setService.test.ts` (FR-017)
- [X] T014 [P] [US1] Add failing set repository tests including `findAttachmentsBySetId` for delete guard in `src/lib/db/repositories/setRepository.test.ts`
- [X] T014b [P] [US1] Add failing `listByTags` AND intersection tests in `src/lib/db/repositories/setRepository.test.ts`

### Implementation for User Story 1

- [X] T015 [P] [US1] Implement `setRepository` CRUD in `src/lib/db/repositories/setRepository.ts`
- [X] T016 [P] [US1] Implement set item CRUD with slot rules, soft-remove roll history, and stale hash flagging in `src/lib/sets/setItemService.ts`
- [X] T017 [US1] Implement `setService` orchestration (delete guard returning `SET_IN_USE` with affected builds/variants, name uniqueness per type, tag validation, `listByTags` AND) in `src/lib/sets/setService.ts` (FR-017)
- [X] T018 [P] [US1] Implement roll-alternatives matcher stub using manifest perks in `src/lib/sets/rollAlternatives.ts`
- [X] T019 [P] [US1] Add `GET`/`POST` routes in `src/app/api/user/sets/route.ts` (`GET` supports `?tags=solar,melee&type=armor` AND filter)
- [X] T020 [P] [US1] Add `GET`/`PATCH`/`DELETE` routes in `src/app/api/user/sets/[id]/route.ts`
- [X] T021 [US1] Add set item routes with `SLOT_OCCUPIED` + `confirmReplace` body flag in `src/app/api/user/sets/[id]/items/route.ts`
- [X] T022 [P] [US1] Build `/debug/sets` page — HTML forms for set CRUD, tag multi-select, item slots, `confirmReplace` resubmit, mod-slot hint, JSON panels in `src/app/debug/sets/page.tsx` (FR-033, FR-027, FR-021)
- [X] T026 [US1] Run `npm run gate` and validate quickstart Scenario 1 via `/debug/sets`

**Checkpoint**: User Story 1 complete — Sets MVP shippable

---

## Phase 4: User Story 2 — View and Filter All Weapons and Armor (Priority: P2)

**Goal**: Browse full manifest catalog and owned inventory with fast fuse.js filtering

**Independent Test**: Filter all weapons by type; switch to My Weapons after sync; instant search (spec US2)

### Tests for User Story 2 ⚠️

- [X] T027 [P] [US2] Add failing catalog filter tests including owned-only mode (intersect manifest with `inventoryRepository`) in `src/lib/catalog/filterItems.test.ts` (FR-007, FR-008)

### Implementation for User Story 2

- [X] T028 [P] [US2] Implement fuse-indexed catalog filter service with `scope: 'all' | 'owned'` using manifest stores + `inventoryRepository` in `src/lib/catalog/filterItems.ts` (FR-007, FR-008)
- [X] T028b [P] [US2] Add owned-inventory API helpers in `src/app/api/catalog/_ownedFilter.ts` (auth-gated; returns empty when unsigned-in or unsynced)
- [X] T029 [P] [US2] Add catalog API route in `src/app/api/catalog/weapons/route.ts` (`?scope=all|owned`)
- [X] T030 [P] [US2] Add catalog API route in `src/app/api/catalog/armor/route.ts` (`?scope=all|owned`)
- [X] T031 [P] [US2] Build `/debug/catalog` page — scope toggle, filter forms, JSON results, sync prompt when owned empty in `src/app/debug/catalog/page.tsx` (FR-007, FR-008)
- [X] T034 [US2] Run `npm run gate` and validate quickstart Scenario 2 via `/debug/catalog`

**Checkpoint**: User Stories 1 and 2 independently functional

---

## Phase 5: User Story 3 — Attach Sets to Builds (Priority: P3)

**Goal**: Build + default variant with shared exotic armor; attach sets live/snapshot; synergy designation; slot conflict + pair armor validation; suggestions hook

**Independent Test**: Create build with synergy + exotic armor; attach live/snapshot sets; filter attach list by Solar+Melee (FR-032); pair match/mismatch; conflict blocks save (spec US3)

### Tests for User Story 3 ⚠️

- [ ] T035 [P] [US3] Add failing build/variant service tests in `src/lib/builds/buildService.test.ts`
- [ ] T036 [P] [US3] Add failing slot resolution + conflict tests in `src/lib/builds/resolveVariant.test.ts`
- [ ] T037 [P] [US3] Add failing attachment mode tests in `src/lib/builds/attachmentService.test.ts`
- [ ] T037b [P] [US3] Add failing automatic suggestion tests (trigger on exotic/subclass/tag change, no explicit action) in `src/lib/suggestions/suggestSets.test.ts`
- [ ] T037c [P] [US3] Add failing synergy suggestion tests (match by synergy type, link targets, build tags) in `src/lib/suggestions/suggestSynergies.test.ts`

### Implementation for User Story 3

- [ ] T038 [P] [US3] Implement `buildRepository` in `src/lib/db/repositories/buildRepository.ts`
- [ ] T039 [P] [US3] Implement `variantRepository` and `attachmentRepository` in `src/lib/db/repositories/variantRepository.ts`
- [ ] T040 [US3] Implement variant slot resolution + `SLOT_CONFLICT` / `PAIR_ARMOR_MISMATCH` in `src/lib/builds/resolveVariant.ts`
- [ ] T041 [US3] Implement live vs snapshot attachment logic in `src/lib/builds/attachmentService.ts`
- [ ] T041b [US3] Implement minimal read-only `synergyRepository.list` + seed helper for dev/tests in `src/lib/db/repositories/synergyRepository.ts` (unblocks FR-024 build save before full US4 CRUD)
- [ ] T042 [US3] Implement `buildService` (save guards FR-022/024/025) in `src/lib/builds/buildService.ts`
- [ ] T043 [P] [US3] Add builds list/create API in `src/app/api/user/builds/route.ts` (`GET` supports `?tags=` AND filter)
- [ ] T044 [P] [US3] Add build detail/patch/delete API in `src/app/api/user/builds/[id]/route.ts` (patch includes `tagIds`)
- [ ] T045 [US3] Add variant patch + resolved equipment API in `src/app/api/user/builds/[id]/variants/[variantId]/route.ts` (PATCH accepts `notes`)
- [ ] T046 [P] [US3] Build `/debug/builds` page — build/variant forms, synergy multi-select, attach live/snapshot, tag filter, conflict JSON, suggestions hooks in `src/app/debug/builds/page.tsx` (FR-024, FR-032, FR-033)
- [ ] T049b [US3] Wire automatic + explicit set/synergy suggestion forms on `/debug/builds` (panel updates when exotic/subclass/tags change)
- [ ] T050 [P] [US3] Implement rule-based `suggestSets` with automatic triggers (exotic armor, subclass, build tags, designated synergies) and explicit goal input hook in `src/lib/suggestions/suggestSets.ts` (FR-010 contextual; LLM enhancement deferred to T077)
- [ ] T050b [P] [US3] Implement rule-based `suggestSynergies` (type/link/tag overlap with build context) in `src/lib/suggestions/suggestSynergies.ts` (FR-016; LLM deferred to T077)
- [ ] T051 [US3] Run `npm run gate` and validate quickstart Scenario 3 via `/debug/builds`

**Checkpoint**: User Story 3 complete — set-based builds work

---

## Phase 6: User Story 4 — Define and Manage Synergies (Priority: P4)

**Goal**: Synergy CRUD by type; link to weapons, perks, origin traits, armor set bonuses; reverse lookup via API + `/debug/catalog`

**Independent Test**: Via `/debug/synergies` and APIs: create synergies with links; filter by type; reverse lookup JSON on `/debug/catalog` (spec US4)

### Tests for User Story 4 ⚠️

- [ ] T052 [P] [US4] Add failing synergy service tests (link kinds, multi-link, multi-synergy per target, set-bonus manifest resolution) in `src/lib/synergies/synergyService.test.ts`

### Implementation for User Story 4

- [ ] T053 [P] [US4] Implement full `synergyRepository` CRUD (extends T041b read-only) in `src/lib/db/repositories/synergyRepository.ts`
- [ ] T054 [US4] Implement `synergyService` in `src/lib/synergies/synergyService.ts`
- [ ] T055 [P] [US4] Add synergies API routes in `src/app/api/user/synergies/route.ts` and `src/app/api/user/synergies/[id]/route.ts`
- [ ] T056 [P] [US4] Build `/debug/synergies` page — CRUD forms, link kind inputs, reverse-lookup test panel in `src/app/debug/synergies/page.tsx` (FR-033)
- [ ] T057b [P] [US4] Add synergy reverse-lookup JSON preview to `/debug/catalog` page
- [ ] T059 [US4] Add `GET /api/user/synergies/by-target` reverse lookup route per [synergy-contract.md](contracts/synergy-contract.md)
- [ ] T058 [US4] Run `npm run gate` and validate quickstart Scenario 4 via `/debug/synergies` + `/debug/catalog`

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
- [ ] T065 [P] [US5] Build `/debug/suggestions` page — roll suggestion forms + JSON panels in `src/app/debug/suggestions/page.tsx` (FR-033)
- [ ] T066 [US5] Wire roll suggestion triggers on `/debug/builds` and `/debug/sets` (link to suggest-rolls API)
- [ ] T067 [US5] Run `npm run gate` and validate quickstart Scenario 5 via `/debug/suggestions`

**Checkpoint**: Roll suggestions deliverable

---

## Phase 8: User Story 6 — Create Variant Builds Using Different Sets (Priority: P6)

**Goal**: Multiple variants per build; shared exotic armor; per-variant exotic weapon + sets; compare and filter

**Independent Test**: Duplicate variant; swap sets and exotic weapon; compare view; filter by exotic armor (spec US6)

### Tests for User Story 6 ⚠️

- [ ] T068 [P] [US6] Add failing variant duplicate/compare tests including `notes` diff in `src/lib/builds/variantService.test.ts`

### Implementation for User Story 6

- [ ] T069 [US6] Implement variant create/duplicate with snapshot defaults in `src/lib/builds/variantService.ts`
- [ ] T070 [US6] Implement variant compare diff (sets, exotic weapon, notes) in `src/lib/builds/compareVariants.ts`
- [ ] T071 [P] [US6] Add variant create/delete API in `src/app/api/user/builds/[id]/variants/route.ts`
- [ ] T072 [P] [US6] Add variant compare API in `src/app/api/user/builds/[id]/compare/route.ts`
- [ ] T073 [US6] Extend `/debug/builds` — variant duplicate, notes field, compare JSON panel, list filters (FR-015, FR-033)
- [ ] T076 [US6] Run `npm run gate` and validate quickstart Scenario 6 via `/debug/builds`

**Checkpoint**: Full variant workflow complete

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: LLM explicit suggestions, resolved export API, full quickstart validation

- [ ] T077 [P] Wire explicit LLM goal suggestions into `suggestSets.ts` and `suggestSynergies.ts` using existing LLM pipeline in `src/lib/llm/` (FR-010/016 explicit path)
- [ ] T079 Extend variant resolved-equipment export on build API or `/debug/builds` JSON download (production sheet UI deferred)
- [ ] T080 [P] Add integration test for end-to-end set attach flow in `src/lib/builds/buildFlow.integration.test.ts`
- [ ] T081 Run full `specs/001-build-sets-synergies/quickstart.md` validation checklist via `/debug/*`
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
| US3 (P3) | US1 + T041b (minimal synergy read) | Full synergy CRUD (US4) enhances picker and T050b/T057b; US3 checkpoint requires designated synergy via T041b + T042 |
| US4 (P4) | Phase 2; **US2 for T057b** | Synergy CRUD independent; T057b reverse-lookup preview lives on `/debug/catalog` (US2) |
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
- **US1**: T013–T014 tests parallel; T015–T016 repos parallel
- **US2**: T027–T031 mostly parallel after T028
- **US3**: T035–T037c tests parallel; T041b before T042; T043–T044 API parallel
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

# UI (after services):
T022: src/app/debug/sets/page.tsx
T046: src/app/debug/builds/page.tsx
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
8. Polish → LLM + export API + full quickstart via `/debug/*`

### Suggested MVP Scope

**User Story 1 only** (Phase 1 + 2 + 3): typed Sets with slot rules, roll storage, APIs + `/debug/sets` — independently valuable per spec. Production UI and nav are out of scope (FR-033).

---

## Notes

- Co-locate all tests as `*.test.ts` next to implementation (constitution IV)
- Validate all API inputs with zod (constitution V)
- Commit only after story checkpoint passes `npm run gate` (constitution III)
- Fashion sets: persist but exclude from `resolveVariant.ts` functional path
- Concept tags: vocabulary in `src/data/conceptTags.ts`; junction tables `set_tags` / `build_tags`; AND filter via tag intersection (FR-031/032)
- `INVALID_TAG` error when tag id not in vocabulary (FR-029)
- Pair sets: enforce `PAIR_ARMOR_MISMATCH` in `attachmentService.ts` per FR-028
