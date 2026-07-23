# Tasks: Hard-gate characterization tests

**Input**: `specs/035-hard-gate-tests/spec.md`, `plan.md`  
**Prerequisites**: Spec + plan complete; improve prompt `001-characterization-hard-gates.md`

## Phase 1: Setup
- [x] T001 Point `.specify/feature.json` at `specs/035-hard-gate-tests`; create feature dir artifacts

## Phase 2: Foundational (blocked until done)
- [x] T002 Document mock strategy (getServices entityCache + exotic ability module) in plan/research

## Phase 3: User Story 1 — Exotic limits (P1)
**Goal**: Legal/illegal exotic composition characterization  
**Independent Test**: `npx vitest run src/lib/builds/assertExoticLimits.test.ts`
- [x] T003 [US1] Add `src/lib/builds/assertExoticLimits.test.ts` with mocked exotic-weapons/armor stores: empty OK; 1+1 OK; dual weapons/armors → `TOO_MANY_EXOTICS`

## Phase 4: User Story 2 — Subclass kit (P1)
**Goal**: Legal kit + over-capacity/over-aspect hard blocks  
**Independent Test**: `npx vitest run src/lib/builds/assertSubclassKit.test.ts`
- [x] T004 [US2] Add `src/lib/builds/assertSubclassKit.test.ts` mocking aspects store fragmentCapacity

## Phase 5: User Story 3 — Mod energy (P1)
**Goal**: Under/over capacity + illegal slot category  
**Independent Test**: `npx vitest run src/lib/builds/assertModEnergy.test.ts`
- [x] T005 [US3] Add `src/lib/builds/assertModEnergy.test.ts` mocking mods store for `assertModEnergyForConfigs`

## Phase 6: User Story 4 — Exotic ability pins (P1)
**Goal**: Match vs mismatch ability requirements  
**Independent Test**: `npx vitest run src/lib/builds/assertExoticAbilityPins.test.ts`
- [x] T006 [US4] Add `src/lib/builds/assertExoticAbilityPins.test.ts` mocking exotic ability requirements lookup

## Phase 7: Polish & verification
- [x] T007 Run `npm run test` for the four new files (or full suite if fast enough)
- [x] T008 Run `npm run typecheck` and `npm run lint`; fix failures introduced by this branch
- [x] T009 Mark improve acceptance criteria satisfied; final implement commit

## Dependencies
- US1–US4 independent after T002 (parallelizable)
- T007–T009 after all story tests exist

## Implementation strategy
MVP = all four assert test files green offline. No production edits unless a clear test-only bug blocks characterization. No full-loadout-on-create tests.
