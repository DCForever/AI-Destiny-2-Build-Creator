# Tasks: DART-038 Flutter Equip UI

**Input**: Design documents from `/specs/dart-038-flutter-equip-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Format helpers + Flutter widget/controller tests (memory DB, mock write). Bungie character parse unit tests. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-038-flutter-equip-ui/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Confirm DART-037 exports (`planEquipSteps`, `executeEquipPlan`, write client) available to windows_host

---

## Phase 2: Characters on profile client

**Goal**: `getCharacters` + CharacterSummary for class-filtered pick  
**Independent Test**: `packages/bungie/test/character_parse_test.dart` (or profile_client_test extension)

- [x] T003 [P] Add `CharacterSummary` + class map helpers in `packages/bungie/lib/src/profile/`
- [x] T004 [P] Implement `getCharacters` on `BungieProfileClient` / HTTP impl (components=200)
- [x] T005 Export types; write unit test for character parse + HTTP path
- [x] T006 Update `FakeProfileClient` in windows_host test fakes with `getCharacters`

**Checkpoint**: bungie character tests green

---

## Phase 3: Equip format + controller + panel (US1–US3) 🎯 MVP

**Goal**: Character pick, equip-ready gate, gaps confirm, step report  
**Independent Test**: `equip_format_test.dart` + `equip_panel_test.dart`

- [x] T007 [P] Implement `apps/windows_host/lib/equip/equip_format.dart`
- [x] T008 [P] Write `apps/windows_host/test/equip_format_test.dart`
- [x] T009 Implement `apps/windows_host/lib/equip/equip_controller.dart` (readiness, characters, requestEquip, gaps confirm, execute)
- [x] T010 Implement `apps/windows_host/lib/equip/equip_panel.dart` UI
- [x] T011 Embed EquipPanel in `builds_library_page.dart`; wire AppServices writeClient if needed
- [x] T012 Write `apps/windows_host/test/equip_panel_test.dart` (gate, gaps cancel/confirm, step report mock)

**Checkpoint**: equip tests green; soft never auto-applies

---

## Phase 4: Polish & finish

- [x] T013 Update `apps/windows_host/README.md` + pubspec description for equip UI
- [x] T014 Run bungie character + equip flutter tests
- [x] T015 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-038 done, pointer → DART-039

---

## Dependencies & Execution Order

- Setup → Characters → Equip UI + tests → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs + feature.json  
2. Profile getCharacters  
3. Equip format/controller/panel + tests  
4. Merge to integration base + roadmap pointer  
