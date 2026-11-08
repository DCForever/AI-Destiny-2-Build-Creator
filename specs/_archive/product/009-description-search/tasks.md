---
description: "Task list for Description Search for Pickers feature"
---

# Tasks: Description Search for Pickers

**Input**: Design documents from `/specs/009-description-search/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Foundational `descriptionMatch` blocks all stories. US1 + US2 + US5 are P1 (perk/trait pickers, subtypes, set bonus/exotics/manifest). US3 + US4 are P2 (catalog filter parity verification, UI descriptions in lists).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US5)

## Path Conventions

- Shared search: `src/lib/search/`
- Synergies pickers: `src/lib/synergies/`
- Catalog filters: `src/lib/catalog/`
- Manifest search: `src/lib/manifest/itemResolver.ts`
- API: `src/app/api/catalog/`, `src/app/api/manifest/search/`
- Debug UI: `src/app/debug/synergies/`, `src/app/debug/catalog/`
- Docs: `specs/009-description-search/quickstart.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Test fixtures with name-only vs description-only match samples for all entity scopes

- [X] T001 [P] Add description search test fixtures (perk/trait/set tier/exotic intrinsic samples) in `src/lib/search/__fixtures__/descriptionSearchFixtures.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared `descriptionMatch` module used by every search surface

**⚠️ CRITICAL**: No user story work until this phase completes

- [X] T002 [P] Add failing `descriptionMatch` tests (substring, case-insensitive, name vs description rank, empty query) in `src/lib/search/descriptionMatch.test.ts`
- [X] T003 Implement `matchDescriptionQuery`, `compareMatchRank`, and `matchByNameOrDescription` helpers in `src/lib/search/descriptionMatch.ts`

**Checkpoint**: `descriptionMatch` tests pass; gate green on foundational module

---

## Phase 3: User Story 1 — Find Perks and Traits by Effect Keyword (Priority: P1) 🎯 MVP

**Goal**: Weapon perk and origin trait pickers + filter resolvers match name **or** description (FR-001, FR-002)

**Independent Test**: `GET /api/catalog/synergy-pickers/links?kind=weapon_perk&q=melee` returns perks whose description contains "melee"; `perk` filter resolves by description keyword (quickstart §1–2, §6)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T004 [P] [US1] Add failing description-match tests for `resolvePerkFilter` and `resolveOriginTraitFilter` in `src/lib/catalog/perkTraitFilters.test.ts`
- [X] T005 [P] [US1] Add failing description-match tests for `searchSynergyLinkPickerItems` (weapon_perk, origin_trait) in `src/lib/synergies/synergyPickerLinks.test.ts`
- [X] T006 [P] [US1] Add failing links route contract tests for description `q` on weapon_perk and origin_trait in `src/app/api/catalog/synergy-pickers/links/route.test.ts`

### Implementation for User Story 1

- [X] T007 [US1] Extend `matchByName` to use `descriptionMatch` for perk and trait records in `src/lib/catalog/perkTraitFilters.ts`
- [X] T008 [US1] Extend `searchSynergyLinkPickerItems` weapon_perk and origin_trait filters to match `description` in `src/lib/synergies/synergyPickerLinks.ts`; apply `compareMatchRank` before `finalizePickerItems`
- [X] T009 [US1] Wire description-ranked results through `src/app/api/catalog/synergy-pickers/links/route.ts` (no schema change; verify DTO `description` populated)
- [X] T010 [US1] Run `npm run gate` and validate quickstart §1–2 and §6 perk-filter portion

**Checkpoint**: User Story 1 — perk/trait description search in synergy pickers and perk/originTrait filter resolvers

---

## Phase 4: User Story 2 — Find Synergy Sub-Types by Description (Priority: P1)

**Goal**: Melee/Grenade/Super/Verb subtype pickers match ability/verb descriptions (FR-003)

**Independent Test**: `GET /api/catalog/synergy-pickers/subtypes?category=melee&q={keyword from ability description}` returns match with description (quickstart §4)

### Tests for User Story 2 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T011 [P] [US2] Add failing `filterSubTypeOptions` description-match tests in `src/lib/synergies/subTypeVocabularies.test.ts`
- [X] T012 [P] [US2] Add failing subtypes route contract tests for description `q` in `src/app/api/catalog/synergy-pickers/subtypes/route.test.ts`

### Implementation for User Story 2

- [X] T013 [US2] Extend `filterSubTypeOptions` to match `option.description` via `descriptionMatch` in `src/lib/synergies/subTypeVocabularies.ts`
- [X] T014 [US2] Verify subtypes route passes through ranked options in `src/app/api/catalog/synergy-pickers/subtypes/route.ts`
- [X] T015 [US2] Run `npm run gate` and validate quickstart §4

**Checkpoint**: User Story 2 — subtype picker description search

---

## Phase 5: User Story 5 — Set Bonuses, Exotics, and Other Described Entities (Priority: P1)

**Goal**: Set bonus tier descriptions, exotic intrinsic search in catalog `q` and manifest search (FR-012, FR-013, FR-014, FR-017)

**Independent Test**: Set bonus picker matches tier description; catalog `q` finds exotic by intrinsic text; manifest search finds exotic-weapons by intrinsic description (quickstart §3, §5, §7–8)

### Tests for User Story 5 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T016 [P] [US5] Add failing tier-description tests for `resolveSetBonusFilter` in `src/lib/catalog/setBonusFilter.test.ts`
- [X] T017 [P] [US5] Add failing armor_set_bonus description tests in `src/lib/synergies/synergyPickerLinks.test.ts`
- [X] T018 [P] [US5] Add failing catalog `q` intrinsic-description tests for exotic weapons in `src/lib/catalog/filterItems.test.ts`
- [X] T019 [P] [US5] Add failing manifest search description tests for exotic-weapons in `src/lib/manifest/itemResolver.test.ts`

### Implementation for User Story 5

- [X] T020 [US5] Extend `resolveSetBonusFilter` to match tier perk name and description in `src/lib/catalog/setBonusFilter.ts`
- [X] T021 [US5] Extend `armor_set_bonus` branch to match `perk.description` and rank results in `src/lib/synergies/synergyPickerLinks.ts`
- [X] T022 [US5] Project `intrinsicName` and `intrinsicDescription` on `SearchableCatalogRow` and add Fuse keys in `src/lib/catalog/filterItems.ts` (`weaponToCatalog` / `armorToCatalog`)
- [X] T023 [US5] Extend per-store Fuse index keys to include `description` and exotic intrinsic description in `src/lib/manifest/itemResolver.ts`
- [X] T024 [US5] Extend manifest search route allowed categories for description search on mods/aspects/fragments/artifacts if not already covered in `src/app/api/manifest/search/route.ts`
- [X] T025 [US5] Run `npm run gate` and validate quickstart §3, §5, §7–8

**Checkpoint**: User Story 5 — set bonus, exotic intrinsic, and manifest description search

---

## Phase 6: User Story 3 — Catalog and Sets Filter Parity (Priority: P2)

**Goal**: Catalog weapons/armor routes and Sets/Catalog debug filters use description-aware perk, originTrait, and setBonus resolution end-to-end (FR-009, FR-015)

**Independent Test**: `GET /api/catalog/weapons?perk={description-only keyword}` and `GET /api/catalog/armor?setBonus={tier-description keyword}` return expected rows (quickstart §6–7)

### Tests for User Story 3 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T026 [P] [US3] Add failing weapons route tests for description-only `perk` and `originTrait` params in `src/app/api/catalog/weapons/route.test.ts`
- [X] T027 [P] [US3] Add failing armor route tests for description-only `setBonus` param in `src/app/api/catalog/armor/route.test.ts`
- [X] T028 [P] [US3] Add regression test that catalog `q` does NOT match rollable perk descriptions (FR-019) in `src/lib/catalog/filterItems.test.ts`

### Implementation for User Story 3

- [X] T029 [US3] Verify weapons route uses updated `resolvePerkFilter` / `resolveOriginTraitFilter` and empty-filter messages in `src/app/api/catalog/weapons/route.ts`
- [X] T030 [US3] Verify armor route uses updated `resolveSetBonusFilter` in `src/app/api/catalog/armor/route.ts`
- [X] T031 [US3] Validate Sets debug perk/setBonus filters inherit description resolution via catalog API in `src/app/debug/sets/SetsDebugPage.tsx` (no code change if already wired; document or fix gaps)
- [X] T032 [US3] Run `npm run gate` and validate quickstart §6–7 and regression §9

**Checkpoint**: User Story 3 — catalog/Sets filter parity with description keywords

---

## Phase 7: User Story 4 — Descriptions Visible in Result Lists (Priority: P2)

**Goal**: Debug picker UIs show description text in search results before selection (FR-005, US4)

**Independent Test**: Synergies debug link/subtype pickers render description per row; catalog debug shows intrinsic description for exotics (quickstart §1, §5)

### Implementation for User Story 4

- [X] T033 [US4] Render description excerpt (with unavailable indicator) in link and subtype picker result lists in `src/app/debug/synergies/SynergiesDebugPage.tsx`
- [X] T034 [US4] Add optional description column or secondary line for exotic catalog rows in `src/app/debug/catalog/CatalogDebugPage.tsx`
- [X] T035 [US4] Run `npm run gate` and validate quickstart §1 and §5 UI portions

**Checkpoint**: User Story 4 — informed selection with visible descriptions in lists

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Regression, contract alignment, full feature validation

- [X] T036 [P] Add description-search contract alignment notes or cross-links in `specs/009-description-search/contracts/description-search-contract.md` if implementation diverged (update doc only if needed)
- [X] T037 [P] Verify name-only searches unchanged (regression) across `perkTraitFilters.test.ts`, `setBonusFilter.test.ts`, and `synergyPickerLinks.test.ts`
- [X] T038 Run full manual validation per `specs/009-description-search/quickstart.md` (all 9 scenarios + regression §9)
- [X] T039 Run `npm run gate` as final feature checkpoint

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Foundational — MVP for perk/trait discovery
- **US2 (Phase 4)**: Depends on Foundational — independent of US1 (parallel after Phase 2)
- **US5 (Phase 5)**: Depends on Foundational — uses `descriptionMatch`; independent of US1/US2 for domain files
- **US3 (Phase 6)**: Depends on US1 + US5 (filter resolvers and catalog fuse must land first)
- **US4 (Phase 7)**: Depends on US1 + US2 + US5 (APIs return descriptions; UI displays them)
- **Polish (Phase 8)**: Depends on all desired user stories

### User Story Dependencies

```text
Foundational (T002–T003)
    ├── US1 (T004–T010) ──┐
    ├── US2 (T011–T015) ──┼──► US4 (T033–T035)
    └── US5 (T016–T025) ──┴──► US3 (T026–T032)
```

- **US1**: Independent after Foundational — MVP
- **US2**: Independent after Foundational — parallel with US1/US5
- **US5**: Independent after Foundational — parallel with US1/US2
- **US3**: Requires US1 perk/trait resolvers + US5 setBonus resolver
- **US4**: Requires picker APIs from US1/US2/US5

### Within Each User Story

- Tests MUST fail before implementation (constitution)
- Domain libs before route handlers
- Routes before debug UI (US4)
- `npm run gate` at each story checkpoint

### Parallel Opportunities

- **Phase 1**: T001 standalone
- **Phase 2**: T002 ∥ T001 (fixtures before tests that import them — sequence T001 then T002)
- **US1 tests**: T004 ∥ T005 ∥ T006
- **US2 tests**: T011 ∥ T012
- **US5 tests**: T016 ∥ T017 ∥ T018 ∥ T019
- **Cross-story after Foundational**: US1 implementation ∥ US2 tests ∥ US5 tests
- **Polish**: T036 ∥ T037

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests together:
T004: src/lib/catalog/perkTraitFilters.test.ts
T005: src/lib/synergies/synergyPickerLinks.test.ts
T006: src/app/api/catalog/synergy-pickers/links/route.test.ts

# After T003 descriptionMatch.ts lands:
T007: src/lib/catalog/perkTraitFilters.ts
T008: src/lib/synergies/synergyPickerLinks.ts
```

---

## Parallel Example: User Story 5

```bash
# US5 can start tests while US1 implementation finishes:
T016: src/lib/catalog/setBonusFilter.test.ts
T017: src/lib/synergies/synergyPickerLinks.test.ts  # coordinate — same file as US1; sequence or single PR
T018: src/lib/catalog/filterItems.test.ts
T019: src/lib/manifest/itemResolver.test.ts
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1: Setup fixtures
2. Complete Phase 2: Foundational `descriptionMatch`
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: quickstart §1–2, §6 perk portion
5. Perk/trait description search usable in synergy pickers

### Incremental Delivery

1. Setup + Foundational → shared matcher ready
2. US1 → perk/trait pickers + filter resolvers (MVP)
3. US2 → subtype pickers
4. US5 → set bonus tier + exotic intrinsic + manifest
5. US3 → catalog/Sets filter parity verification
6. US4 → descriptions in debug UI lists
7. Polish → gate + quickstart

### Suggested MVP Scope

**User Story 1 only** (T001–T010): delivers core user ask (search perks by effect keyword in pickers) with shared `descriptionMatch` foundation.

**Recommended P1 bundle**: US1 + US2 + US5 (T001–T025) before UI polish — all description-bearing entity types searchable via API.

---

## Notes

- `synergyPickerLinks.test.ts` and `synergyPickerLinks.ts` are shared by US1 and US5 — implement US1 perk/trait branches first, append US5 set-bonus tests in same file or split `describe` blocks
- `perkTraitFilters` changes satisfy most of US3 weapons path; US3 phase focuses on route tests + armor `setBonus` + FR-019 regression
- No DB migrations; read-only manifest search only
- Commit only at green checkpoints per story (`npm run gate`)

---

## Task Summary

| Phase | Story | Task IDs | Count |
|-------|-------|----------|-------|
| 1 Setup | — | T001 | 1 |
| 2 Foundational | — | T002–T003 | 2 |
| 3 US1 Perk/trait | US1 | T004–T010 | 7 |
| 4 US2 Subtypes | US2 | T011–T015 | 5 |
| 5 US5 Set bonus/exotics | US5 | T016–T025 | 10 |
| 6 US3 Catalog parity | US3 | T026–T032 | 7 |
| 7 US4 UI lists | US4 | T033–T035 | 3 |
| 8 Polish | — | T036–T039 | 4 |
| **Total** | | **T001–T039** | **39** |

**Independent test criteria**:

| Story | Verify |
|-------|--------|
| US1 | Synergy links API + perk/trait filter resolvers match description keywords |
| US2 | Subtypes API matches ability/verb descriptions |
| US5 | Set bonus tier text, exotic intrinsic catalog `q`, manifest search |
| US3 | Catalog weapons/armor routes + Sets filters; FR-019 regression |
| US4 | Debug UI shows descriptions in result lists before selection |
