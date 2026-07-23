# Tasks: Catalog Universal Search

**Input**: Design documents from `/specs/027-catalog-universal-search/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md  
**Tests**: Constitution requires test-first for new behavior (co-located vitest).  
**Organization**: By user story for independent delivery.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Parallelizable (different files, no incomplete deps)
- **[Story]**: US1–US5 from spec.md

## Phase 1: Setup

- [ ] T001 Verify feature docs and paths in specs/027-catalog-universal-search/plan.md match intended src layout
- [ ] T002 [P] Note FR-015–FR-018 clarifications (Universal mode, Set+Synergy only, create wizard, Pair targets, instance pin 1/many/none) in specs/027-catalog-universal-search/plan.md Delivery Mapping if missing

---

## Phase 2: Foundational (BLOCKS stories)

- [ ] T003 [P] Create CompositionKind enum + set/synergy action eligibility in src/lib/catalog/compositionKinds.ts
- [ ] T004 [P] Create compositionKinds tests in src/lib/catalog/compositionKinds.test.ts (fail first)
- [ ] T005 Implement searchCompositionCatalog multi-store search + rank + soft per-kind caps in src/lib/catalog/universalSearch.ts using src/lib/search/descriptionMatch.ts
- [ ] T006 Create universalSearch unit tests in src/lib/catalog/universalSearch.test.ts (match, rank, NEED_QUERY, kind filter, empty)
- [ ] T007 [P] Zod query schema for universal search in src/lib/catalog/universalSearchSchema.ts
- [ ] T008 Wire GET route src/app/api/catalog/universal-search/route.ts (503 MANIFEST_NOT_READY; ownership annotate when authed)
- [ ] T009 Contract tests in src/app/api/catalog/universal-search/route.test.ts per contracts/universal-search-contract.md

**Checkpoint**: API returns mixed hits; gate green on new tests

---

## Phase 3: US1 — Universal search UI (P1) MVP

**Goal**: Catalog Universal mode with mixed-kind search results  
**Independent Test**: Query melee / known trait; mixed labels; no-match and manifest-not-ready distinct

- [ ] T010 [P] [US1] Add CatalogKind or mode `universal` to src/components/catalog/catalogScreenTypes.ts
- [ ] T011 [US1] Fetch /api/catalog/universal-search and render mixed hit list in src/components/catalog/CatalogScreen.tsx (or src/components/catalog/UniversalSearchPanel.tsx)
- [ ] T012 [US1] Universal mode/tab chrome in src/components/catalog/CatalogScreen.tsx without breaking weapons/armor browse
- [ ] T013 [US1] Empty states NEED_QUERY / no matches / MANIFEST_NOT_READY in Catalog universal UI
- [ ] T014 [US1] Show ownership badge on equippable hits when owned summary present

**Checkpoint**: US1 manual quickstart search steps pass

---

## Phase 4: US2 — Detail pane (P1)

**Goal**: Open hit detail; back keeps query  
**Independent Test**: Gear + perk/trait detail; back restores results

- [ ] T015 [US2] Detail panel for CompositionSearchHit in src/components/catalog/UniversalHitDetail.tsx (name, kind, description, meta)
- [ ] T016 [US2] Selection state + query snapshot restore on back in CatalogScreen/Universal panel
- [ ] T017 [P] [US2] Optional owned instances fetch for equippable hash (reuse instances API pattern from CatalogScreen)

**Checkpoint**: US2 independent test

---

## Phase 5: US3 — Set create/add (P1)

**Goal**: Create/Add Set from detail with wizard, Pair rules, instance pin FR-018  
**Independent Test**: Create/add weapon set; dual-exotic blocked; multi-instance pick

- [ ] T018 [P] [US3] Set type/slot eligibility helpers in src/lib/catalog/setPlacementFromHit.ts (+ tests setPlacementFromHit.test.ts)
- [ ] T019 [US3] Create Set wizard UI (name, type, slot, instance per FR-016/018) in src/components/catalog/UniversalSetActions.tsx
- [ ] T020 [US3] Add to existing Set flow (list compatible sets, slot, replace confirm) calling existing /api/user/sets APIs
- [ ] T021 [US3] Wire Set CTAs only when actions.set; sign-in gate when unsigned
- [ ] T022 [US3] Success confirmation (FR-014) after set mutation

**Checkpoint**: US3 quickstart Set steps

---

## Phase 6: US4 — Synergy create/add (P2)

**Goal**: Create/Add Synergy link from valid evidence hits  
**Independent Test**: Perk/trait → synergy link; no duplicate; hide CTA when ineligible

- [ ] T023 [P] [US4] Map hit → SynergyLinkInput in src/lib/catalog/synergyLinkFromHit.ts (+ tests)
- [ ] T024 [US4] Synergy actions UI in src/components/catalog/UniversalSynergyActions.tsx using existing synergies APIs
- [ ] T025 [US4] Dedupe already-linked targets; disable synergy CTA when actions.synergy false
- [ ] T026 [US4] Sign-in gate + success confirmation for synergy mutations

**Checkpoint**: US4 quickstart Synergy steps

---

## Phase 7: US5 — Kind filters (P3)

**Goal**: Filter mixed results by kind without clearing query  
**Independent Test**: Chip narrows list; over-narrow filtered empty

- [ ] T027 [US5] kinds query param already on API — ensure UI multi kind chips call kinds=
- [ ] T028 [US5] FILTERED_EMPTY vs no-match messaging in universal results UI

**Checkpoint**: US5 independent test

---

## Phase 8: Polish

- [ ] T029 [P] Align plan/quickstart with FR-015–018 if drift
- [ ] T030 Run npm run gate; fix failures
- [ ] T031 Manual smoke per specs/027-catalog-universal-search/quickstart.md
- [ ] T032 [P] Optional BR note in specs/business-rules.md if product rule not captured

---

## Dependencies

- Setup → Foundational → US1 → US2 → US3 → US4 → US5 → Polish
- US4 can start after US2 (needs detail); US5 after US1
- MVP = Phase 1–3 (Foundational + US1)

## Parallel examples

```text
T003+T004 compositionKinds
T007 schema || T005–T006 search core after kinds
T018 || T023 placement/link mappers during US3/US4
```

## MVP

Ship Foundational + US1 (universal search API + Catalog Universal mode list). Then US2–US3 for composition value.
