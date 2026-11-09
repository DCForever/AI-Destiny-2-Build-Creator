# Tasks: DART-020 Flutter Catalog Offline

**Input**: Design documents from `/specs/dart-020-flutter-catalog-offline/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1: Setup

- [x] T001 Confirm branch `dart-020-flutter-catalog-offline`; specs dir present
- [x] T002 Update `.specify/feature.json` → `specs/dart-020-flutter-catalog-offline`

## Phase 2: Pure filter (US1)

- [x] T003 [US1] Implement `CatalogItem`, `FacetFilter`, helpers in `packages/manifest/lib/src/catalog/`
- [x] T004 [US1] Implement `filterCatalogClient` + `filter_options` constants; export from barrel
- [x] T005 [US1] Unit tests `packages/manifest/test/filter_catalog_test.dart` (mix include/exclude, exotic, query, chip cycle)

## Phase 3: Project + offline load (US2)

- [x] T006 [US2] Implement `catalog_projector.dart` (MVP stores → CatalogItem)
- [x] T007 [US2] Implement `OfflineCatalog` load/browse in `offline_catalog.dart`
- [x] T008 [US2] Tests `catalog_projector_test.dart` + `offline_catalog_test.dart` with fixture entity JSON

## Phase 4: Flutter Catalog UI (US3)

- [x] T009 [US3] Wire `OfflineCatalog` on `AppServices` / bootstrap
- [x] T010 [US3] Implement `apps/windows_host/lib/catalog/catalog_page.dart`
- [x] T011 [US3] Shell nav Catalog | Settings in `app.dart`
- [x] T012 [US3] Widget tests `catalog_page_test.dart`

## Phase 5: Polish & finish

- [x] T013 Update `packages/README.md` for catalog module
- [x] T014 Mark tasks complete; `dart test packages/manifest` (57) + `flutter test` (9) green
- [x] T015 Commit; merge `--no-edit` into `feature/multiplatform-dart`; roadmap DART-020 done, pointer DART-021; P1 gate note; commit base
