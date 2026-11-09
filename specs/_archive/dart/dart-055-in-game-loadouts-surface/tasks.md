# Tasks: DART-055 In-Game Loadouts Surface

**Input**: Design documents from `/specs/dart-055-in-game-loadouts-surface/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-055-in-game-loadouts-surface`

## Phase 2: Pure parse (US1)

- [x] T002 [P] [US1] Add `packages/bungie/lib/src/profile/character_loadouts.dart` (DTOs + parse + presentation)
- [x] T003 [P] [US1] Export from `destiny2_bungie.dart`
- [x] T004 [US1] Add `packages/bungie/test/character_loadouts_test.dart` (Next fixture parity)
- [x] T005 [US1] Extend `BungieProfileClient` + `HttpBungieProfileClient` with character loadouts profile (200,206)
- [x] T006 [US1] Update all `FakeProfileClient` / implementors for new method
- [x] T007 [US1] Run `dart test packages/bungie` green

## Phase 3: Windows UI (US2)

- [x] T008 [US2] Add `apps/windows_host/lib/loadouts/loadouts_controller.dart` + optional presentation loader
- [x] T009 [US2] Add `apps/windows_host/lib/loadouts/loadouts_page.dart`
- [x] T010 [US2] Wire NavigationRail **Loadouts** + IndexedStack page in `app.dart`
- [x] T011 [US2] Tests: `shell_nav_loadouts_test.dart`, `loadouts_page_test.dart`
- [x] T012 [US2] Windows host loadouts tests green

## Phase 4: Jaspr (US3)

- [x] T013 [US3] ShellHeader + Router `/loadouts` + loadouts page/controller
- [x] T014 [US3] Extend `shell_nav_compose_test.dart` + `loadouts_page_test.dart`
- [x] T015 [US3] Web host tests green

## Phase 5: Docs + finish (US4)

- [x] T016 Update feature-gaps GAP-NAV-01 closed; cutover loadouts PASS + RB-01 cleared + RC-NAV note
- [x] T017 Update roadmap DART-055 done; packages/README note
- [x] T018 Run relevant tests + cutover validator
- [x] T019 Commit; merge `--no-edit` into `feature/multiplatform-dart`; roadmap Current → DART-056; commit base
