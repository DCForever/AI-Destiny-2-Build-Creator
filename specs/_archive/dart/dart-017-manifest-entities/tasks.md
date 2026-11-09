# Tasks: DART-017 Manifest Entities

**Input**: Design documents from `/specs/dart-017-manifest-entities/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1: Setup

- [x] T001 Confirm branch `dart-017-manifest-entities`; specs dir present
- [x] T002 Update `.specify/feature.json` → `specs/dart-017-manifest-entities`
- [x] T003 Create `packages/manifest` pubspec + workspace member + barrel

## Phase 2: Foundational types

- [x] T004 Implement normalizeName + entity record types + MVP store names
- [x] T005 Implement raw types + extractor common helpers
- [x] T006 Port hand-trimmed raw table fixtures to Dart

## Phase 3: Extractors (US2)

- [x] T007 [US2] Implement exotic-armor + weapons extractors
- [x] T008 [US2] Implement aspects + fragments + abilities + mods extractors
- [x] T009 [US2] Extractor unit tests against fixtures

## Phase 4: Entity cache read/rebuild (US1, US3)

- [x] T010 [US1/US3] Implement FileEntityCache getMeta/getStore/rebuild via StorageRoot
- [x] T011 [US1/US3] Offline read + rebuild round-trip tests

## Phase 5: Resolve + hard adapters (US4)

- [x] T012 [US4] ItemResolver (exact + byHash) + PerkValidator
- [x] T013 [US4] Hard constraints adapters (subclass kit, mod energy)
- [x] T014 [US4] Adapter + resolve tests

## Phase 6: Polish & finish

- [x] T015 Update packages/README.md + root analyze script if needed
- [x] T016 Mark tasks complete; `dart test packages/manifest` green (20)
- [x] T017 Commit; merge `--no-edit` into `feature/multiplatform-dart`; update roadmap pointer to DART-018; commit base
