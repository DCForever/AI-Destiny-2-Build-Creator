---
description: "Task list for Sets Catalog-Style Item Lookup feature"
---

# Tasks: Sets Catalog-Style Item Lookup

**Input**: Design documents from `/specs/008-sets-catalog-lookup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Per constitution (Test-First NON-NEGOTIABLE): write co-located `*.test.ts` first, confirm they fail, then implement. Run `npm run gate` at each story checkpoint before commit.

**Organization**: Foundational catalog type extensions block all stories. US1 and US2 are both P1 (weapon perk/trait + armor set bonus). US3 adds stat sync/sort. US4 wires debug Sets picker composing catalog + instance APIs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US4)

## Path Conventions

- Catalog domain: `src/lib/catalog/`
- Sets slot mapping: `src/lib/sets/`
- Inventory instances: `src/lib/inventory/instances/`
- Bungie sync: `src/lib/bungie/`
- DB: `src/lib/db/schema.ts`, `src/lib/db/client.ts`, `src/lib/db/types.ts`
- API: `src/app/api/catalog/`, `src/app/api/user/inventory/instances/`
- Debug: `src/app/debug/sets/SetsDebugPage.tsx`
- Docs: `specs/008-sets-catalog-lookup/quickstart.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Test fixtures and set-slot → catalog-bucket mapping shared by picker UI and API clients

- [X] T001 [P] Add set lookup test fixtures (sample perks, origin traits, set bonuses, weapon/armor hashes) in `src/lib/catalog/__fixtures__/setLookupFixtures.ts`
- [X] T002 [P] Add failing `setSlotToCatalogBucket` tests in `src/lib/sets/catalogSlotMap.test.ts`
- [X] T003 Implement `setSlotToCatalogBucket` and `catalogBucketForSetType` in `src/lib/sets/catalogSlotMap.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extended catalog types and filter params used by US1–US2

**⚠️ CRITICAL**: No user story work until this phase completes

- [X] T004 Extend `CatalogItem` (`setBonusName`, `setBonusHash`) and `CatalogFilterParams` (`perk`, `originTrait`, `setBonus`) in `src/lib/catalog/types.ts`
- [X] T005 [P] Add failing empty-result message helper tests in `src/lib/catalog/emptyFilterResult.test.ts`
- [X] T006 Implement `emptyFilterMessage` for unresolved perk/trait/setBonus filters in `src/lib/catalog/emptyFilterResult.ts`

**Checkpoint**: Types compile; slot map tests pass; gate green on foundational modules

---

## Phase 3: User Story 1 — Find Weapons by Perk or Origin Trait (Priority: P1) 🎯 MVP

**Goal**: Extend weapon catalog with `perk` and `originTrait` filters; instance drill-down via existing `q` param (FR-002, FR-003, FR-004)

**Independent Test**: `GET /api/catalog/weapons?perk=Incandescent` returns only matching weapons; select owned row → `GET /api/user/inventory/instances?itemHash=…&q=Incandescent` filters copies (quickstart §1–2)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T007 [P] [US1] Add failing `perkTraitFilters` tests (resolve perk/trait name/hash, empty when unresolvable) in `src/lib/catalog/perkTraitFilters.test.ts`
- [X] T008 [P] [US1] Add failing weapon catalog filter tests (`perk`, `originTrait`, AND semantics) in `src/lib/catalog/filterItems.test.ts`
- [X] T009 [P] [US1] Add failing weapons route contract tests for `perk` and `originTrait` query params in `src/app/api/catalog/weapons/route.test.ts`

### Implementation for User Story 1

- [X] T010 [US1] Implement `resolvePerkFilter` and `resolveOriginTraitFilter` using `weapon-perks`, `origin-traits`, and `perkWeaponIndex` in `src/lib/catalog/perkTraitFilters.ts`
- [X] T011 [US1] Extend `filterWeaponCatalog` to apply perk/originTrait filters before fuse search in `src/lib/catalog/filterItems.ts`
- [X] T012 [US1] Add `perk` and `originTrait` to zod query schema and pass to `filterWeaponCatalog` in `src/app/api/catalog/weapons/route.ts`; return `message` on empty unresolved filter per contract
- [X] T013 [US1] Load `perkWeaponIndex` in weapons route when `perk` param present (via `loadPerkWeaponIndex` from manifest version)
- [X] T014 [US1] Run `npm run gate` and validate quickstart §1–2 (API or debug catalog with new params)

**Checkpoint**: User Story 1 — weapon perk/trait catalog filter works end-to-end via API

---

## Phase 4: User Story 2 — Find Armor by Set Bonus (Priority: P1)

**Goal**: Project legendary armor from `set-bonuses` and filter by `setBonus` param (FR-005, FR-006)

**Independent Test**: `GET /api/catalog/armor?setBonus=Eutechnology&slot=Helmet` returns only set member helmets (quickstart §3)

### Tests for User Story 2 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T015 [P] [US2] Add failing `buildLegendaryArmorCatalogRows` tests in `src/lib/catalog/legendaryArmor.test.ts`
- [X] T016 [P] [US2] Add failing armor `setBonus` filter tests in `src/lib/catalog/filterItems.test.ts`
- [X] T017 [P] [US2] Add failing armor route contract tests for `setBonus` param in `src/app/api/catalog/armor/route.test.ts`

### Implementation for User Story 2

- [X] T018 [US2] Implement `buildLegendaryArmorCatalogRows` (set-bonuses `itemHashes` + manifest item projection) in `src/lib/catalog/legendaryArmor.ts`
- [X] T019 [US2] Implement `resolveSetBonusFilter` (name substring or hash → matching `SetBonusRecord`s) in `src/lib/catalog/setBonusFilter.ts` with co-located `src/lib/catalog/setBonusFilter.test.ts` (tests first)
- [X] T020 [US2] Extend `filterArmorCatalog` to merge legendary rows when `setBonus` set (exotic-only when unset) and apply set bonus + slot/class filters in `src/lib/catalog/filterItems.ts`
- [X] T021 [US2] Add `setBonus` to zod query schema; load `set-bonuses` store and pass legendary source to `filterArmorCatalog` in `src/app/api/catalog/armor/route.ts`
- [X] T022 [US2] Run `npm run gate` and validate quickstart §3

**Checkpoint**: P1 complete — weapon perk/trait + armor set bonus catalog filters (MVP for catalog APIs)

---

## Phase 5: User Story 3 — Rank Owned Armor by Highest Stat (Priority: P2)

**Goal**: Capture armor stats at sync; sort owned instances by `sortBy` (FR-007)

**Independent Test**: After re-sync, `GET /api/user/inventory/instances?itemHash=…&kind=armor&sortBy=Melee` returns copies highest-first (quickstart §4)

### Tests for User Story 3 ⚠️

> Write FIRST; confirm FAIL before implementation

- [X] T023 [P] [US3] Add failing `parseArmorStatValues` tests (six Armor 3.0 stats, partial/missing) in `src/lib/inventory/instances/parseArmorStats.test.ts`
- [X] T024 [P] [US3] Add failing `sortInstancesByStat` tests (dimension, total, ties, incomplete last) in `src/lib/inventory/instances/sortInstances.test.ts`
- [X] T025 [P] [US3] Add failing instances route `sortBy` contract tests in `src/app/api/user/inventory/instances/route.test.ts`
- [X] T026 [P] [US3] Add failing profile stat parse tests in `src/lib/bungie/profile.test.ts`

### Implementation for User Story 3

- [X] T027 [US3] Add `ensureStatValuesColumn` migration (`stat_values TEXT`) in `src/lib/db/client.ts` and `statValues` column in `src/lib/db/schema.ts`
- [X] T028 [US3] Extend `UserInventoryItem` and inventory repository read/write for `statValues` in `src/lib/db/types.ts` and `src/lib/db/repositories/inventoryRepository.ts`
- [X] T029 [US3] Implement `parseArmorStatValues` from Bungie `itemComponents.stats` in `src/lib/inventory/instances/parseArmorStats.ts`; wire parse in `src/lib/bungie/profile.ts` for armor buckets
- [X] T030 [US3] Persist `stat_values` JSON on armor rows during sync in `src/lib/bungie/syncInventory.ts`
- [X] T031 [US3] Extend `OwnedInstanceDetail` with `statValues`, `totalStats`, `statsIncomplete` in `src/lib/inventory/instances/types.ts`
- [X] T032 [US3] Project stat fields in `projectInstance` in `src/lib/inventory/instances/projectInstance.ts`
- [X] T033 [US3] Implement `sortInstancesByStat` and integrate into `listUserInstances` when `sortBy` set in `src/lib/inventory/instances/sortInstances.ts` and `src/lib/inventory/instances/listUserInstances.ts`
- [X] T034 [US3] Add `sortBy` to zod query schema and `InstanceFilterCriteria` in `src/app/api/user/inventory/instances/route.ts`
- [X] T035 [US3] Run `npm run gate` and validate quickstart §4 (re-sync required for stat data)

**Checkpoint**: User Story 3 — armor instance stat sort works via API

---

## Phase 6: User Story 4 — Unified Picker Flow in Debug Sets UI (Priority: P2)

**Goal**: Replace manual hash entry with catalog browse → instance drill-down → attach on `/debug/sets` (FR-001, FR-008, FR-012)

**Independent Test**: Add weapon to set using only picker (perk filter, select instance, Put item) without typing `itemHash` (quickstart §1 + §5)

### Implementation for User Story 4

- [X] T036 [US4] Add **Item lookup** fieldset to `src/app/debug/sets/SetsDebugPage.tsx` (scope, q, slot locked via `catalogSlotMap`, weapon: perk + originTrait; armor: setBonus + className)
- [X] T037 [US4] Wire catalog search to `GET /api/catalog/weapons` or `GET /api/catalog/armor` with `includeInstancePointer=1` in `src/app/debug/sets/SetsDebugPage.tsx`
- [X] T038 [US4] On catalog row select: auto-fetch instances (`q` from active perk/trait; `sortBy` for armor) and render selectable instance list in `src/app/debug/sets/SetsDebugPage.tsx`
- [X] T039 [US4] On instance select: populate `itemForm` (`itemHash`, `itemName`, `selectedPerks` from plug hashes) and enable existing Put item flow in `src/app/debug/sets/SetsDebugPage.tsx`
- [X] T040 [US4] Move manual `itemHash` / `selectedPerks` inputs under collapsible **Advanced / fallback** section in `src/app/debug/sets/SetsDebugPage.tsx`
- [X] T041 [US4] Optional: wire set bonus name suggestions from `GET /api/catalog/synergy-pickers/links?kind=armor_set_bonus&q=` in `src/app/debug/sets/SetsDebugPage.tsx`
- [X] T042 [US4] Run `npm run gate` and validate quickstart §1–5 (full picker happy path + slot replace confirmation)

**Checkpoint**: User Story 4 — debug Sets picker matches Catalog interaction model

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Regression, docs, and full feature validation

- [X] T043 [P] Verify existing `src/lib/sets/setService.test.ts` and catalog tests pass unchanged (FR-012 slot replace, stale items)
- [X] T044 [P] Add weapons/armor catalog filter performance smoke test or document &lt;5s expectation in `src/lib/catalog/filterItems.test.ts` if not already covered
- [X] T045 Run full manual validation per `specs/008-sets-catalog-lookup/quickstart.md` (all scenarios + regression §5)
- [X] T046 Run `npm run gate` as final feature checkpoint

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: Depends on Foundational — no dependency on US2–US4
- **US2 (Phase 4)**: Depends on Foundational — independent of US1 (parallel catalog domain, different files)
- **US3 (Phase 5)**: Depends on Foundational — independent of US1/US2 for API testing; US4 needs US3 for armor stat sort UI
- **US4 (Phase 6)**: Depends on US1 + US2 (catalog filters); US3 for armor stat sort in picker
- **Polish (Phase 7)**: Depends on desired user stories complete

### User Story Dependencies

```text
Foundational (T004–T006)
    ├── US1 (T007–T014) ──┐
    ├── US2 (T015–T022) ──┼──► US4 (T036–T042)
    └── US3 (T023–T035) ──┘
```

- **US1**: Independent after Foundational — MVP for weapon set curation
- **US2**: Independent after Foundational — can parallel with US1
- **US3**: Independent after Foundational — can parallel with US1/US2 until US4
- **US4**: Requires US1 + US2 APIs; armor stat sort UI requires US3

### Within Each User Story

- Tests MUST fail before implementation (constitution)
- Domain libs before route handlers
- Routes before debug UI (US4)
- `npm run gate` at each story checkpoint

### Parallel Opportunities

- **Phase 1**: T001 ∥ T002
- **Phase 2**: T005 ∥ T004 (after T004 types land, T005–T006 sequential)
- **US1 tests**: T007 ∥ T008 ∥ T009
- **US2 tests**: T015 ∥ T016 ∥ T017
- **US3 tests**: T023 ∥ T024 ∥ T025 ∥ T026
- **Cross-story**: US1 implementation (T010–T013) ∥ US2 tests (T015–T017) after Foundational
- **Polish**: T043 ∥ T044

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests together:
T007: src/lib/catalog/perkTraitFilters.test.ts
T008: src/lib/catalog/filterItems.test.ts
T009: src/app/api/catalog/weapons/route.test.ts

# After T010 perkTraitFilters.ts lands:
T011: src/lib/catalog/filterItems.ts
T012: src/app/api/catalog/weapons/route.ts
```

---

## Parallel Example: User Story 2

```bash
# US2 can start tests while US1 implementation finishes:
T015: src/lib/catalog/legendaryArmor.test.ts
T016: src/lib/catalog/filterItems.test.ts  # coordinate with US1 — same file, sequence or single PR
T017: src/app/api/catalog/armor/route.test.ts
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: quickstart §1–2 via API
5. Weapon set curation by perk/trait is usable (Catalog or curl)

### Incremental Delivery

1. Setup + Foundational → types and slot map ready
2. US1 → weapon perk/trait catalog (MVP)
3. US2 → armor set bonus catalog (P1 complete)
4. US3 → stat capture + instance sort
5. US4 → debug Sets picker (full spec verification)
6. Polish → gate + quickstart

### Suggested MVP Scope

**User Story 1 only** (T001–T014): delivers weapon perk/origin trait lookup via extended catalog API — highest-priority user ask, independently testable without UI.

**Recommended P1 bundle**: US1 + US2 (T001–T022) before UI work — both are P1 and complete catalog-side discovery.

---

## Notes

- `filterItems.test.ts` is shared by US1 and US2 — implement US1 weapon tests first, append US2 armor tests in same file or split describe blocks
- Stat ranking requires **inventory re-sync** after US3 lands to populate `stat_values`
- No `set_items` schema change — picker maps instance → `itemHash` + `selectedPerks` only
- Commit only at green checkpoints per story (`npm run gate`)

---

## Task Summary

| Phase | Story | Task IDs | Count |
|-------|-------|----------|-------|
| 1 Setup | — | T001–T003 | 3 |
| 2 Foundational | — | T004–T006 | 3 |
| 3 US1 Weapon perk/trait | US1 | T007–T014 | 8 |
| 4 US2 Armor set bonus | US2 | T015–T022 | 8 |
| 5 US3 Stat sort | US3 | T023–T035 | 13 |
| 6 US4 Debug picker | US4 | T036–T042 | 7 |
| 7 Polish | — | T043–T046 | 4 |
| **Total** | | **T001–T046** | **46** |

**Independent test criteria**:

| Story | Verify |
|-------|--------|
| US1 | Catalog weapons API with `perk` / `originTrait`; instance `q` drill-down |
| US2 | Catalog armor API with `setBonus` + slot; legendary rows present |
| US3 | Instance API `sortBy`; stats on DTO after sync |
| US4 | Debug Sets add-item without manual hash; replace confirmation preserved |
