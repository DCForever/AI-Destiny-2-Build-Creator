# Tasks: DART-047 Jaspr Equip Export

**Input**: Design documents from `/specs/dart-047-jaspr-equip-export/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: `dart test` in `apps/web_host`. Memory DB. Mock write + injectable clipboard. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-047-jaspr-equip-export/` docs + set `.specify/feature.json`
- [x] T002 [P] Write research.md / quickstart.md / checklist

---

## Phase 2: Format helpers (US1–US2 foundations)

**Goal**: Pure display helpers  
**Independent Test**: format unit tests

- [x] T003 [P] Implement `lib/equip/equip_format.dart`
- [x] T004 [P] Implement `lib/dim_export/dim_export_format.dart`
- [x] T005 [P] Tests: `test/equip_format_test.dart`, `test/dim_export_format_test.dart`

**Checkpoint**: Format tests green

---

## Phase 3: Controllers (US1–US3) 🎯

**Goal**: Readiness, DIM export, optional equip orchestration  
**Independent Test**: controller tests memory DB

- [x] T006 Implement `lib/dim_export/dim_export_controller.dart`
- [x] T007 Implement `lib/equip/equip_controller.dart` (skipSyncIfStale for tests)
- [x] T008 [P] Tests: `test/dim_export_controller_test.dart`, `test/equip_controller_test.dart`
- [x] T009 Extend `lib/compose/compose_services.dart` + `app.dart` / `build_compose_page.dart` UI sections
- [x] T010 Wire `main.client.dart` public API key + profile/write clients (optional equip)
- [x] T011 [P] `test/no_client_secret_equip_test.dart`; update README

**Checkpoint**: Controller tests green; soft never auto-applies

---

## Phase 4: Finish

- [x] T012 Mark tasks complete; run full `dart test` in apps/web_host
- [x] T013 Commit on `dart-047-jaspr-equip-export`
- [x] T014 Merge into `feature/multiplatform-dart` (--no-edit); roadmap DART-047 done; pointer → DART-048; commit base

---

## Dependencies & Execution Order

- Setup → formats → controllers/UI → finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs  
2. Pure helpers  
3. Controllers + tests  
4. Compose UI + main wiring  
5. Merge + roadmap  
