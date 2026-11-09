# Feature Specification: DART-007 Finish Gaps

**Feature Branch**: `dart-007-finish-gaps`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port finishGaps / next-slot pure helpers. Gap list stable for default vs non-default fixtures."

**Program ID**: DART-007  
**Phase**: P0  
**Depends**: DART-005 (resolve/completeness context), DART-006 (equip-ready sibling; not a runtime dep)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure finish-gap evaluation and next-slot / post-mutation walkthrough helpers in `packages/domain` that mirror TypeScript:

- `src/lib/builds/finishGaps.ts` — `evaluateFinishGaps`, category statuses, `nextActionable`, labels
- `src/lib/builds/finishNextSlot.ts` — `firstEmptyRequiredSlot`, `resolvePostMutationStep`, `shouldOpenArmorOptimize`, `showFinishCreateActions`, `finishCategoryToSetType`

**Out of scope (later slices):** IO adapters that load build detail (`finishGapsFromDetail` DB/API shaping beyond pure claim maps), optimizer core (DART-008), UI walkthrough chrome (P3/P4), equip/DIM, soft auto-apply, Node sidecar.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gap list for empty / partial / complete kits (Priority: P1)

As a multiplatform domain engineer, I can evaluate finish gaps for a variant from pure attachments + equipment claims and get a stable ordered list (armor → weapon → mod) with statuses `needs_set` | `capture_available` | `needs_fill` | `satisfied` so guided finish can show the same gap model as product TS.

**Why this priority**: Roadmap exit criterion — gap list stable; primary pure surface.

**Independent Test**: Golden fixtures mirror `finishGaps.test.ts` (empty, claims without set, covering without fills, full satisfied, live-over-snapshot, mod soft coverage, skippedKeys nextActionable).

**Acceptance Scenarios**:

1. **Given** no attachments and empty equipment, **When** `evaluateFinishGaps` runs, **Then** gaps order is armor → weapon → mod, armor/weapon are `needs_set`, `complete` is false.
2. **Given** armor claims without an armor set attachment, **When** evaluated, **Then** armor status is `capture_available` and `canCapture` is true.
3. **Given** a live armor set attachment and empty armor slots, **When** evaluated, **Then** armor status is `needs_fill` and `emptySlots` lists all required armor slots in product order.
4. **Given** live armor/weapon/mod sets and all armor+weapon slots filled, **When** evaluated, **Then** all gaps are `satisfied`, `complete` is true, `nextActionable` is null.
5. **Given** both snapshot and live armor attachments, **When** evaluated, **Then** covering prefers live.
6. **Given** armor+weapon complete and `hasModCoverage: true` without a mod set, **When** evaluated, **Then** mod is `satisfied` and `complete` is true.
7. **Given** all categories unsatisfied and `skippedKeys: ['armor']`, **When** evaluated, **Then** `nextActionable` is weapon (then falls back if all skipped).

---

### User Story 2 - Default vs non-default gap list stability (Priority: P1)

As an engineer, I can evaluate the same attachments/equipment with `isDefaultVariant: true` and `false` and get identical gap statuses, empty slots, completeness, and nextActionable selection so finish guidance does not diverge by default flag at the pure layer (flag is carried on the result for callers only).

**Why this priority**: Explicit roadmap exit criterion — gap list stable for default vs non-default fixtures.

**Independent Test**: Pair of fixtures with identical attachments/equipment differing only in `isDefaultVariant`; deep-compare gaps and nextActionable category/status.

**Acceptance Scenarios**:

1. **Given** empty kit default and non-default, **When** both are evaluated, **Then** gap categories/statuses/`emptySlots`/`complete` match; only `isDefaultVariant` on the result differs.
2. **Given** partial capture_available armor + unsatisfied weapon, **When** both default flags are evaluated, **Then** gap list and `nextActionable` match.
3. **Given** fully satisfied kit, **When** both flags are evaluated, **Then** both report `complete: true` and null nextActionable.

---

### User Story 3 - Next-slot / post-mutation walkthrough helpers (Priority: P1)

As an engineer, I can resolve the next walkthrough step and fill slot from a `FinishGap` so successive fills shrink empty slots in required order, armor live covering can open optimizer, and snapshot covering stays on category.

**Why this priority**: Roadmap “next-slot pure helpers”; pairs with gap evaluation for finish UX later.

**Independent Test**: Golden fixtures mirror `finishNextSlot.test.ts`.

**Acceptance Scenarios**:

1. **Given** weapon needs_fill with empty primary/special/heavy, **When** `firstEmptyRequiredSlot` / `resolvePostMutationStep` run, **Then** fill targets primary then successive empties.
2. **Given** armor needs_fill with live covering, **When** resolved with default preferArmorOptimize, **Then** step is `armor_optimize`.
3. **Given** same armor gap with preferArmorOptimize false, **When** resolved, **Then** step is `fill` at first empty armor slot.
4. **Given** snapshot covering needs_fill, **When** resolved, **Then** step is `category` (no auto fill).
5. **Given** needs_set / capture_available, **When** resolved, **Then** step is `category`; `showFinishCreateActions` is true only for those statuses.
6. **Given** null or satisfied gap, **When** resolved, **Then** step is `overview`.

---

### Edge Cases

- Mod category never `canCapture` (create-from-build skips mod snapshot) — always false; status only `satisfied` or `needs_set`.
- Invalid / zero / missing itemHash does not count as a filled slot.
- Pair/fashion set attachments do not cover armor/weapon/mod categories.
- Soft coverage never auto-applies; `hasModCoverage` is an explicit caller input, not inferred soft evaluation here.
- Domain package remains zero IO/UI runtime dependencies.
- Slot wire names use product strings (`class_item`, not UI shorthand `class`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure `evaluateFinishGaps` accepting variantId, isDefaultVariant, attachments, equipment map, optional hasModCoverage and skippedKeys.
- **FR-002**: Gap categories MUST be evaluated in fixed order armor → weapon → mod.
- **FR-003**: Covering set for a category MUST prefer live attachment of that set type over snapshot.
- **FR-004**: Armor/weapon required slots MUST match `EquipmentSlot.armorSlots` / `weaponSlots` wire names.
- **FR-005**: Status rules MUST match TS: covering+full → satisfied; covering+empty → needs_fill; no covering + claims → capture_available; else needs_set (mod: set or hasModCoverage → satisfied, else needs_set; canCapture false).
- **FR-006**: `complete` MUST be true only when every gap status is satisfied.
- **FR-007**: `nextActionable` MUST prefer first unsatisfied category not in skippedKeys, else first unsatisfied, else null.
- **FR-008**: Domain MUST export pure next-slot helpers: `firstEmptyRequiredSlot`, `resolvePostMutationStep`, `shouldOpenArmorOptimize`, `showFinishCreateActions`, `finishCategoryToSetType` (and related result types).
- **FR-009**: Golden unit tests MUST cover finishGaps parity cases + default vs non-default stability + finishNextSlot parity cases.
- **FR-010**: Domain package runtime dependencies MUST remain zero IO/UI.

### Key Entities

- **FinishCategory / FinishGapStatus / FinishGap / FinishGapsResult**: pure result shapes (new this slice).
- **FinishAttachmentInput / FinishEquipmentClaim / EvaluateFinishGapsInput**: pure inputs.
- **FinishWalkthroughStep / FinishPostMutationTarget**: pure next-step navigation DTOs.
- **SetType / AttachmentMode / EquipmentSlot**: reused from DART-002.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` includes finish-gaps suite green with parity scenarios above.
- **SC-002**: Default vs non-default fixtures produce identical gap lists (statuses, emptySlots, complete, nextActionable category).
- **SC-003**: Category order and status wire names match TS (`needs_set`, `needs_fill`, `capture_available`, `satisfied`).
- **SC-004**: Domain `pubspec.yaml` runtime deps remain empty (SDK only).
- **SC-005**: Roadmap row DART-007 marked done after merge to `feature/multiplatform-dart`.

## Assumptions

- Pure layer does not load DB or build detail; callers map attachments/equipment into finish input DTOs (TS `finishGapsFromDetail` adapter stays out of domain or is thin pure mapping only if useful without IO types).
- `isDefaultVariant` is echoed on the result for UI/context; it does not change gap math (product completeness differs in resolveVariant; finish gaps are set/fill coverage).
- Armor live → optimizer preference defaults to true (product 031 behavior) and is overridable for tests/UI.
- Soft guidance never auto-applies; hard DBR blocks are out of this module.
- No NEEDS CLARIFICATION retained; defaults above match TS source of truth.
