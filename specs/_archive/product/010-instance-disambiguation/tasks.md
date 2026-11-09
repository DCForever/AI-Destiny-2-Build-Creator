---
description: "Task list for Instance Disambiguation Picker"
---

# Tasks: Instance Disambiguation Picker

**Input**: Design documents from `/specs/010-instance-disambiguation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are **in scope** (spec Verification + quickstart "Automated coverage" table) and the constitution requires Test-First. Per story, tests are written FIRST and confirmed FAILING before implementation; commits happen only at green checkpoints after the increment's tests + `npm run gate` pass.

**Organization**: Tasks are grouped by user story (priority order from spec.md) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US5 (maps to spec.md user stories); Setup/Foundational/Polish carry no story label
- Exact file paths are included in each task

## Path Conventions

Single Next.js project; source at repository root `src/`. Co-located `*.test.ts(x)` beside each module (Constitution IV).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish a green baseline; confirm no new dependencies or tooling are needed.

- [X] T001 Confirm branch `010-instance-disambiguation` is checked out and `npm run gate` passes on the current baseline (green starting point per Constitution III).
- [X] T002 [P] Confirm required manifest entity stores (`weapons`, `weapon-perks`, `set-bonuses`) build and the debug prerequisites in `DEBUG.md` are met; verify no new npm dependencies are required by this feature.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Additive, nullable DB schema for both P1/P2 stories, done once in the shared DB files to avoid cross-story conflicts. Both columns are backward compatible (SC-007); `gear_tier` requires a one-time re-sync to backfill.

**⚠️ CRITICAL**: No user story work should modify `src/lib/db/schema.ts` / `client.ts` until this phase is complete.

- [X] T003 Extend the migration smoke test in `src/lib/db/schema.test.ts` to assert that `set_items.instance_id` and `inventory_items.gear_tier` exist after `runMigrations` (write FIRST; must FAIL before T004/T005).
- [X] T004 [P] Add `setItems.instanceId` (`text("instance_id")`) and `inventoryItems.gearTier` (`integer("gear_tier")`) to the drizzle schema in `src/lib/db/schema.ts`.
- [X] T005 [P] Add idempotent `ensureSetItemInstanceIdColumn(db)` and `ensureGearTierColumn(db)` (PRAGMA `table_info` + `ALTER TABLE ADD COLUMN`, mirroring `ensureStatValuesColumn`) and invoke both from `runMigrations` in `src/lib/db/client.ts`.
- [X] T006 [P] Add `gearTier: number | null` to the `UserInventoryItem` row shape in `src/lib/db/types.ts`.

**Checkpoint**: Migrations pass (T003 green); DB row shape carries `gearTier`. `npm run gate` clean → commit.

---

## Phase 3: User Story 1 - Compare Matching Instances in a Carousel (Priority: P1) 🎯 MVP

**Goal**: After the user selects a single owned item, show **all owned copies** of that one item as a carousel of distinct, navigable cards (identity: instanceId, power, location); reuse existing empty/sync prompts.

**Independent Test**: On `/debug/sets` with synced inventory, select an item owned in ≥3 copies → a carousel of distinct cards renders (one per copy), each with a distinguishable identity, and the user can move between cards. Owning exactly one copy → single selectable card; unsynced/unsigned → existing prompt (not an empty carousel).

### Tests for User Story 1 ⚠️ (write first, confirm failing)

- [X] T007 [P] [US1] Tests for the candidate-session reducer **core** (`open`, `select`, `next`/`prev` with clamp/wrap, derived `visible = all − removed`) in `src/lib/inventory/instances/candidateSession.test.ts`.

### Implementation for User Story 1

- [X] T008 [US1] Implement the pure reducer core (`open(itemHash, kind, all)`, `select`, `next`, `prev`, `visible` derivation; `removedInstanceIds` present but empty) in `src/lib/inventory/instances/candidateSession.ts` (depends on T007).
- [X] T009 [P] [US1] Create presentational `InstanceCarousel.tsx` (renders `visible[]` cards with copy identity — instanceId, power, location/character; prev/next navigation) in `src/app/debug/sets/InstanceCarousel.tsx`.
- [X] T010 [US1] Wire the carousel into `src/app/debug/sets/SetsDebugPage.tsx`: on selecting an owned item (gate via `CatalogItem.ownedCount`), fetch instances via `instancesHref`, `open` the candidate session, and route unsynced/unsigned/no-copies to the existing sync-required/empty states (depends on T008, T009).

**Checkpoint**: US1 independently testable — carousel of copies renders and navigates. `npm run gate` clean → commit.

---

## Phase 4: User Story 2 - See Full Weapon Perks and Full Armor Detail per Copy (Priority: P1)

**Goal**: Each card shows kind-appropriate detail. Armor: **Tier** (exact from `gearTier`, stat-band estimate fallback, else "unavailable"), all six Armor 3.0 stats + total (incomplete flagged), and **Set Bonus** (2-piece & 4-piece, or "no set bonus"). Weapon: all equipped perks (already in the DTO), unresolved plugs shown by hash.

**Independent Test**: For a multi-copy weapon, each card lists every perk on that copy; for a multi-copy armor piece, each card shows Tier, all six stat values + total, and both set-bonus tiers — with explicit unavailable/incomplete/no-set indicators where applicable.

### Tests for User Story 2 ⚠️ (write first, confirm failing)

- [X] T011 [P] [US2] Tests for `resolveArmorTier` precedence (`gearTier`→`source:"api"`; exotic→`"Exotic"`; legacy `null`+complete stats→`source:"estimated"` `"~Tier N"` via `ARMOR_TIER_BANDS`; else→`source:"none"` unavailable) in `src/data/rules/armorTiers.test.ts`.
- [X] T012 [P] [US2] Tests for `armorSetBonus` inversion `Map<itemHash, SetBonusRecord>` + lookup (member→2pc/4pc tiers; non-member→`null`) in `src/lib/inventory/instances/armorSetBonus.test.ts`.
- [X] T013 [P] [US2] Tests for `parseGearTier` capture: `DestinyItemInstanceComponent.gearTier` (component 300) → `UserInventoryItem.gearTier`, `null` when absent, in `src/lib/bungie/profile.test.ts`.
- [X] T014 [US2] Extend `src/lib/inventory/instances/projectInstance.test.ts`: armor projection gains `tier` + `setBonus`; incomplete stats flagged; no-set → `setBonus: null`; **weapon projection unchanged** — including an assertion that a weapon's `plugs[]` contains **every** equipped socket hash from `item.plugHashes` (unresolved passed through by hash) so FR-003/SC-002 coverage is guaranteed (regression).

### Implementation for User Story 2

- [X] T015 [P] [US2] Implement `resolveArmorTier({ gearTier, totalStats, isExotic, statsComplete })` + `ARMOR_TIER_BANDS` (source-cited) in `src/data/rules/armorTiers.ts`.
- [X] T016 [P] [US2] Implement `armorSetBonus.ts` (build `Map<itemHash, SetBonusRecord>` by inverting `SetBonusRecord.itemHashes`, plus `lookup(itemHash)`) in `src/lib/inventory/instances/armorSetBonus.ts`.
- [X] T017 [P] [US2] Add `parseGearTier(instance)` and populate `gearTier` in `parseInventoryItemAttempt` / inventory persistence in `src/lib/bungie/profile.ts` (depends on T006 column/type).
- [X] T018 [P] [US2] Extend `OwnedInstanceDetail` with `tier?: ArmorTier` and `setBonus?: ArmorSetBonusSummary | null`, and declare `ArmorTier` / `ArmorSetBonusSummary` / `SetBonusTier` types, in `src/lib/inventory/instances/types.ts`.
- [X] T019 [US2] Extend `src/lib/inventory/instances/loadInstanceContext.ts` (and the `InstanceListContext` interface) to build an armor-metadata lookup keyed by `itemHash` providing both the `SetBonusRecord` (from the `set-bonuses` store, via T016) and an `isExotic` flag (from the exotic-armor store / item `tierType === 6`), and thread it through `listUserInstances.ts` into `projectInstance` (depends on T016).
- [X] T020 [US2] Change the `projectInstance` signature to accept the armor-metadata lookup from T019, and (armor only) attach `tier` via `resolveArmorTier({ gearTier: item.gearTier, totalStats, isExotic: meta.isExotic, statsComplete: !statsIncomplete })` and `setBonus` via `meta.setBonus ?? null`. Update all call sites (`listUserInstances.ts`) and `projectInstance.test.ts` fixtures for the new signature (depends on T015, T016, T018, T019).
- [X] T021 [US2] Render armor detail (Tier label incl. `approximate`/unavailable, six stats + total + `statsIncomplete` flag, set bonus 2pc/4pc or "no set bonus") and, for weapons, **every** equipped socket plug from `OwnedInstanceDetail.plugs[]` in socket order (unresolved shown by hash, FR-004). Note: `plugs[]` is a flat, socket-ordered list without column labels and includes non-perk sockets (masterwork/mods/cosmetics); render in order (optionally de-emphasize obvious cosmetic plugs). Explicit per-column grouping would need a sync-side socket-index change (out of scope). File: `src/app/debug/sets/InstanceCarousel.tsx` (depends on T020, T009).

**Checkpoint**: US2 independently testable — armor cards show Tier/stats/set bonus, weapon cards show all perks. `npm run gate` clean → commit.

---

## Phase 5: User Story 3 - Pick a Single Instance and Attach It (Priority: P1)

**Goal**: Select exactly one copy and attach it to a **set** slot, recording the specific `instanceId` (+ default equipped `selectedPerks`); preserve slot compatibility and occupied-slot replace confirmation.

**Independent Test**: Attach one copy from a multi-copy carousel to a set slot → the saved set item references that copy's `instanceId`; attaching a different copy yields a different reference; occupied-slot replace confirmation still applies.

### Tests for User Story 3 ⚠️ (write first, confirm failing)

- [X] T022 [P] [US3] Tests for `setItemInputSchema` accepting optional `instanceId` (min-1 string; empty string → invalid) in `src/lib/sets/schemas.test.ts`.
- [X] T023 [P] [US3] Tests for `upsertSetItem`: persists `instanceId` on `SetItemRecord`; two copies (same `itemHash`, different `instanceId`) are distinguishable; omitted `selectedPerks` defaults to the instance's equipped plug hashes; occupied-slot `confirmReplace` regression, in `src/lib/sets/setItemService.test.ts`.

### Implementation for User Story 3

- [X] T024 [P] [US3] Add `instanceId: z.string().min(1).optional()` to `setItemInputSchema` in `src/lib/sets/schemas.ts`.
- [X] T025 [US3] Persist `instanceId` in `upsertSetItem` and add `instanceId: string | null` to `SetItemRecord` in `src/lib/sets/setItemService.ts` (depends on T024, T004/T005 column).
- [X] T026 [US3] Wire single-select + Attach in `src/app/debug/sets/SetsDebugPage.tsx`: send the selected copy's `instanceId` (default `selectedPerks` = equipped), preserving existing replace confirmation and slot rules (depends on T010, T025).

**Checkpoint**: P1 complete (US1+US2+US3) — the meaningful shippable increment. `npm run gate` clean → commit.

---

## Phase 6: User Story 4 - Select Which Weapon Perks to Record on Attachment (Priority: P2)

**Goal**: For a selected weapon copy, offer per-socket **all plug options that copy can hold** (curated ∪ randomized), mark equipped via the copy's plugs, default to equipped, and record the selection; armor shows no perk step; degrade to equipped-only when options are unavailable.

**Independent Test**: Select a weapon copy with multiple options per socket, choose a non-equipped alternative in one column, attach → the set item records the chosen perks; a socket with no alternatives shows only the equipped perk; armor shows no perk step.

### Tests for User Story 4 ⚠️ (write first, confirm failing)

- [X] T027 [P] [US4] Tests for `resolveWeaponPerkOptions(itemHash)` (per column curated ∪ randomized, de-duplicated; unresolved hash → name falls back to hash string; unknown/non-weapon → empty `columns`) in `src/lib/catalog/weaponPerkOptions.test.ts`.
- [X] T028 [P] [US4] Tests for the perk-options route (200 shape; `400` missing/invalid `itemHash`; unavailable weapon → `200` with `columns: []`) in `src/app/api/catalog/weapons/perk-options/route.test.ts`.

### Implementation for User Story 4

- [X] T029 [P] [US4] Implement `resolveWeaponPerkOptions(itemHash)` (compose `weapons` `perkColumns` + `weapon-perks` names) in `src/lib/catalog/weaponPerkOptions.ts`.
- [X] T030 [US4] Implement `GET /api/catalog/weapons/perk-options?itemHash=` (zod-validate `itemHash`, return `{ itemHash, columns }`, empty columns on unavailable) in `src/app/api/catalog/weapons/perk-options/route.ts` (depends on T029).
- [X] T031 [US4] Add the per-socket perk-selection step in `src/app/debug/sets/SetsDebugPage.tsx`: lazily fetch options for the chosen weapon copy, mark equipped by intersecting with copy `plugs[].hash`, default to equipped, degrade to equipped-only when `columns: []`, and show no perk step for armor (depends on T026, T030).

**Checkpoint**: US4 independently testable — weapon perk selection records chosen roll. `npm run gate` clean → commit.

---

## Phase 7: User Story 5 - Remove Unwanted Candidates from the Carousel (Priority: P2)

**Goal**: Remove candidates from the current session (never mutating inventory), reset/restore, and show a clear empty state when all are removed.

**Independent Test**: Open a multi-copy carousel, remove two copies → they disappear but inventory is unchanged; remaining copies stay selectable; reset restores removed copies; removing all shows an empty state with reset/re-search.

### Tests for User Story 5 ⚠️ (write first, confirm failing)

- [X] T032 [P] [US5] Extend `src/lib/inventory/instances/candidateSession.test.ts` with `removeCandidate` (session-only; clears `selectedInstanceId` if it was removed) and `resetCandidates` (restores all) transitions.

### Implementation for User Story 5

- [X] T033 [US5] Add `removeCandidate(instanceId)` and `resetCandidates()` transitions to `src/lib/inventory/instances/candidateSession.ts` (depends on T008, T032).
- [X] T034 [US5] Add a per-card remove control plus reset control and empty-state (with re-search/reset) in `src/app/debug/sets/InstanceCarousel.tsx` and `src/app/debug/sets/SetsDebugPage.tsx` (depends on T021, T033).

**Checkpoint**: All stories complete. `npm run gate` clean → commit.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T035 [P] Update `DEBUG.md` (carousel disambiguation flow, `perk-options` endpoint, one-time re-sync note for `gear_tier`, edge-case table) and bump its **Last reviewed** date, per the `debug-docs` rule.
- [X] T036 Run `quickstart.md` Scenario A + Scenario B + edge cases, then `npm run gate` (typecheck + lint + test + build) for the full-feature green checkpoint. (Automated gate green — 585 tests + build; manual Scenario A/B require a live signed-in session with synced inventory.)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup; **blocks** any story task that touches `src/lib/db/*` (T017, T025).
- **User Stories (Phase 3–7)**: depend on Foundational. Priority order US1 → US2 → US3 (P1) → US4 → US5 (P2). US1–US3 are independently testable; US4 and US5 build on the US1–US3 surface.
- **Polish (Phase 8)**: depends on all targeted stories being complete.

### Key cross-task dependencies

- T003 (failing migration test) → T004, T005, T006.
- T007 → T008; T008 → T010, T033.
- T009 → T021, T034.
- T006 → T017 (parse populates the new column/field).
- T015, T016, T018, T019 → T020; T016 → T019; T020 + T009 → T021.
- T024 → T025 → T026; T026 → T031.
- T029 → T030 → T031.
- T032 → T033 → T034.

### Shared-file serialization (NOT parallel)

- `src/app/debug/sets/SetsDebugPage.tsx`: T010 → T026 → T031 (and reset wiring in T034) run sequentially.
- `src/app/debug/sets/InstanceCarousel.tsx`: T009 → T021 → T034 run sequentially.
- `src/lib/inventory/instances/candidateSession.ts`: T008 → T033.
- `src/lib/db/schema.ts` / `client.ts` / `schema.test.ts`: confined to Phase 2.

---

## Parallel Opportunities

- **Phase 1**: T002 ∥ T001.
- **Phase 2 (after T003)**: T004 ∥ T005 ∥ T006 (different files).
- **US2 tests**: T011 ∥ T012 ∥ T013 ∥ T014 (distinct files).
- **US2 impl**: T015 ∥ T016 ∥ T017 ∥ T018 (distinct files); then T019 → T020 → T021.
- **US3 tests**: T022 ∥ T023; **US4 tests**: T027 ∥ T028.
- Once Foundational is done, P1 stories can be staffed in parallel, respecting the shared-file serialization above.

### Parallel Example: User Story 2 tests

```bash
Task: "resolveArmorTier precedence tests in src/data/rules/armorTiers.test.ts"
Task: "armorSetBonus map/lookup tests in src/lib/inventory/instances/armorSetBonus.test.ts"
Task: "parseGearTier capture tests in src/lib/bungie/profile.test.ts"
Task: "projectInstance armor tier/setBonus + weapon-unchanged tests in src/lib/inventory/instances/projectInstance.test.ts"
```

---

## Implementation Strategy

### MVP scope

- **Minimum**: Phase 1 + Phase 2 + **US1** (carousel of copies) — proves the disambiguation surface end-to-end.
- **Shippable P1 increment**: US1 + US2 + US3 — compare copies with full detail and attach the chosen `instanceId` to a set. This is the recommended first release.

### Incremental delivery

1. Setup + Foundational → migrations green.
2. US1 → carousel (MVP) → gate → commit.
3. US2 → per-card detail → gate → commit.
4. US3 → instance attach → **P1 complete** → gate → commit.
5. US4 → weapon perk selection → gate → commit.
6. US5 → candidate removal → gate → commit.
7. Polish (DEBUG.md + quickstart validation).

### Notes

- Verify each story's tests FAIL before implementing (Test-First, NON-NEGOTIABLE).
- Commit only at checkpoints where the increment's tests pass and `npm run gate` is clean (Green Checkpoints).
- `gear_tier` backfill requires a one-time inventory re-sync; legacy `null` rows resolve via the stat-band estimate or "unavailable" until re-synced.
- All new external inputs (`instanceId`, `itemHash`) are zod-validated at route boundaries (Constitution V).
