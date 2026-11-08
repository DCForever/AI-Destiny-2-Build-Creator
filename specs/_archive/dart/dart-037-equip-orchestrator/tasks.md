# Tasks: DART-037 Equip Orchestrator

**Input**: Design documents from `/specs/dart-037-equip-orchestrator/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Domain plan goldens + bungie mock write / HTTP write tests. No live Bungie. No CLIENT_SECRET.

## Phase 1: Setup

- [x] T001 Create `specs/dart-037-equip-orchestrator/` docs (spec/plan/research/tasks/checklist) + set `.specify/feature.json`
- [x] T002 Add `destiny2_domain` dependency to `packages/bungie/pubspec.yaml`

---

## Phase 2: Pure plan (US1) 🎯

**Goal**: `planEquipSteps` parity with TS  
**Independent Test**: `packages/domain/test/equip_plan_test.dart`

- [x] T003 [US1] Implement `packages/domain/lib/src/evaluators/equip_plan.dart` (DTOs + planner)
- [x] T004 [US1] Export equip_plan from `packages/domain/lib/destiny2_domain.dart`
- [x] T005 [US1] Write `packages/domain/test/equip_plan_test.dart` (order, vault hop, skip transfer, empty, NOT_EQUIP_READY, multi-slot)

**Checkpoint**: `dart test` in domain equip_plan_test green

---

## Phase 3: Write client + orchestrator (US2/US3)

**Goal**: Mocked write execute + partial status; HTTP transfer/equip posts  
**Independent Test**: bungie write + orchestrator tests

- [x] T006 [US2] Implement `packages/bungie/lib/src/write/write_client.dart` (interface, HTTP, mock)
- [x] T007 [US2/US3] Implement `packages/bungie/lib/src/write/equip_orchestrator.dart`
- [x] T008 Export write + orchestrator from `packages/bungie/lib/destiny2_bungie.dart`
- [x] T009 [US2] Write `packages/bungie/test/write_client_test.dart` (HTTP POST shapes, mock default)
- [x] T010 [US2/US3] Write `packages/bungie/test/equip_orchestrator_test.dart` (order success + partial no rollback)

**Checkpoint**: bungie tests green

---

## Phase 4: Polish & finish

- [x] T011 Update package descriptions for DART-037 surface
- [x] T012 Run domain + bungie tests for this slice
- [x] T013 Mark tasks complete; commit; merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-037 done, pointer → DART-038

---

## Dependencies & Execution Order

- Setup → Pure plan → Write/orchestrator → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs + feature.json  
2. Domain plan + tests  
3. Bungie write client + orchestrator + tests  
4. Merge to integration base + roadmap pointer  
