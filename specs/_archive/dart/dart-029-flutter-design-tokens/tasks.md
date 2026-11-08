# Tasks: DART-029 Flutter Design Tokens

**Input**: Design documents from `/specs/dart-029-flutter-design-tokens/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Pure package unit tests + Windows host theme widget/unit tests. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `packages/ui_tokens` pubspec (SDK only runtime), barrel, workspace membership in root `pubspec.yaml`
- [x] T002 [P] Write package README skeleton + specs already in place

---

## Phase 2: Foundational tokens + layout contracts

- [x] T003 [P] [US1] Implement `colors.dart`, `spacing.dart`, `radii.dart`, `typography.dart`
- [x] T004 [P] [US2] Implement `flap_board_layout.dart` (rail, gap, column templates)
- [x] T005 Export all from `destiny2_ui_tokens.dart`; complete README documentation

**Checkpoint**: `dart pub get` resolves; package analyzes clean

---

## Phase 3: User Story 1–2 tests 🎯 MVP

**Goal**: Documented tokens + FlapBoard contracts proven by tests  
**Independent Test**: `dart test packages/ui_tokens`

- [x] T006 [US1][US2] Write `packages/ui_tokens/test/ui_tokens_test.dart` (hex parity, radius 0, rail 320, gap 0, templates)
- [x] T007 Confirm pure package tests pass

**Checkpoint**: Exit “Documented tokens” + layout contracts green

---

## Phase 4: User Story 3 — Windows theme stub

**Goal**: Theme without Material-card default; wire app  
**Independent Test**: `flutter test` theme suite

- [x] T008 [US3] Add `destiny2_ui_tokens` dep to `apps/windows_host`; implement `lib/theme/flap_theme.dart`
- [x] T009 [US3] Apply theme in `app.dart` (replace ColorScheme.fromSeed)
- [x] T010 [US3] Write `apps/windows_host/test/flap_theme_test.dart`
- [x] T011 [US3] Confirm host theme tests pass

**Checkpoint**: Exit “Windows theme stub without Material-card default”

---

## Phase 5: Polish & finish

- [x] T012 Update `packages/README.md` for `ui_tokens`
- [x] T013 Run `dart test packages/ui_tokens` and host theme tests; melos analyze includes package if needed
- [x] T014 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-029 done, pointer → DART-030

---

## Dependencies & Execution Order

- Setup → Tokens/layout → Tests → Theme → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Pure tokens package first (portable)
2. Prove values with tests
3. Thin Flutter theme stub + wire host
4. Merge to integration base
