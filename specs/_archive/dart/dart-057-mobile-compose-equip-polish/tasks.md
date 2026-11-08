# Tasks: DART-057 Mobile Compose / Equip Polish

**Input**: Design documents from `/specs/dart-057-mobile-compose-equip-polish/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-057-mobile-compose-equip-polish`

## Phase 2: Mobile surface matrix (US1)

- [x] T002 [US1] Add `apps/mobile_host/lib/surface_matrix.dart` (status enum + matrix + bottom-nav keys)
- [x] T003 [US1] Settings matrix card in `apps/mobile_host/lib/settings/settings_page.dart`
- [x] T004 [US1] Tests: `surface_matrix_test.dart` + update `shell_nav_test.dart`
- [x] T005 [US1] Finish-gap display on mobile compose (`finish_gaps_format.dart` + controller getter + detail section) — display only, no equip CTA

## Phase 3: Jaspr soft-stat editor (US2)

- [x] T006 [US2] Expand `build_compose_page.dart` soft-stat fields to all `ArmorStatName`
- [x] T007 [US2] Extend `soft_guidance_format_test.dart` multi-stat coverage

## Phase 4: Finish-gaps host UX (US3)

- [x] T008 [US3] Windows `finish_gaps_format.dart` + controller `finishGaps` + panel on `builds_library_page.dart`
- [x] T009 [US3] Windows equip/DIM panels take `finishComplete`; CTA AND policy + format helpers
- [x] T010 [US3] Jaspr `finish_gaps_format.dart` + controller getter + compose finish section + CTA gates
- [x] T011 [US3] Host format tests (windows + web): finish display helpers + canEnable* with finishComplete

## Phase 5: Docs + finish

- [x] T012 Update feature-gaps GAP-MOB-01 / GAP-UI-01 / GAP-FEAT-06 closed; GAP-FEAT-01 deferred; cutover finish note
- [x] T013 Update roadmap DART-057 done; Current → DART-058
- [x] T014 Run host tests green for touched suites
- [x] T015 Commit; merge `--no-edit` into `feature/multiplatform-dart`; commit base
