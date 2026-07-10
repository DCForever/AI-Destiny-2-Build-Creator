# Tasks: Build Identity & Default Completeness

**Input**: Design documents from `/specs/015-build-identity/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Constitution requires Test-First — failing tests before implementation for each story; green `npm run gate` at each story checkpoint.

**Organization**: Tasks grouped by user story (US1–US4) for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no incomplete dependencies)
- **[Story]**: US1–US4 maps to spec user stories
- Exact file paths in every task

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Align branch docs and confirm working tree ready for schema work

- [ ] T001 Verify feature docs present under `specs/015-build-identity/` (plan, spec, research, data-model, contracts, quickstart) and note touchpoints from `plan.md` Project Structure
- [ ] T002 [P] Skim existing builds tests in `src/lib/builds/buildService.test.ts`, `src/lib/builds/resolveVariant.test.ts`, and `src/lib/builds/variantService.test.ts` to identify extension points for identity/loadout/fork/naming

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema + zod types all stories need — MUST complete before US1–US4 implementation

**⚠️ CRITICAL**: No user story implementation until this phase is complete (tests for stories may be drafted after foundation types exist)

- [ ] T003 Make `exoticArmorHash` / `exoticArmorName` nullable and add `exoticWeaponHash`, `exoticWeaponName`, `pinnedSuper` on builds in `src/lib/db/schema.ts`
- [ ] T004 Add SQLite migration/bootstrap for nullable exotic armor + new build columns in `src/lib/db/client.ts`
- [ ] T005 [P] Extend create/update zod schemas for optional armor, build-shared weapon, `pinnedSuper`, optional `name`, and `identityAction` in `src/lib/builds/schemas.ts`
- [ ] T006 [P] Update `BuildRecord` / repository mapping types for new nullable fields in `src/lib/builds/` (repository or types module used by `buildService.ts`)
- [ ] T007 Checkpoint: typecheck compiles against new schema/types (`npx tsc --noEmit` or project typecheck script) with no story behavior yet

**Checkpoint**: Foundation ready — user story work can begin

---

## Phase 3: User Story 1 - Establish Build Identity on Save (Priority: P1) 🎯 MVP

**Goal**: Synergies ≥1; optional exotic armor item; build-shared vs variant exotic weapon; optional pinned Super; tags filter-only (not identity)

**Independent Test**: Create build with ≥1 synergy and null exotic armor; set build-shared weapon and/or pinned Super; zero synergies → `NO_SYNERGY`; tag-only PATCH does not require identity confirm (confirm lands in US3 — for US1 assert tags update without forking/errors)

### Tests for User Story 1 ⚠️

> Write FIRST; confirm FAIL before implementation.

- [ ] T008 [P] [US1] Add failing tests for optional exotic armor create/update and `NO_SYNERGY` in `src/lib/builds/buildService.test.ts`
- [ ] T009 [P] [US1] Add failing tests for build-shared exotic weapon preferred over variant in `src/lib/builds/resolveVariant.test.ts`
- [ ] T010 [P] [US1] Add failing tests for `pinnedSuper` persistence on create/update in `src/lib/builds/buildService.test.ts`

### Implementation for User Story 1

- [ ] T011 [US1] Wire nullable exotic armor through create/update in `src/lib/builds/buildService.ts` and skip pair-armor/exotic claims when hash is null
- [ ] T012 [US1] Persist and return build-level `exoticWeaponHash` / `exoticWeaponName` / `pinnedSuper` in `src/lib/builds/buildService.ts`
- [ ] T013 [US1] Prefer build exotic weapon over variant when resolving equipment in `src/lib/builds/resolveVariant.ts`
- [ ] T014 [US1] Accept new identity fields on `POST /api/user/builds` in `src/app/api/user/builds/route.ts` per `specs/015-build-identity/contracts/build-identity-contract.md`
- [ ] T015 [US1] Expose optional exotic armor, build-shared weapon, and pinned Super on create form in `src/app/debug/builds/BuildsDebugPage.tsx`
- [ ] T016 [US1] Run US1 tests green + `npm run gate`; commit checkpoint for User Story 1

**Checkpoint**: US1 independently verifiable via debug create + service/resolve tests

---

## Phase 4: User Story 2 - Require a Full Default Combat Loadout (Priority: P1)

**Goal**: Default variant must have full combat loadout (8 slots + subclass kit + mods presence); non-default may be empty

**Independent Test**: Incomplete default → `DEFAULT_VARIANT_INCOMPLETE` with gaps; complete default saves; empty non-default saves

### Tests for User Story 2 ⚠️

- [ ] T017 [P] [US2] Add failing tests for `assertFullCombatLoadout` missing weapon/armor/mods gaps in `src/lib/builds/resolveVariant.test.ts`
- [ ] T018 [P] [US2] Add failing tests that default save rejects incomplete loadout and non-default empty save succeeds in `src/lib/builds/buildService.test.ts` (and/or `src/lib/builds/variantService.test.ts`)

### Implementation for User Story 2

- [ ] T019 [US2] Implement `assertFullCombatLoadout` (weapons, armor, subclass kit, mods presence) and export structured `DEFAULT_VARIANT_INCOMPLETE` in `src/lib/builds/resolveVariant.ts` per `specs/015-build-identity/contracts/default-loadout-naming-contract.md`
- [ ] T020 [US2] Call full-loadout assert for default variants only inside `validateVariantSave` in `src/lib/builds/buildService.ts`; remove ≥1-slot requirement for non-defaults
- [ ] T021 [US2] Surface incomplete-default error details in `src/app/debug/builds/BuildsDebugPage.tsx` when attach/save fails
- [ ] T022 [US2] Run US2 tests green + `npm run gate`; commit checkpoint for User Story 2

**Checkpoint**: US2 independently verifiable; US1 still green

---

## Phase 5: User Story 3 - Confirm In-Place or Fork When Editing Identity (Priority: P2)

**Goal**: Identity field PATCH requires `identityAction: confirm | fork`; tags/non-identity skip confirm

**Independent Test**: Identity PATCH without action → `IDENTITY_CONFIRM_REQUIRED`; confirm keeps id; fork creates new build with snapshot attachments; tag-only PATCH no confirm

### Tests for User Story 3 ⚠️

- [ ] T023 [P] [US3] Add failing tests for `IDENTITY_CONFIRM_REQUIRED` and confirm in-place in `src/lib/builds/buildService.test.ts`
- [ ] T024 [P] [US3] Add failing tests for fork isolation (original unchanged, new build, snapshot attachments) in `src/lib/builds/buildService.test.ts` and/or `src/lib/builds/variantService.test.ts`

### Implementation for User Story 3

- [ ] T025 [US3] Detect identity-field diffs and require `identityAction` in `src/lib/builds/buildService.ts` per `specs/015-build-identity/contracts/identity-confirm-fork-contract.md`
- [ ] T026 [US3] Implement fork: new build + copy all variants + snapshot-clone attachments via `src/lib/builds/variantService.ts` helpers
- [ ] T027 [US3] Map `IDENTITY_CONFIRM_REQUIRED` / fork response on `PATCH` in `src/app/api/user/builds/[id]/route.ts`
- [ ] T028 [US3] Add Confirm in-place / Fork controls on identity edit in `src/app/debug/builds/BuildsDebugPage.tsx`
- [ ] T029 [US3] Run US3 tests green + `npm run gate`; commit checkpoint for User Story 3

**Checkpoint**: US3 independently verifiable; prior stories still green

---

## Phase 6: User Story 4 - Default Build Names and Per-Class Rename Uniqueness (Priority: P2)

**Goal**: Derived default names (omit missing segments); rename unique per class

**Independent Test**: Blank name → derived segments; duplicate Warlock name rejected; same name on Titan+Warlock allowed

### Tests for User Story 4 ⚠️

- [ ] T030 [P] [US4] Add failing unit tests for segment omit/include rules in `src/lib/builds/defaultBuildName.test.ts`
- [ ] T031 [P] [US4] Add failing uniqueness tests (`DUPLICATE_BUILD_NAME` same class; allow cross-class) in `src/lib/builds/buildService.test.ts`

### Implementation for User Story 4

- [ ] T032 [US4] Implement `deriveDefaultBuildName` in `src/lib/builds/defaultBuildName.ts` per naming contract
- [ ] T033 [US4] Call default name on create when name blank and enforce per-class uniqueness on create/rename in `src/lib/builds/buildService.ts`
- [ ] T034 [US4] Allow optional/blank name on create API in `src/app/api/user/builds/route.ts` and show rename uniqueness errors in `src/app/debug/builds/BuildsDebugPage.tsx`
- [ ] T035 [US4] Run US4 tests green + `npm run gate`; commit checkpoint for User Story 4

**Checkpoint**: All four user stories independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Quickstart validation and doc/trace cleanup

- [ ] T036 [P] Walk `specs/015-build-identity/quickstart.md` V1–V4 against debug UI and note any gaps
- [ ] T037 [P] Update `specs/business-rules.md` cross-links if new error codes (`DEFAULT_VARIANT_INCOMPLETE`, `IDENTITY_CONFIRM_REQUIRED`, `DUPLICATE_BUILD_NAME`) need indexing
- [ ] T038 Final `npm run gate` and ensure all US1–US4 checkpoints remain green

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Start immediately
- **Foundational (Phase 2)**: After Setup — **BLOCKS** all story implementation
- **US1 (Phase 3)**: After Foundational — MVP
- **US2 (Phase 4)**: After Foundational; ideally after US1 (shares validate/save paths)
- **US3 (Phase 5)**: After Foundational; needs US1 identity fields present
- **US4 (Phase 6)**: After Foundational; can parallel US2/US3 if staffed, but shares `buildService.ts`
- **Polish (Phase 7)**: After desired stories complete

### User Story Dependencies

- **US1 (P1)**: No story dependency — MVP
- **US2 (P1)**: Uses resolve/validate paths; best after US1 schema wiring
- **US3 (P2)**: Depends on US1 identity fields existing
- **US4 (P2)**: Independent of US2/US3 logically; file conflict on `buildService.ts` → serialize or coordinate

### Within Each User Story

1. Tests first (fail)
2. Implementation
3. Debug UI as needed
4. Gate + commit checkpoint

### Parallel Opportunities

- T002 with T001
- T005 || T006 after T003/T004
- T008 || T009 || T010 (US1 tests)
- T017 || T018 (US2 tests)
- T023 || T024 (US3 tests)
- T030 || T031 (US4 tests)
- T036 || T037 (polish)

---

## Parallel Example: User Story 1

```text
# After foundation, launch US1 failing tests in parallel:
Task: T008 optional armor + NO_SYNERGY in src/lib/builds/buildService.test.ts
Task: T009 build-shared weapon resolve in src/lib/builds/resolveVariant.test.ts
Task: T010 pinnedSuper in src/lib/builds/buildService.test.ts

# Then implement sequentially where files overlap (buildService → resolve → route → debug)
```

---

## Parallel Example: User Story 4

```text
Task: T030 defaultBuildName.test.ts
Task: T031 uniqueness in buildService.test.ts
# Then T032 helper → T033 service → T034 API/debug
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup  
2. Phase 2 Foundational  
3. Phase 3 US1  
4. **STOP** — validate identity fields via debug + tests  
5. Gate commit  

### Incremental Delivery

1. US1 → identity model  
2. US2 → default completeness  
3. US3 → confirm/fork  
4. US4 → naming  
5. Polish / quickstart  

### Suggested MVP scope

**US1 only** (optional armor, shared weapon, pinned Super, synergies, tags-not-identity)

---

## Notes

- [P] = different files, no incomplete deps
- Co-locate tests next to modules (`*.test.ts`)
- Error codes: `NO_SYNERGY`, `DEFAULT_VARIANT_INCOMPLETE`, `IDENTITY_CONFIRM_REQUIRED`, `DUPLICATE_BUILD_NAME`
- Commit only when story tests + `npm run gate` are green
- Avoid editing the same file in parallel across stories without coordination (`buildService.ts`, `BuildsDebugPage.tsx`)
