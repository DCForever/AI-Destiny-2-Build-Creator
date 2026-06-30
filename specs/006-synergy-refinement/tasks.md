---
description: "Task list for Synergy Refinement feature"
---

# Tasks: Synergy Refinement

**Input**: Design documents from `/specs/006-synergy-refinement/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Foundational schema + domain libs block all stories. US1/US2 are both P1 and ship together for MVP (auto-name requires sub-type). US3 verifies existing many-to-many. US4/US5 extend debug UI pickers + description panel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US5)

## Path Conventions

- Domain: `src/lib/synergies/`
- Data: `src/data/synergyElements.ts`
- DB: `src/lib/db/schema.ts`, `src/lib/db/repositories/synergyRepository.ts`, `drizzle/`
- API: `src/app/api/catalog/synergy-pickers/`, `src/app/api/user/synergies/`
- Debug: `src/app/debug/synergies/SynergiesDebugPage.tsx`, `src/app/debug/catalog/CatalogDebugPage.tsx`
- Docs: `DEBUG.md`, `specs/006-synergy-refinement/quickstart.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Constants and test fixtures for synergy refinement

- [ ] T001 [P] Add seven-element list (Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic) in `src/data/synergyElements.ts`
- [ ] T002 [P] Add synergy refinement test fixtures (sample types, subTypes, link display names) in `src/lib/synergies/__fixtures__/synergyRefinementFixtures.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: `sub_type` persistence, updated type enum, core naming + vocabulary modules

**⚠️ CRITICAL**: No user story work until this phase completes

- [ ] T003 Add Drizzle migration `sub_type TEXT` on `synergies` in `drizzle/` (update `src/lib/db/client.ts` bootstrap SQL if used)
- [ ] T004 Add `subType` column to `synergies` in `src/lib/db/schema.ts`
- [ ] T005 Update `SYNERGY_TYPES` (add `element`, rename `damage`→`dps`, exclude creatable `kinetic_weapon`) and add `subType` to zod schemas in `src/lib/synergies/schemas.ts`
- [ ] T006 [P] Add failing `generateSynergyName` tests (patterns, truncation, em dash) in `src/lib/synergies/generateSynergyName.test.ts`
- [ ] T007 Implement `generateSynergyName` in `src/lib/synergies/generateSynergyName.ts`
- [ ] T008 [P] Add failing `subTypeVocabularies` tests (verbs dedupe, Base prepend, elements include Kinetic) in `src/lib/synergies/subTypeVocabularies.test.ts`
- [ ] T009 Implement `listSubTypeOptions(category)` in `src/lib/synergies/subTypeVocabularies.ts` (verbs from `subclasses.meta`, abilities from manifest store, elements from `synergyElements.ts`)
- [ ] T010 [P] Add failing legacy migration tests in `src/lib/synergies/legacySynergyTypes.test.ts`
- [ ] T011 Implement `normalizeLegacySynergyType` in `src/lib/synergies/legacySynergyTypes.ts` (`kinetic_weapon`→element+Kinetic, `damage`→dps)
- [ ] T012 Persist and read `subType` in `src/lib/db/repositories/synergyRepository.ts` (create/update/list/get)

**Checkpoint**: Core libs pass unit tests; DB accepts `sub_type`; gate green on foundational modules

---

## Phase 3: User Story 1 — Auto-Generated Synergy Names (Priority: P1) 🎯 MVP

**Goal**: Server and debug UI compose names from category + sub-type + link (FR-001, FR-015)

**Independent Test**: Create Verb + Scorch + weapon link → saved name `Verb: Scorch — {weapon}` (quickstart Scenario 1)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before service wiring

- [ ] T013 [P] [US1] Add failing auto-name integration tests in `src/lib/synergies/synergyService.test.ts` (create/update overrides client name; DPS pattern without subType)

### Implementation for User Story 1

- [ ] T014 [US1] Apply `generateSynergyName` on create/update in `src/lib/synergies/synergyService.ts` (primary link = `links[0].displayName`)
- [ ] T015 [US1] Make `name` optional on create in `src/lib/synergies/schemas.ts`; include `subType` in API responses via repository
- [ ] T016 [US1] Add read-only auto-name preview in `src/app/debug/synergies/SynergiesDebugPage.tsx` (import `generateSynergyName`; update on category/subType/link change)
- [ ] T017 [US1] Run `npm run gate` and validate quickstart Scenario 1 (auto-name before create)

**Checkpoint**: User Story 1 — names auto-generated end-to-end

---

## Phase 4: User Story 2 — Sub-Types and Category Model (Priority: P1)

**Goal**: Required sub-types per category, Base for melee/grenade/super, Element+Kinetic, legacy migration (FR-002–FR-009)

**Independent Test**: Melee+Base saves; Verb without subType rejected; category list excludes Kinetic Weapon/Damage (quickstart Scenario 2)

### Tests for User Story 2 ⚠️

- [ ] T018 [P] [US2] Add failing sub-type validation tests in `src/lib/synergies/validateSynergySubType.test.ts`
- [ ] T019 [P] [US2] Add failing subtypes route tests in `src/app/api/catalog/synergy-pickers/subtypes/route.test.ts`

### Implementation for User Story 2

- [ ] T020 [US2] Implement `validateSynergySubType(type, subType)` in `src/lib/synergies/validateSynergySubType.ts`; wire in `src/lib/synergies/synergyService.ts` with `INVALID_SYNERGY_SUBTYPE` via `src/lib/api/errors.ts`
- [ ] T021 [US2] Apply `normalizeLegacySynergyType` on update in `src/lib/synergies/synergyService.ts`
- [ ] T022 [US2] Implement `GET /api/catalog/synergy-pickers/subtypes` in `src/app/api/catalog/synergy-pickers/subtypes/route.ts`
- [ ] T023 [US2] Replace creatable category list and add sub-type `<select>` (fed by subtypes API) in `src/app/debug/synergies/SynergiesDebugPage.tsx`
- [ ] T024 [US2] Run `npm run gate` and validate quickstart Scenario 2

**Checkpoint**: P1 complete — auto-name + sub-types + category model (MVP)

---

## Phase 5: User Story 3 — Multi-Synergy per Target (Priority: P1)

**Goal**: Reinforce many-to-many — multiple synergies on one weapon; reverse lookup + catalog badges show all (FR-010, FR-011)

**Independent Test**: DPS + Verb synergies on same weapon → by-target returns both (quickstart Scenario 3)

### Tests for User Story 3 ⚠️

- [ ] T025 [P] [US3] Add failing weapon `itemHash` dual-synergy reverse-lookup test in `src/lib/synergies/synergyService.test.ts`

### Implementation for User Story 3

- [ ] T026 [US3] Extend reverse-lookup form to support `itemHash` weapon queries in `src/app/debug/synergies/SynergiesDebugPage.tsx`
- [ ] T027 [US3] Ensure catalog synergy badges render **all** linked synergies (not first only) in `src/app/debug/catalog/CatalogDebugPage.tsx`
- [ ] T028 [US3] Run `npm run gate` and validate quickstart Scenario 3

**Checkpoint**: Multi-synergy associations verified in service + debug surfaces

---

## Phase 6: User Story 4 — Catalog-Backed Link Pickers (Priority: P2)

**Goal**: No free-text/hash link fields; searchable catalog pickers for all link kinds (FR-012, FR-013)

**Independent Test**: Each link kind uses picker only; submit without selection fails (quickstart Scenario 4)

### Tests for User Story 4 ⚠️

- [ ] T029 [P] [US4] Add failing links picker route tests in `src/app/api/catalog/synergy-pickers/links/route.test.ts`

### Implementation for User Story 4

- [ ] T030 [US4] Implement `GET /api/catalog/synergy-pickers/links` in `src/app/api/catalog/synergy-pickers/links/route.ts` (origin_trait, weapon_perk, armor_set_bonus from entity stores)
- [ ] T031 [US4] Add weapon link search select via `GET /api/catalog/weapons?q=` in `src/app/debug/synergies/SynergiesDebugPage.tsx`
- [ ] T032 [US4] Replace free-text origin_trait, weapon_perk, armor_set_bonus inputs with searchable selects in `src/app/debug/synergies/SynergiesDebugPage.tsx`
- [ ] T033 [US4] Remove manual `itemHash`/`perkHash` text fields; build `SynergyLink` from picker selection only
- [ ] T034 [US4] Run `npm run gate` and validate quickstart Scenario 4

**Checkpoint**: All link targets chosen from catalog pickers

---

## Phase 7: User Story 5 — Description Preview (Priority: P2)

**Goal**: Read-only description panel for selected link target (FR-014)

**Independent Test**: Select weapon → description visible; change link kind → description updates (quickstart Scenario 5)

### Implementation for User Story 5

- [ ] T035 [US5] Add read-only description panel below link picker in `src/app/debug/synergies/SynergiesDebugPage.tsx` (from catalog item or picker row `description`)
- [ ] T036 [US5] Clear/hide description when link selection cleared or link kind changes in `src/app/debug/synergies/SynergiesDebugPage.tsx`
- [ ] T037 [US5] Run `npm run gate` and validate quickstart Scenario 5

**Checkpoint**: Description preview for all four link kinds

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, legacy migration manual check, final gate

- [ ] T038 [P] Update synergy debug flows in `DEBUG.md` (auto-name, sub-types, pickers, multi-synergy)
- [ ] T039 [P] Add legacy migration note to `specs/006-synergy-refinement/quickstart.md` Scenario 6 if steps drift
- [ ] T040 Run full `specs/006-synergy-refinement/quickstart.md` validation and `npm run gate`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundational (needs `generateSynergyName`, schema, repository)
- **US2 (Phase 4)**: Depends on US1 for full MVP (validation + sub-type UI; can start T018–T020 in parallel after T005)
- **US3 (Phase 5)**: Depends on Foundational only (service layer); can parallel US4 after US2
- **US4 (Phase 6)**: Depends on US2 sub-type UI stable; independent of US3
- **US5 (Phase 7)**: Depends on US4 pickers (description from picker rows)
- **Polish (Phase 8)**: Depends on US1–US5 desired scope

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| US1 | Foundational | Auto-name on create |
| US2 | Foundational + US1 name wiring | Sub-type validation + category list |
| US3 | Foundational | Dual synergy reverse lookup |
| US4 | US2 (category form) | Picker-only link fields |
| US5 | US4 | Description panel |

### Parallel Opportunities

- **Phase 1**: T001 ∥ T002
- **Phase 2**: T006 ∥ T008 ∥ T010 (tests); after T005, T007/T009/T011 sequential per file
- **Phase 3**: T013 ∥ (after T012)
- **Phase 4**: T018 ∥ T019; T022 after T009
- **Phase 5**: T025 ∥ T026 prep
- **Phase 6**: T029 ∥ T030 after manifest test helpers
- **Phase 8**: T038 ∥ T039

---

## Parallel Example: Foundational

```bash
# Tests in parallel (confirm FAIL first):
T006 generateSynergyName.test.ts
T008 subTypeVocabularies.test.ts
T010 legacySynergyTypes.test.ts

# Then implement matching modules:
T007 → T009 → T011 → T012
```

---

## Parallel Example: User Story 4

```bash
# Route test + implementation:
T029 links/route.test.ts
T030 links/route.ts

# Debug UI (same file — sequential):
T031 → T032 → T033
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US1 (auto-names)
4. Complete Phase 4: US2 (sub-types + categories)
5. **STOP and VALIDATE** quickstart Scenarios 1–2 + gate

### Incremental Delivery

1. Setup + Foundational → core libs ready
2. US1 + US2 → MVP (creatable synergies with auto-name + sub-types)
3. US3 → multi-synergy verification
4. US4 → catalog pickers (no free-text)
5. US5 → description preview
6. Polish → DEBUG.md + full quickstart

### Suggested MVP Scope

**Phases 1–4** (T001–T024): Auto-generated names, sub-types, updated categories, debug form for category/sub-type/name. Link pickers can remain minimal until US4 if needed for US1 testing (use existing test harness with programmatic links in service tests).

---

## Notes

- Many-to-many already implemented in `synergyRepository` / `synergyService.test.ts` — US3 is verification + UI, not schema work
- `validateSynergyLink.ts` unchanged for link kinds; pickers must produce valid link payloads
- Commit only after each phase checkpoint with green gate
- Total tasks: **40** (Setup 2, Foundational 10, US1 5, US2 7, US3 4, US4 6, US5 3, Polish 3)
