# Tasks: DART-035 Optimizer Isolate

**Input**: Design documents from `/specs/dart-035-optimizer-isolate/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Required for pipeline, isolate, materialize, apply-in-place.

## Phase 1: Setup

- [x] T001 Confirm branch `dart-035-optimizer-isolate` off `feature/multiplatform-dart`; set `.specify/feature.json` feature_directory
- [x] T002 [P] Write spec kit docs under `specs/dart-035-optimizer-isolate/`

---

## Phase 2: Domain pipeline (US1)

- [x] T003 Extend optimizer models with combination / request / response / empty-reason types in `packages/domain/lib/src/models/optimizer.dart`
- [x] T004 Implement `explainEmpty` in `packages/domain/lib/src/evaluators/optimizer_explain_empty.dart`
- [x] T005 Implement pure `optimizeArmorCore` in `packages/domain/lib/src/evaluators/optimizer_pipeline.dart`
- [x] T006 Export new APIs from `packages/domain/lib/destiny2_domain.dart`
- [x] T007 [US1] Golden tests in `packages/domain/test/optimizer_pipeline_test.dart`

**Checkpoint**: `dart test packages/domain` includes pipeline suite green

---

## Phase 3: Isolate runner (US2)

- [x] T008 Implement serialize helpers + `optimizeArmorLocal` / `optimizeArmorInIsolate` in `packages/app/lib/src/optimizer_isolate.dart`
- [x] T009 Export from `packages/app/lib/destiny2_app.dart`
- [x] T010 [US2] Isolate parity tests in `packages/app/test/optimizer_isolate_test.dart`

**Checkpoint**: Isolate and local results match on fixture board

---

## Phase 4: Materialize + apply (US3 / US4)

- [x] T011 Extend `UseCaseErrorCode` for combination/ownership failures in `packages/app/lib/src/errors.dart`
- [x] T012 Implement materialize + apply-in-place in `packages/app/lib/src/optimizer_use_cases.dart`
- [x] T013 Export optimizer use cases from `destiny2_app.dart`
- [x] T014 [US3][US4] Tests in `packages/app/test/optimizer_materialize_test.dart` (confirm-only: optimize does not write)

**Checkpoint**: Materialize/apply green; confirm-only covered

---

## Phase 5: Polish & finish

- [x] T015 Run `dart test packages/domain` and `dart test packages/app`; `dart analyze` on touched packages
- [x] T016 Update `packages/README.md` note for DART-035 if needed
- [x] T017 Mark tasks complete; commit; merge to `feature/multiplatform-dart`; update roadmap status/pointer

---

## Dependencies & Execution Order

- Setup → Domain US1 → Isolate US2 → Materialize US3/US4 → Polish
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

Pure pipeline first (testable without isolate), then isolate wrapper parity, then DB materialize confirm-only path.
