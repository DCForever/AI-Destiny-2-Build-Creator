# Tasks: DART-062 Catalog Browse Semantics

**Input**: Design documents from `/specs/dart-062-catalog-browse-semantics/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-062-catalog-browse-semantics`
- [x] T002 Branch `dart-062-catalog-browse-semantics` from `feature/multiplatform-dart`

## Phase 2: Foundational pure APIs

- [x] T003 [P] Add `compareDisplayName` / `sortCatalogByDisplayName` in `packages/manifest/lib/src/catalog/sort_by_name.dart`; export
- [x] T004 [P] Add `groupCatalogItems` + dimension enums/labels in `packages/manifest/lib/src/catalog/group_catalog.dart`; export
- [x] T005 Alpha-sort finalize in `filterCatalogClient` (`filter_catalog.dart`); update order expectations in tests
- [x] T006 Unit tests `group_catalog_test.dart` + alpha sort cases in `filter_catalog_test.dart`

## Phase 3: US4 Exotic weapons (P1)

- [x] T007 [P] Add `ExoticWeaponRecord` + `MvpStoreName.exoticWeapons` encode/decode
- [x] T008 [P] Implement `ExoticWeaponsExtractor` + registry entry
- [x] T009 Project exotic weapons in `catalog_projector.dart`, OfflineCatalog load, EntityBundle
- [x] T010 Fixture Gjallarhorn (or equivalent) in raw_tables + extractor tests

## Phase 4: US5 Legendary armor (P1)

- [x] T011 [P] Add `LegendaryArmorRecord` + `MvpStoreName.legendaryArmor` encode/decode
- [x] T012 [P] Implement `LegendaryArmorExtractor` + registry entry
- [x] T013 Project legendary armor in projector / OfflineCatalog / EntityBundle
- [x] T014 Fixture legendary armor in raw_tables + extractor tests

## Phase 5: US1 Multi-facet hosts (P1)

- [x] T015 Windows `catalog_page.dart`: slot, class, archetype facet chips + filter wiring
- [x] T016 Jaspr `catalog_page.dart`: same facet rows
- [x] T017 Host tests for slot/class/archetype chip filtering

## Phase 6: US2 Group-by hosts (P1) + US3 alpha (P2)

- [x] T018 Windows group-by multi-select + grouped ListView headers
- [x] T019 Jaspr group-by multi-select + section headers
- [x] T020 Host tests asserting group headers and filter count invariant
- [x] T021 Sample exotic-weapons + legendary-armor rows in web entity bundles

## Phase 7: Finish

- [x] T022 Run package + host catalog tests; fix failures
- [x] T023 Update roadmap / gap status; commit; merge to `feature/multiplatform-dart`
