# Tasks: DART-001 Domain Foundation

**Input**: Design documents from `/specs/dart-001-domain-foundation/`

**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Smoke test required (constitution Test-First for package shell).

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Create `packages/` tree and domain package directories per plan.md
- [x] T002 Add root `pubspec.yaml` workspace and Melos 7+ `melos:` scripts (`test`, `analyze`)
- [x] T003 [P] Extend `.gitignore` for Dart/Melos artifacts (`.dart_tool/`, `packages/**/pubspec.lock`, `.idea/`, etc.)

---

## Phase 2: Foundational (Blocking Prerequisites)

- [x] T004 Author pure `packages/domain/pubspec.yaml` (SDK only runtime; `test` as dev_dependency)
- [x] T005 [P] Add shared `analysis_options.yaml` minimal defaults
- [x] T006 Document layout + purity rules in `packages/README.md`

**Checkpoint**: Structure and docs exist; ready for smoke library + test

---

## Phase 3: User Story 1 — Resolve pure domain package (P1) 🎯 MVP

**Goal**: Domain package resolves with zero IO/UI deps

**Independent Test**: `dart pub get` at root / in domain succeeds; pubspec has no forbidden deps

- [x] T007 [US1] Implement trivial pure export in `packages/domain/lib/src/smoke.dart` and barrel `packages/domain/lib/destiny2_domain.dart`
- [x] T008 [US1] Bootstrap workspace (`dart pub get` / `melos bootstrap`) and confirm resolve

**Checkpoint**: Package graph resolves

---

## Phase 4: User Story 2 — CI-friendly smoke test (P1)

**Goal**: One command runs domain smoke tests without UI hosts

**Independent Test**: `melos run test` or `dart test packages/domain` exits 0

- [x] T009 [US2] Write failing-then-passing smoke test in `packages/domain/test/smoke_test.dart`
- [x] T010 [US2] Wire Melos `test` script; run and capture green output

**Checkpoint**: CI-friendly test entry green

---

## Phase 5: User Story 3 — Documented layout (P2)

**Goal**: Contributors can find bootstrap/test/purity rules

**Independent Test**: quickstart + packages README match tree

- [x] T011 [US3] Align `specs/dart-001-domain-foundation/quickstart.md` with final commands
- [x] T012 [US3] Brief pointer from root README; packages/README remains canonical layout doc

**Checkpoint**: Layout docs complete

---

## Phase 6: Polish

- [x] T013 Verify domain pubspec has no IO/UI deps (manual audit: empty `dependencies: {}`)
- [x] T014 Mark all tasks complete; prepare finish-spec merge to `feature/multiplatform-dart`
- [ ] T015 Update `docs/multiplatform-dart-slice-roadmap.md` status/pointer on base after merge

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish
- US2 depends on US1 export existing
- Finish-spec merge only onto `feature/multiplatform-dart`

## Implementation Strategy

1. Skeleton configs + empty package
2. Smoke export + test
3. Docs audit + merge

## Evidence (implement)

- `dart pub get` — success (workspace + `destiny2_domain`)
- `melos bootstrap` — 1 package bootstrapped
- `melos run test` — 2/2 smoke tests passed
- `melos run analyze` — no issues
- `dart test packages/domain` — 2/2 passed (no-Melos entry)
