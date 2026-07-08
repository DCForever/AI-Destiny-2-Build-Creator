---
description: "Task list for Build Pipeline Consistency"
---

# Tasks: Build Pipeline Consistency

**Input**: Design documents from `/specs/012-build-pipeline-consistency/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are **in scope** (plan Constitution Check + quickstart automated checks). Per constitution: write tests FIRST, confirm FAILING, then implement; commit only when the increment’s tests + `npm run gate` pass.

**Organization**: Phases follow plan delivery order (US1 → US3 → US2 → US4 → US5) so each story stays independently testable while respecting UI dependencies (create before variant attach).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US5 map to spec.md user stories; Setup/Foundational/Polish have no story label
- Exact file paths included in each task

## Path Conventions

Single Next.js project; source at repository root `src/`. Co-located `*.test.ts` beside modules (Constitution IV).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Green baseline; shared debug component folder; no new npm deps.

- [X] T001 Confirm branch `012-build-pipeline-consistency` is checked out and `npm run gate` passes on the current baseline (Constitution III).
- [X] T002 [P] Create `src/components/debug/` directory placeholder (e.g. empty `.gitkeep` or README stub) and confirm `DEBUG.md` prerequisites for Builds/Sets/Synergies/Catalog still apply; no new npm dependencies required.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared helpers + API behavior that all stories depend on (explicit synergies, abilities search, attachment merge/remove, lookup parity helpers).

**⚠️ CRITICAL**: User-story UI work should not begin until this phase’s tests are green and helpers/APIs exist.

### Tests (write first, confirm failing)

- [X] T003 [P] Extend `src/lib/builds/buildService.test.ts`: `createUserBuild` with missing/empty `synergyIds` throws `NO_SYNERGY` and does **not** auto-pick/seed a designation; create with explicit `synergyIds` and empty `defaultVariant` attachments succeeds.
- [X] T004 [P] Add/extend tests for `GET /api/manifest/search` accepting `category=abilities` (and optional `kind` filter) in `src/app/api/manifest/search/route.test.ts` (create if missing).
- [X] T005 [P] Add failing tests for `mergeAttachment` / `removeAttachment` (add, update mode, remove one, preserve others, full-list output) in `src/lib/builds/attachmentMerge.test.ts`.

### Implementation

- [X] T006 Implement `mergeAttachment` and `removeAttachment` (pure helpers producing full `attachments[]` for replace-all PATCH) in `src/lib/builds/attachmentMerge.ts` (depends on T005).
- [X] T007 Update `createUserBuild` in `src/lib/builds/buildService.ts` to require explicit `synergyIds` (min 1); remove silent `listSynergies(...).slice(0,1)` auto-designation on create; keep `assertSynergiesPresent` / not-found checks (depends on T003).
- [X] T008 [P] Extend `createBuildSchema` / docs comments in `src/lib/builds/schemas.ts` so `synergyIds` is required (min 1) on create if not already; align with `contracts/build-create-designation-contract.md`.
- [X] T009 Extend `GET` query schema in `src/app/api/manifest/search/route.ts` with `category: "abilities"` and optional `kind` filter; return `name`/`hash`/`icon`/`kind` (depends on T004).
- [X] T010 [P] Add shared empty-state / identity-field helpers in `src/lib/debug/lookupParity.ts` (+ `lookupParity.test.ts`) per `contracts/debug-lookup-parity-contract.md`.
- [X] T011 Update callers/tests that relied on auto-seeded synergies (`src/lib/builds/buildService.test.ts`, `buildFlow.integration.test.ts`, related fixtures) to create/pass explicit `synergyIds` (depends on T007).

**Checkpoint**: Foundation green — explicit create synergies, abilities search, attachment helpers. `npm run gate` → commit.

---

## Phase 3: User Story 1 - Create a Build Without Manual Hashes (Priority: P1) 🎯 MVP

**Goal**: Debug Builds create uses catalog-backed exotic armor, structured subclass, and synergy multi-select; empty default variant allowed; no synergies → block + link to Synergies debug.

**Independent Test**: On `/debug/builds`, create a build by picking exotic armor, subclass fields, tags, and ≥1 synergy — no hash/JSON primary path; create with zero sets succeeds; with zero synergies, create is blocked with link to `/debug/synergies`.

### Tests for User Story 1 ⚠️

- [X] T012 [P] [US1] Unit tests for exotic-armor result mapping / selection payload (`hash` + `name`) helpers used by the lookup (co-locate beside component helper or in `src/lib/debug/lookupParity.test.ts`).
- [X] T013 [P] [US1] Confirm schema/service reject create without synergies (covered by T003/T008; add UI-facing message constant test only if extracted).

### Implementation for User Story 1

- [X] T014 [P] [US1] Implement `ExoticArmorLookup` in `src/components/debug/ExoticArmorLookup.tsx` (manifest/catalog search → select `{ hash, name }`; empty state via T010).
- [X] T015 [P] [US1] Implement `SynergyMultiSelect` in `src/components/debug/SynergyMultiSelect.tsx` (`GET /api/user/synergies`, filter by name/type, multi-select `synergyIds`; empty list shows message + link to `/debug/synergies`).
- [X] T016 [P] [US1] Implement `SubclassStructuredForm` in `src/components/debug/SubclassStructuredForm.tsx` (class → `SUBCLASSES_BY_CLASS` → abilities via manifest search `abilities` + aspects/fragments; builds `GeneratedBuild.subclass` object; optional advanced JSON collapsed).
- [X] T017 [US1] Rework create section of `src/app/debug/builds/BuildsDebugPage.tsx`: wire T014–T016 + concept tags; remove primary-path raw exotic hash / subclass JSON; submit explicit `synergyIds`; allow empty `defaultVariant`; show validation errors; label any remaining hash fields Advanced (depends on T007, T014–T016).
- [X] T018 [US1] Add exotic-armor picker for **build list filter** on `BuildsDebugPage.tsx` (same identity as create; FR-013) (depends on T014).

**Checkpoint**: US1 independently testable — picker-based create. `npm run gate` → commit.

---

## Phase 4: User Story 3 - Account for Every Variant (Priority: P1)

**Goal**: List/select all variants; variant-scoped actions use selection only; optional exotic weapon set/clear via catalog lookup; duplicate/compare refresh list.

**Independent Test**: Duplicate variant, switch selection, set exotic weapon on copy only, resolve/export each — no silent first-variant targeting; clear selection blocks scoped actions.

### Tests for User Story 3 ⚠️

- [X] T019 [P] [US3] Unit tests for variant list → select options mapping (`id`, `name`, `isDefault`) in `src/components/debug/VariantSelect.test.ts` or helper test beside it.

### Implementation for User Story 3

- [X] T020 [P] [US3] Implement `VariantSelect` in `src/components/debug/VariantSelect.tsx` (props: variants, selectedId, onChange; visible active selection).
- [X] T021 [P] [US3] Implement `ExoticWeaponLookup` in `src/components/debug/ExoticWeaponLookup.tsx` (manifest/catalog exotic weapon search → set/clear `{ hash, name }`).
- [X] T022 [US3] Wire build detail load on select in `BuildsDebugPage.tsx`: populate variants via `VariantSelect`; preselect default **visibly**; disable attach/suggest-sets/resolve/export/duplicate-target actions when no variant selected (depends on T020).
- [X] T023 [US3] Wire exotic weapon set/clear for selected variant via `PATCH /api/user/builds/:id/variants/:variantId` using `ExoticWeaponLookup` in `BuildsDebugPage.tsx`; refresh detail after save (depends on T021, T022).
- [X] T024 [US3] Ensure duplicate/compare/resolve/export/suggest-sets use `selectedVariantId` only; after duplicate, refresh variant list and allow selecting the copy in `BuildsDebugPage.tsx` (depends on T022).

**Checkpoint**: US3 independently testable — multi-variant accounting + exotic weapon. `npm run gate` → commit.

---

## Phase 5: User Story 2 - Attach/Detach Sets With Full Context (Priority: P1)

**Goal**: Filtered set attach (type + tag AND), live/snapshot, additive attach, detach one, confirm target variant name; Pair mismatch still enforced by API.

**Independent Test**: Attach weapon set to variant A and armor set to variant B; attach second set to A without wiping first; detach one; resolved JSON per variant correct.

### Tests for User Story 2 ⚠️

- [X] T025 [P] [US2] Extend `src/lib/builds/attachmentMerge.test.ts` coverage for sequential add + remove scenarios matching debug attach/detach flows (if gaps remain after T005/T006).

### Implementation for User Story 2

- [X] T026 [P] [US2] Implement `SetAttachPicker` in `src/components/debug/SetAttachPicker.tsx` (`GET /api/user/sets?type=&tags=`, set select, live/snapshot, empty state + link to `/debug/sets`).
- [X] T027 [US2] Wire attach on `BuildsDebugPage.tsx`: load current attachments from build detail → `mergeAttachment` → PATCH full list to selected variant; confirm variant name if selection changed mid-flow (depends on T006, T022, T026).
- [X] T028 [US2] List selected variant’s attachments on `BuildsDebugPage.tsx` with **Remove** per row → `removeAttachment` → PATCH full list; remaining attachments unchanged (depends on T006, T027).
- [X] T029 [US2] Surface Pair/exotic and other attach API errors clearly in the JSON/error panel on `BuildsDebugPage.tsx` (depends on T027).

**Checkpoint**: US2 independently testable — additive attach + detach. `npm run gate` → commit.

---

## Phase 6: User Story 4 - Attach and Review Synergies After Create (Priority: P2)

**Goal**: Edit designations on an existing build via SynergyMultiSelect + PATCH; listings show name/type; suggestions reflect remaining designations.

**Independent Test**: Designate two synergies, remove one via save, confirm build detail and suggest flows use the updated set.

### Tests for User Story 4 ⚠️

- [X] T030 [P] [US4] Extend `src/lib/builds/buildService.test.ts` (or existing update tests): `updateUserBuild` with `synergyIds` replaces designations; empty array rejected.

### Implementation for User Story 4

- [X] T031 [US4] Add post-create synergy designation editor on `BuildsDebugPage.tsx`: load current designations, `SynergyMultiSelect`, save via `PATCH /api/user/builds/:id` with `{ synergyIds }`; refresh detail (depends on T015, T017).
- [X] T032 [US4] Display designated synergies (name + type) on selected build summary panel consistent with Synergies debug listing fields in `BuildsDebugPage.tsx` (depends on T031).

**Checkpoint**: US4 independently testable. `npm run gate` → commit.

---

## Phase 7: User Story 5 - Consistent Lookups Across Debug Surfaces (Priority: P2)

**Goal**: Parity matrix for exotic armor, sets, synergies (and exotic weapon where used); shared pickers adopted; advanced raw ID fields labeled; empty states consistent.

**Independent Test**: Walk parity checklist in `contracts/debug-lookup-parity-contract.md` / quickstart Scenario E — same discovery model on every page that needs each entity.

### Tests for User Story 5 ⚠️

- [X] T033 [P] [US5] Extend `src/lib/debug/lookupParity.test.ts` for required identity fields per entity kind in the parity matrix.

### Implementation for User Story 5

- [X] T034 [P] [US5] Audit `src/app/debug/sets/SetsDebugPage.tsx`: ensure set list type+tag AND filters and empty states align with `SetAttachPicker` / parity helpers; label any remaining raw hash fields Advanced.
- [X] T035 [P] [US5] Audit `src/app/debug/synergies/SynergiesDebugPage.tsx`: listing exposes `id`/`name`/`type` consistent with `SynergyMultiSelect`; no happy-path free-text synergy IDs for designation-like flows.
- [X] T036 [P] [US5] Audit `src/app/debug/catalog/CatalogDebugPage.tsx` and `src/app/debug/suggestions/SuggestionsDebugPage.tsx`: exotic/item lookups remain catalog-backed; adopt shared helpers/components where raw IDs remain on happy path.
- [X] T037 [US5] Final pass on `BuildsDebugPage.tsx`: collapse/label all Advanced hash/ID fields; ensure empty states use T010 copy; no happy-path opaque IDs for create/attach/designate/variant/exotic weapon (depends on T017, T022–T028, T031).

**Checkpoint**: US5 parity checklist pass. `npm run gate` → commit.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T038 [P] Update `DEBUG.md` with full pipeline steps (create → synergies → variants → attach/detach → exotic weapon → resolve/compare), empty-create and no-synergy block behavior, and bump **Last reviewed** date (debug-docs rule).
- [X] T039 [P] Align `specs/012-build-pipeline-consistency/quickstart.md` scenarios with detach, exotic weapon, and no-synergy block; manual Scenarios A–F are optional when not signed in, and `npm run gate` is the automated substitute.
- [X] T040 Run `npm run gate` and fix any remaining type/lint/test/build failures across touched files.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Start immediately
- **Foundational (Phase 2)**: Depends on Setup — **blocks** all user stories
- **US1 (Phase 3)**: After Foundational — MVP
- **US3 (Phase 4)**: After US1 create shell exists (needs build select on Builds page); can overlap slightly with US1 if create form lands first
- **US2 (Phase 5)**: After US3 variant selection (needs `selectedVariantId`)
- **US4 (Phase 6)**: After US1 (`SynergyMultiSelect` + create)
- **US5 (Phase 7)**: After shared pickers exist (best after US1–US4)
- **Polish (Phase 8)**: After desired stories complete

### User Story Dependencies

| Story | Depends on | Independently testable after |
|-------|------------|------------------------------|
| US1 | Phase 2 | Phase 3 checkpoint |
| US3 | US1 page shell (build list/create) | Phase 4 checkpoint |
| US2 | US3 variant select + Phase 2 merge helpers | Phase 5 checkpoint |
| US4 | US1 SynergyMultiSelect | Phase 6 checkpoint |
| US5 | Shared pickers from US1–US4 | Phase 7 checkpoint |

### Parallel Opportunities

- T003–T005 tests in parallel; T014–T016 components in parallel; T020–T021 in parallel; T034–T036 audits in parallel; T038–T039 docs in parallel.

### Parallel Example: User Story 1

```bash
# After Phase 2:
Task: "Implement ExoticArmorLookup in src/components/debug/ExoticArmorLookup.tsx"
Task: "Implement SynergyMultiSelect in src/components/debug/SynergyMultiSelect.tsx"
Task: "Implement SubclassStructuredForm in src/components/debug/SubclassStructuredForm.tsx"
# Then wire BuildsDebugPage create section.
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 + 2 (foundation)
2. Phase 3 US1 — picker-based create
3. **STOP**: Validate quickstart Scenario A
4. Gate + commit

### Incremental Delivery

1. US1 → create without hashes  
2. US3 → variant accounting + exotic weapon  
3. US2 → attach/detach sets  
4. US4 → edit designations  
5. US5 → cross-page parity + polish  

### Suggested MVP Scope

**US1 only** (Phases 1–3): proves explicit synergies + catalog exotic + structured subclass. Full pipeline value needs US3+US2 next.

---

## Notes

- Attachment API remains replace-all; always use `attachmentMerge.ts` before PATCH
- Do not reintroduce silent synergy seeding
- Constitution: Test-First + Green Checkpoints at each story checkpoint
- Avoid same-file conflicts: serialize `BuildsDebugPage.tsx` edits across US1→US5
