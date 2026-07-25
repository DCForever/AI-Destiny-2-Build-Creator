# Tasks: DART-046 Jaspr Compose Spine

**Input**: Design documents from `/specs/dart-046-jaspr-compose-spine/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: `dart test` in `apps/web_host`. Memory DB. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-046-jaspr-compose-spine/` docs + set `.specify/feature.json`
- [x] T002 [P] Write research.md / quickstart.md / checklist

---

## Phase 2: Foundational — deps + pure format helpers

**Goal**: Path deps + display helpers  
**Independent Test**: format unit tests

- [x] T003 Add `destiny2_app` + `destiny2_domain` path deps to `apps/web_host/pubspec.yaml`
- [x] T004 [P] Implement `lib/compose/build_format.dart`, `soft_guidance_format.dart`, `variant_compose_format.dart`, `set_slot_mapping.dart`
- [x] T005 [P] Unit tests: `test/build_format_test.dart`, `soft_guidance_format_test.dart`, `variant_compose_format_test.dart`
- [x] T006 Implement `lib/compose/compose_services.dart` (db + three controllers)

**Checkpoint**: Format tests green; pub get resolves

---

## Phase 3: User Stories 1–3 — Controllers (P1) 🎯

**Goal**: Builds / sets / synergies orchestration with hard gates  
**Independent Test**: controller tests memory DB

- [x] T007 Implement `lib/builds/builds_controller.dart` (create, variants, attach, pin, soft)
- [x] T008 Implement `lib/sets/sets_controller.dart`
- [x] T009 Implement `lib/synergies/synergies_controller.dart`
- [x] T010 [P] Tests: `test/builds_controller_test.dart`, `sets_controller_test.dart`, `synergies_controller_test.dart`

**Checkpoint**: Intent→attach→pin + soft chip tests green

---

## Phase 4: User Stories 4–5 — Jaspr UI + nav (P1/P2)

**Goal**: Pages + shell routes  
**Independent Test**: component smoke + shell nav

- [x] T011 Implement `lib/builds/builds_page.dart` + `build_compose_page.dart`
- [x] T012 Implement `lib/sets/sets_page.dart` + `lib/synergies/synergies_page.dart`
- [x] T013 Update `shell_header.dart`, `app.dart`, `main.client.dart` for spine routes + services
- [x] T014 [P] Tests: `test/builds_page_test.dart`, `test/shell_nav_compose_test.dart`
- [x] T015 Update `apps/web_host/README.md` for DART-046

**Checkpoint**: web_host full test suite green (70)

---

## Phase 5: Finish

- [x] T016 Mark tasks complete; run full `dart test` in apps/web_host
- [x] T017 Commit on `dart-046-jaspr-compose-spine`
- [ ] T018 Merge into `feature/multiplatform-dart` (--no-edit); roadmap DART-046 done; pointer → DART-047; commit base

---

## Dependencies & Execution Order

- Setup → formats/deps → controllers → UI/nav → finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs  
2. Pure helpers + services  
3. Controllers with memory-DB parity tests  
4. Jaspr pages + nav  
5. Merge + roadmap  
