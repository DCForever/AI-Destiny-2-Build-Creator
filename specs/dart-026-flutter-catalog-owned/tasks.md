# Tasks: DART-026 Flutter Catalog Owned

**Input**: Design documents from `/specs/dart-026-flutter-catalog-owned/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Pure unit tests + flutter widget tests with memory DB. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 [P] Create `packages/manifest/lib/src/catalog/owned_catalog.dart` skeleton + export
- [x] T002 [P] Create `packages/db/lib/src/repos/instance_projection.dart` skeleton + export
- [x] T003 [P] Create `apps/windows_host/lib/catalog/owned_catalog_bridge.dart` skeleton

---

## Phase 2: Foundational — pure owned + instances

- [x] T004 Implement `countOwnedByItemHash` + `annotateCatalogWithOwned` in owned_catalog.dart
- [x] T005 Add `CatalogScope` + scope filter in filter_catalog.dart
- [x] T006 Implement `CatalogInstanceProjection` + `projectInstancesForHash` / list project
- [x] T007 [P] Write `packages/manifest/test/owned_catalog_test.dart` + extend filter tests
- [x] T008 [P] Write `packages/db/test/instance_projection_test.dart`
- [x] T009 Confirm pure tests pass

**Checkpoint**: Pure annotate/filter/project green

---

## Phase 3: User Story 1+3 — Catalog bridge + UI (P1) 🎯 MVP

**Goal**: Owned filter works after sync in Flutter Catalog  
**Independent Test**: catalog_owned_page_test with seeded inventory

- [x] T010 [US1] Implement OwnedCatalogBridge (load inventory, annotate, browse)
- [x] T011 [US3] Update catalog_page.dart: All|Owned toggle, ownership display, reload path
- [x] T012 [US2] Instance panel on row select using projectInstancesForHash
- [x] T013 Write `apps/windows_host/test/catalog_owned_page_test.dart`
- [x] T014 Confirm flutter tests pass (owned + existing catalog_page_test)

**Checkpoint**: Exit criteria green

---

## Phase 4: Polish & finish

- [x] T015 Update windows_host README note for owned catalog if present
- [x] T016 Run targeted tests; pure graph guard still green
- [x] T017 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-026 done, pointer → DART-027

---

## Dependencies & Execution Order

- Setup → Pure foundation → Bridge/UI → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure owned annotate + scope filter  
2. Instance projection DTOs  
3. Host bridge + Catalog UI  
4. Tests then merge
