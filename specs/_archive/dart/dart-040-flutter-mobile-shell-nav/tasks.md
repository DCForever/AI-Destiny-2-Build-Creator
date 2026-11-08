# Tasks: DART-040 Flutter Mobile Shell Nav

**Input**: Design documents from `/specs/dart-040-flutter-mobile-shell-nav/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Flutter widget/unit tests (memory/temp DB). No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-040-flutter-mobile-shell-nav/` docs + set `.specify/feature.json`
- [x] T002 Create Flutter app `apps/mobile_host` (android+ios); add workspace member; pub get

---

## Phase 2: Bootstrap + theme (US1)

**Goal**: Single DB open, theme, app entry  
**Independent Test**: `host_bootstrap_test.dart`

- [x] T003 Implement `apps/mobile_host/lib/host_bootstrap.dart` (StorageRoot + single AppDatabase + ManifestRefreshApi)
- [x] T004 Implement `apps/mobile_host/lib/theme/flap_theme.dart`
- [x] T005 Implement `apps/mobile_host/lib/main.dart` bootstrap entry
- [x] T006 Write `apps/mobile_host/test/host_bootstrap_test.dart`

---

## Phase 3: Shell + Settings + Builds Focus Swap (US2–US4) 🎯 MVP

**Goal**: Bottom nav; Builds list via shared use cases; Focus Swap detail; Settings  
**Independent Test**: shell_nav / builds_list / settings tests

- [x] T007 [P] Implement `apps/mobile_host/lib/builds/build_format.dart`
- [x] T008 Implement `apps/mobile_host/lib/builds/builds_controller.dart` (listUserBuilds / getBuildDetail)
- [x] T009 Implement Builds list + detail pages + Focus Swap nested navigator
- [x] T010 Implement `apps/mobile_host/lib/settings/settings_page.dart`
- [x] T011 Implement `apps/mobile_host/lib/app.dart` bottom NavigationBar shell
- [x] T012 Write `apps/mobile_host/test/settings_page_test.dart`
- [x] T013 Write `apps/mobile_host/test/builds_list_test.dart` (empty + seeded + Focus Swap)
- [x] T014 Write `apps/mobile_host/test/shell_nav_test.dart` (Builds/Settings destinations)

**Checkpoint**: All mobile_host flutter tests green

---

## Phase 4: Polish & finish

- [x] T015 Update README + packages/README; root workspace/docs as needed
- [x] T016 Run `flutter test` in mobile_host; run `flutter build apk --debug` for installable evidence
- [x] T017 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-040 done, pointer → DART-041

---

## Dependencies & Execution Order

- Setup → Bootstrap → Shell/list/settings + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs + feature.json  
2. Flutter create + bootstrap  
3. Bottom nav + Focus Swap + Settings + tests  
4. Android debug APK + merge + roadmap pointer  
