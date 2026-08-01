# Tasks: DART-063 Catalog Universal Modes, Synergy Tags, Owned Detail

**Input**: Design documents from `/specs/dart-063-catalog-universal-modes-synergy-tags/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-063-catalog-universal-modes-synergy-tags`
- [x] T002 Branch `dart-063-catalog-universal-modes-synergy-tags` from `feature/multiplatform-dart`

## Phase 2: Pure browse modes + composition (US1/US2)

- [x] T003 [P] Add `CatalogBrowseMode` + `itemsForBrowseMode` in `packages/manifest/lib/src/catalog/catalog_browse_mode.dart`; export
- [x] T004 [P] Add composition kinds + `hitActions` / labels in `composition_kinds.dart`; export
- [x] T005 Mode-specific facet option helpers in `filter_options.dart`
- [x] T006 Unit tests `catalog_browse_mode_test.dart` + `composition_kinds_test.dart`

## Phase 3: Linked synergies + reverse lookup (US3/US4)

- [x] T007 [P] Add `annotateCatalogWithLinkedSynergies` + build map helpers in `linked_synergies.dart`
- [x] T008 [P] DB `findSynergiesByTarget` + `findSynergiesByItemHashes` in synergy_repository
- [x] T009 App use-case wrappers for reverse lookup
- [x] T010 Unit tests linked synergies + reverse lookup

## Phase 4: Owned instance detail enrichment (US5)

- [x] T011 Expand `CatalogInstanceProjection` with socketPlugs, statValues, gearTier, resolved plug cards + builder
- [x] T012 Unit tests for enriched projection / armor stat board helpers

## Phase 5: Host bridges + UI (Windows + Jaspr)

- [x] T013 Windows OwnedCatalogBridge: annotate synergies on refresh; richer instancesFor
- [x] T014 Windows catalog_page: mode chips, kind facets, synergy filter, reverse tags, instance cards, Universal Set/Synergy CTAs
- [x] T015 Jaspr OwnedCatalogBridge + catalog_page parity
- [x] T016 Host tests: modes, synergy filter, reverse tags badges, readable instance detail, no Build attach

## Phase 6: Finish

- [x] T017 Run package + host catalog tests; fix failures
- [x] T018 Update roadmap / gap / fidelity status; commit; merge to `feature/multiplatform-dart`
