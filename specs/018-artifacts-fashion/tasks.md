# Tasks: Artifacts & Fashion (Per Variant)

**Input**: `/specs/018-artifacts-fashion/`  
**Tests**: Test-first; `npm run gate` per story checkpoint.

## Phase 1: Setup

- [x] T001 Verify docs under `specs/018-artifacts-fashion/` (plan, research, data-model, contracts, quickstart)
- [x] T002 [P] Skim `schema.ts` build_variants, `sets/schemas.ts`, `setItemService.ts`, `resolveVariant.ts`, `prepareAttachments`, Builds/Sets debug

## Phase 2: Foundational

- [x] T003 Add `artifact_hash`, `artifact_name`, `artifact_config` columns + migration/backfill on `build_variants`
- [x] T004 Add `FASHION_SLOTS` + fix `isSlotValidForSetType` for fashion in `src/lib/sets/schemas.ts`
- [ ] T005 Checkpoint: typecheck compiles

## Phase 3: US1 Artifact (P1)

- [ ] T006 [P] [US1] Failing tests: set/clear/switch artifact + config; reject unknown hash
- [ ] T007 [US1] Wire variant schemas + `variantService`/`buildService` read/write + manifest validation
- [ ] T008 [US1] BuildsDebugPage: artifact select + config fields
- [ ] T009 [US1] Tests + gate

## Phase 4: US2 Fashion (P1)

- [ ] T010 [P] [US2] Failing tests: fashion slot upsert; reject emote/consumable; ≤1 fashion attachment
- [ ] T011 [US2] Implement fashion item upsert + attachment guard in `setItemService` / `prepareAttachments`
- [ ] T012 [US2] SetsDebugPage: fashion slot picker
- [ ] T013 [US2] Regression: fashion still ignored by combat resolve / coverage / suggest gap scoring
- [ ] T014 [US2] Tests + gate

## Phase 5: US3 Resolved exposure (P2)

- [ ] T015 [P] [US3] Failing tests: resolved includes `artifact` + `fashion` (nulls when unset; omit empty fashion slots)
- [ ] T016 [US3] Extend `getResolvedVariant` / resolved route
- [ ] T017 [US3] BuildsDebugPage Resolve log shows new fields
- [ ] T018 [US3] Tests + gate

## Phase 6: US4 Soft / non-identity (P2)

- [ ] T019 [P] [US4] Regression: non-default save without fashion OK; artifact-only PATCH no identityAction
- [ ] T020 [US4] Tests + gate

## Phase 7: Polish

- [ ] T021 [P] Walk quickstart V1–V4
- [ ] T022 Final `npm run gate`; finish-spec merge to `feature/overhall`
