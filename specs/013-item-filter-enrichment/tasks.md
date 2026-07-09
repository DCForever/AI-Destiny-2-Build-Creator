---
description: "Task list for Item Filter Enrichment"
---

# Tasks: Item Filter Enrichment

**Input**: Design documents from `/specs/013-item-filter-enrichment/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are **in scope** (constitution + plan Constitution Check + quickstart). Write tests FIRST, confirm FAILING, then implement; commit only when the increment’s tests + `npm run gate` pass.

**Organization**: Phases follow spec priority — US1 (enrichment records) → US2 (discovery filters + minimal debug UI) → US3 (shared vs exclusive accuracy). Baseline already has `category=abilities` with `kind`/`classType`/`element` and class-includes-shared; tasks focus on remaining gaps.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US3 map to spec.md user stories; Setup/Foundational/Polish have no story label
- Exact file paths included in each task

## Path Conventions

Single Next.js project; source at repository root `src/`. Co-located `*.test.ts` beside modules (Constitution IV).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm feature branch baseline; no new npm dependencies.

- [ ] T001 Confirm branch `013-item-filter-enrichment` is checked out, `.specify/feature.json` points at `specs/013-item-filter-enrichment`, and `npm run gate` passes on the current baseline (Constitution III).
- [ ] T002 [P] Skim `specs/013-item-filter-enrichment/contracts/ability-enrichment-search-contract.md` and `quickstart.md`; note baseline already in `src/app/api/manifest/search/route.ts` (`abilities`, `kind`, `classType`, `element`, shared-inclusive class filter) vs remaining gaps (`subclass`, `verb`, enrichment fields, debug controls).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared types and override/enrichment module skeletons that all user stories depend on.

**⚠️ CRITICAL**: No user-story implementation until this phase’s types/stubs exist and foundational tests are in place (or explicitly deferred only for empty stubs).

### Tests (write first, confirm failing)

- [ ] T003 [P] Add failing type/shape expectations for `AbilityRecord.subclassAffinities` and `AbilityRecord.verbs` (empty arrays default) in `src/lib/manifest/extractors/extractors2.test.ts` (or a new co-located `abilityEnrichment.test.ts` that imports the record type via a fixture assertion helper).
- [ ] T004 [P] Add failing unit tests for override merge helpers (hash → affinities/verbs) in `src/data/abilityEnrichmentOverrides.test.ts` covering Phoenix Dive / Chaos Reach anchor keys once the module exists.

### Implementation

- [ ] T005 Extend `AbilityRecord` in `src/lib/manifest/types/records.ts` with `subclassAffinities: string[]` and `verbs: string[]` (required arrays; document empty = unknown/none) per `data-model.md` (depends on T003 intent).
- [ ] T006 [P] Create `src/data/abilityEnrichmentOverrides.ts` with typed maps for affinity and verb overrides (include Phoenix Dive → Dawnblade + Prismatic Warlock + Cure; Chaos Reach → Stormcaller + Jolt) and export lookup helpers (depends on T004).
- [ ] T007 Create `src/lib/manifest/extractors/abilityEnrichment.ts` exporting pure functions `deriveSubclassAffinities(...)` and `deriveAbilityVerbs(...)` with stubs returning `[]` (wire real logic in US1); import override helpers from T006.
- [ ] T008 Update ability fixture(s) in `src/lib/manifest/__fixtures__/rawTables.ts` as needed so Chaos Reach (and Phoenix Dive if added) remain extractable; ensure any new AbilityRecord construction sites compile with the new required fields (depends on T005).

**Checkpoint**: Types + override/enrichment stubs compile. `npm run gate` → commit.

---

## Phase 3: User Story 1 - Filter Abilities by Class, Subclass, Element, and Effect (Priority: P1) 🎯 MVP

**Goal**: Enriched ability records expose class, subclass affinities, element, and effect verbs so Phoenix Dive and Chaos Reach satisfy FR-006/FR-007.

**Independent Test**: Extractor/fixture assertions show Phoenix Dive = Warlock + Dawnblade + Prismatic Warlock + Cure; Chaos Reach = Warlock + Stormcaller + Arc + Jolt; abilities with no confident verbs keep `verbs: []`.

### Tests for User Story 1 ⚠️

- [ ] T009 [P] [US1] Expand `src/lib/manifest/extractors/extractors2.test.ts` (and/or `abilityEnrichment.test.ts`) with failing cases: Chaos Reach affinities/verbs; Phoenix Dive affinities/verbs (add fixture item if missing); word-boundary verb tagging does not false-positive on casual description mentions; empty verbs when no match.
- [ ] T010 [P] [US1] Add failing unit tests in `src/lib/manifest/extractors/abilityEnrichment.test.ts` for dedicated plug-category → `SUBCLASS_METADATA` join (e.g. `warlock.arc.supers` → Stormcaller) and class-qualified Prismatic naming (never bare `Prismatic`).

### Implementation for User Story 1

- [ ] T011 [US1] Implement `deriveSubclassAffinities` in `src/lib/manifest/extractors/abilityEnrichment.ts`: dedicated `{class}.{element}.{kind}` → `SUBCLASS_METADATA`; merge plug-set membership when available via `common.ts` helpers; merge overrides from `abilityEnrichmentOverrides.ts` (depends on T007, T010).
- [ ] T012 [US1] Implement `deriveAbilityVerbs` in `src/lib/manifest/extractors/abilityEnrichment.ts`: best-effort word-boundary scan of description (+ sandbox perk text when resolvable) against `SYNERGY_VERBS` / `resolveVerbSubType`; merge overrides; dedupe canonical names (depends on T007, T009).
- [ ] T013 [US1] Wire enrichment into `src/lib/manifest/extractors/abilities.ts` so each `AbilityRecord` sets `subclassAffinities` and `verbs` (depends on T011, T012, T005).
- [ ] T014 [US1] Add/adjust Phoenix Dive (and any needed) raw fixture entries in `src/lib/manifest/__fixtures__/rawTables.ts`; make T009–T010 pass (depends on T013).
- [ ] T015 [US1] Ensure entity-cache consumers tolerate new fields (rebuild note in comments or extract path); fix any TypeScript breakages in ability record mocks under `src/lib/synergies/subTypeVocabularies.test.ts` and related tests (depends on T005, T013).

**Checkpoint**: US1 independently testable — enriched records for anchors. `npm run gate` → commit.

---

## Phase 4: User Story 2 - Discover Items Without Memorizing Exact Names (Priority: P1)

**Goal**: Structured `subclass` + `verb` filters (AND with existing dimensions) find Phoenix Dive / Chaos Reach without exact names; minimal debug controls on `SubclassStructuredForm` expose the same filters.

**Independent Test**: `GET /api/manifest/search?category=abilities&classType=Warlock&verb=Cure&subclass=Dawnblade` returns Phoenix Dive; Stormcaller+Arc+Jolt+super returns Chaos Reach; debug UI can set verb/subclass without typing the ability name.

### Tests for User Story 2 ⚠️

- [ ] T016 [P] [US2] Extend `src/app/api/manifest/search/route.test.ts` with failing cases for `subclass` and `verb` query params (AND semantics), enriched response fields (`subclassAffinities`, `verbs`, `description`), and alias resolution (`Suppress` → `Suppression`).
- [ ] T017 [P] [US2] Add failing tests for debug form query wiring (subclass/verb params passed to `/api/manifest/search`) in `src/components/debug/SubclassStructuredForm.test.tsx` (create if missing) or a small extracted helper test beside the form.

### Implementation for User Story 2

- [ ] T018 [US2] Extend `querySchema` and filters in `src/app/api/manifest/search/route.ts` with optional `subclass` and `verb`; AND with existing `kind`/`classType`/`element`; resolve verb aliases via `resolveVerbSubType` (depends on T016).
- [ ] T019 [US2] Extend ability search response mapping in `src/app/api/manifest/search/route.ts` to include `description`, `subclassAffinities`, and `verbs` when present on the record (depends on T013, T018).
- [ ] T020 [US2] Update `src/lib/manifest/itemResolver.ts` so abilities search indexes description (and optionally verbs) for text `q` while preserving FR-010 (depends on T005).
- [ ] T021 [US2] Add minimal subclass + verb filter controls to `src/components/debug/SubclassStructuredForm.tsx` (and pass params in `fetchResults`) per contract debug UI table; show enrichment hints in results when available (depends on T017, T018, T019).
- [ ] T022 [US2] Make T016–T017 pass; manually smoke-check quickstart V2 queries (depends on T018–T021).

**Checkpoint**: US2 independently testable — nameless discovery via API + minimal debug UI. `npm run gate` → commit.

---

## Phase 5: User Story 3 - Enrichment Stays Accurate Across Shared and Exclusive Items (Priority: P2)

**Goal**: Shared abilities list element-matched dedicated subclasses (Prismatic only when proven); class filters include shared; wrong class/subclass/element exclusions hold.

**Independent Test**: Shared Arc grenade affinities include Striker/Arcstrider/Stormcaller without auto-all Prismatic; `classType=Warlock&kind=grenade` includes shared grenades; Titan+Cure excludes Phoenix Dive; Voidwalker subclass filter excludes Phoenix Dive.

### Tests for User Story 3 ⚠️

- [ ] T023 [P] [US3] Add failing affinity tests in `src/lib/manifest/extractors/abilityEnrichment.test.ts` for shared plugs: element-matched dedicated subclasses only; Prismatic affinities absent unless override/plug-set proves membership.
- [ ] T024 [P] [US3] Extend `src/app/api/manifest/search/route.test.ts` with failing/asserting cases: class filter includes shared; wrong-class and wrong-subclass negatives for Phoenix Dive / Chaos Reach (align with quickstart V3).

### Implementation for User Story 3

- [ ] T025 [US3] Complete shared-plug branch of `deriveSubclassAffinities` in `src/lib/manifest/extractors/abilityEnrichment.ts` per research R2 tier 2–3 and clarify Q3 (depends on T011, T023).
- [ ] T026 [US3] Confirm/preserve `classTypeFilter` shared-inclusive behavior in `src/app/api/manifest/search/route.ts`; document in a brief comment referencing FR-001 clarify; fix if any regression (depends on T024).
- [ ] T027 [US3] Add shared-grenade (or equivalent) fixture coverage in `src/lib/manifest/__fixtures__/rawTables.ts` and make T023–T024 pass (depends on T025, T026).

**Checkpoint**: US3 independently testable — exclusivity + shared semantics. `npm run gate` → commit.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end validation and cleanup across stories.

- [ ] T028 [P] Run through `specs/013-item-filter-enrichment/quickstart.md` V1–V4; fix any doc/contract mismatches in `contracts/ability-enrichment-search-contract.md` or `quickstart.md`.
- [ ] T029 [P] Rebuild abilities entity cache (project’s usual extract/cache refresh) and spot-check live Phoenix Dive / Chaos Reach enrichment if manifest is available.
- [ ] T030 Final `npm run gate`; ensure no leftover stubs returning empty enrichment for wired paths; commit polish checkpoint.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational — MVP enrichment records
- **US2 (Phase 4)**: Depends on Foundational; practically needs US1 enrichment fields on records for meaningful filter hits
- **US3 (Phase 5)**: Depends on Foundational + US1 affinity derivation; refines shared/exclusive behavior used by US2 filters
- **Polish (Phase 6)**: Depends on desired user stories complete

### User Story Dependencies

- **US1 (P1)**: After Foundational — no dependency on US2/US3
- **US2 (P1)**: After Foundational; uses US1 record fields for discovery demos
- **US3 (P2)**: After US1 derivation exists; hardens shared/exclusive rules for US2 filters

### Within Each User Story

- Tests MUST be written and confirmed FAILING before implementation
- Derivation helpers before extractor wiring
- Extractor/record fields before search DTO/filters
- Search filters before debug UI wiring
- Story complete (tests + gate) before next priority when sequencing solo

### Parallel Opportunities

- T003/T004 in Foundational tests in parallel
- T009/T010 US1 tests in parallel
- T016/T017 US2 tests in parallel
- T023/T024 US3 tests in parallel
- T028/T029 polish in parallel
- After Foundational, US1 must lead; US2/US3 can partially overlap once T013 lands if staffed

---

## Parallel Example: User Story 1

```bash
# Launch US1 tests together:
Task: "Expand extractors2/abilityEnrichment failing cases for Phoenix Dive / Chaos Reach"
Task: "Add failing unit tests for plug-category → SUBCLASS_METADATA join"

# After tests fail, implement derivation then wire extractor:
Task: "Implement deriveSubclassAffinities in abilityEnrichment.ts"
Task: "Implement deriveAbilityVerbs in abilityEnrichment.ts"
```

---

## Parallel Example: User Story 2

```bash
# Launch US2 tests together:
Task: "route.test.ts subclass/verb AND + enriched DTO"
Task: "SubclassStructuredForm filter wiring tests"

# Then implement route filters/DTO and debug controls (DTO depends on US1 fields):
Task: "Add subclass/verb to manifest search route"
Task: "Add minimal subclass/verb controls to SubclassStructuredForm"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1–2
2. Complete Phase 3 (US1 enrichment records)
3. **STOP and VALIDATE**: Phoenix Dive / Chaos Reach fields via extractor tests
4. Demo/commit MVP

### Incremental Delivery

1. Setup + Foundational → types/overrides ready
2. US1 → enriched records (MVP)
3. US2 → nameless discovery API + minimal debug UI
4. US3 → shared/exclusive accuracy
5. Polish → quickstart + cache rebuild + gate

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. Dev A: US1 enrichment
3. After T013: Dev B starts US2 route/UI; Dev A continues US3 shared affinity hardening
4. Integrate and polish together

---

## Notes

- [P] = different files, no incomplete-task dependencies
- Baseline already includes abilities search + class-includes-shared — do not regress T026
- Prismatic affinities MUST be class-qualified (`Prismatic Warlock`, etc.)
- Verb tagging is best-effort whitelist + overrides — not a full hand map
- Commit only at green checkpoints (`npm run gate`)
- Suggested MVP: Phase 1–3 (US1 only)
