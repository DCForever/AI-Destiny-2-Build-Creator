# Tasks: DART-064 Build Identity, Subclass Kit, Manifest Pickers

**Input**: Design documents from `/specs/dart-064-build-identity-subclass-compose/`  
**Prerequisites**: plan.md, spec.md, research.md  

## Phase 1: Setup

- [x] T001 Create Spec Kit docs + set `.specify/feature.json` → `specs/dart-064-build-identity-subclass-compose`
- [x] T002 Branch `dart-064-build-identity-subclass-compose` from `feature/multiplatform-dart`

## Phase 2: Identity Confirm/Fork (US1)

- [x] T003 [P] Add `UseCaseErrorCode.identityConfirmRequired` + `IdentityAction` + pure `detectIdentityFieldChanges` in `packages/app`
- [x] T004 Extend `UpdateBuildCommand` + `updateUserBuild` confirm/fork; fork copies variants as snapshots
- [x] T005 Unit tests identity confirm required / confirm / fork / soft-stat bypass in `packages/app/test`

## Phase 3: Compose hard blocks + Manifest search (US3/US4)

- [x] T006 [P] Add `compose_hard_blocks.dart` plain-language aggregator using domain evaluators
- [x] T007 [P] Add `manifest_search_picks.dart` name search for exotic armor / super / kit pieces
- [x] T008 Unit tests for hard-block aggregator + manifest search

## Phase 4: Windows host (US1–US4)

- [x] T009 Controller: identityAction paths, subclass kit draft, hard-block preview, catalog picks source
- [x] T010 UI: Confirm/Fork/Cancel; subclass kit composer + capacity; Manifest pick sheets; hard-block banners
- [x] T011 Windows tests for confirm/fork, kit, pickers, hard-block, soft never disables save

## Phase 5: Jaspr host (US1–US5)

- [x] T012 Controller parity: identity confirm/fork, subclass kit, hard blocks, pick filters
- [x] T013 BuildComposePage: identity edit + Confirm/Fork; kit; pickers; named set picker + per-slot pins
- [x] T014 Jaspr tests for named attach, per-slot pins, identity/kit/hard-block

## Phase 6: Finish

- [x] T015 Run package + host tests; fix failures
- [x] T016 Update roadmap / gap / fidelity status; commit; merge to `feature/multiplatform-dart`
