# Feature Specification: DART-008 Optimizer Core

**Feature Branch**: `dart-008-optimizer-core`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port enumerate/prune/score pure core + maxCombinations. Unit tests on small fixture boards; truncation flags; no Flutter isolate yet."

**Program ID**: DART-008  
**Phase**: P0  
**Depends**: DART-002 (models / armor slots / ArmorStatName)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** pure armor-optimizer core in `packages/domain` that mirrors TypeScript:

- `src/lib/optimizer/types.ts` — `CandidatePiece`, `ArmorSlot` / `ARMOR_OPTIMIZER_SLOTS`, `SetBonusCoverageGoal`, reuse refs (minimal shapes)
- `src/lib/optimizer/constraints.ts` — `KitConstraints`, `isKitValid`, exotic/set-bonus kit checks, set-bonus summary helpers
- `src/lib/optimizer/enumerate.ts` — `groupBySlot`, `enumerateKits`, `DEFAULT_MAX_COMBINATIONS`, truncation / `evaluatedCount`
- `src/lib/optimizer/prune.ts` — `DEFAULT_PRUNE_K`, `prunePiecesForSlot`, `prunePiecesBySlot`
- `src/lib/optimizer/score.ts` — `estimateKitStats`, `sumPrioritizedStats`, `sumAllStats`, `compareCombinations`, `meetsSoftThresholds`, `isEstimateIncomplete`

**Out of scope (later slices):** inventory loading (`loadArmorCandidates`), full `optimizeArmor` pipeline / DTO materialize, auto stat mods, empty-reason explainers, Flutter isolate (DART-035), optimizer UI (DART-036), soft auto-apply, Node sidecar, IO.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enumerate kits with hard constraints + truncation (Priority: P1)

As a multiplatform domain engineer, I can enumerate complete five-slot armor kits from per-slot candidate boards, enforce hard kit constraints (≤1 exotic, optional locked exotic, requireExotic, set-bonus goals), and observe `evaluatedCount` / `truncated` when `maxCombinations` is hit so the pure core matches product TS before any isolate work.

**Why this priority**: Roadmap exit criterion — enumerate core + maxCombinations + truncation flags.

**Independent Test**: Small fixture boards mirroring `enumerate.test.ts` and hard-constraint cases from `constraints.test.ts`.

**Acceptance Scenarios**:

1. **Given** any armor slot has zero candidates, **When** `enumerateKits` runs, **Then** kits is empty, evaluatedCount is 0, truncated is false.
2. **Given** one piece per slot, **When** enumerated, **Then** exactly one kit of length 5 is returned.
3. **Given** multiple exotics across slots, **When** enumerated, **Then** no emitted kit has more than one exotic piece.
4. **Given** lockedExoticItemHash + setBonusGoals, **When** enumerated, **Then** every kit includes the locked hash and meets set-bonus min pieces.
5. **Given** a large Cartesian board and `maxCombinations: 10`, **When** enumerated, **Then** truncated is true and evaluatedCount ≤ 11.

---

### User Story 2 - Prune per-slot candidate boards (Priority: P1)

As an engineer, I can prune each slot to top-K by prioritized stats while always retaining locked exotic copies and set-bonus family pieces so enumeration stays within budget without dropping required candidates.

**Why this priority**: Roadmap “prune” pure core; pairs with enumerate for real boards later.

**Independent Test**: Fixtures mirroring `prune.test.ts`.

**Acceptance Scenarios**:

1. **Given** more than K pieces in a slot, **When** pruned with k=4 and Melee priority, **Then** exactly 4 pieces remain and the highest Melee values are kept.
2. **Given** k=1 and a low-stat locked exotic, **When** pruned, **Then** the locked exotic instance is still retained.
3. **Given** k=1 and a set-bonus goal family piece with low stats, **When** pruned, **Then** that family piece is retained (top-K within family).

---

### User Story 3 - Score and rank combinations (Priority: P1)

As an engineer, I can estimate kit stats, compare combinations by priority then total then reuse, evaluate soft thresholds without hard-blocking, and flag incomplete estimates so ranking matches TS.

**Why this priority**: Roadmap “score” pure core; soft thresholds remain soft.

**Independent Test**: Fixtures mirroring `score.test.ts`.

**Acceptance Scenarios**:

1. **Given** pieces with partial stat maps, **When** `estimateKitStats` runs, **Then** each Armor 3.0 stat is summed across pieces.
2. **Given** priorities vs empty priorities, **When** `sumPrioritizedStats` runs, **Then** priorities sum only listed stats; empty falls back to all six.
3. **Given** two rankable combos, **When** `compareCombinations` runs, **Then** order is lexicographic by priorities, then total stats, then reuse only if preferReuse.
4. **Given** soft thresholds, **When** `meetsSoftThresholds` runs, **Then** missing threshold keys are ignored; unmet numeric targets return false; undefined thresholds return true.
5. **Given** a piece missing any of the six stats, **When** `isEstimateIncomplete` runs, **Then** true; complete six-stat kits return false.

---

### Edge Cases

- Soft thresholds never reject kits at enumerate time (hard constraints only); soft is score/rank side.
- Early exotic pruning during DFS (`nextExotics > 1`) must not emit dual-exotic kits even before `isKitValid`.
- Truncation stops further evaluation; kits collected so far are returned as best-so-far candidates (no ranking required in this slice).
- Domain package remains zero IO/UI runtime dependencies.
- No Flutter isolate / compute isolation in this slice.
- Slot wire names match product (`class_item`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Domain MUST export pure optimizer candidate/kit types (`CandidatePiece`, set-bonus goals, kit constraints, enumerate/prune options and results).
- **FR-002**: Domain MUST export `groupBySlot` and `enumerateKits` with default max combinations matching TS (`250_000`).
- **FR-003**: `enumerateKits` MUST return `{ kits, evaluatedCount, truncated }` and set truncated when evaluation budget is exhausted.
- **FR-004**: Hard kit validity MUST enforce complete 5 distinct armor slots, ≤1 exotic, optional requireExotic, locked exotic hash, and set-bonus goals.
- **FR-005**: Domain MUST export `prunePiecesForSlot` / `prunePiecesBySlot` with default K=16, retaining top-K, locked exotic, and set-bonus families.
- **FR-006**: Domain MUST export score helpers: estimate, sum prioritized/all, compare, soft thresholds, incomplete estimate.
- **FR-007**: Soft threshold helpers MUST NOT be treated as hard blocks in enumerate validity.
- **FR-008**: Golden unit tests MUST cover small fixture boards for enumerate (incl. truncation), prune, score, and kit constraints.
- **FR-009**: Domain package runtime dependencies MUST remain zero IO/UI; no Flutter isolate APIs.

### Key Entities

- **CandidatePiece**: owned armor instance for search (slot, itemHash, instanceId, isExotic, setBonusKey, statValues, energyCapacity, usedInSets).
- **KitConstraints**: hard filters for enumeration validity.
- **SetBonusCoverageGoal**: setBonusKey + minPieces (2 or 4).
- **EnumerateResult**: kits + evaluatedCount + truncated.
- **RankableCombination**: estimatedStats + reusePieceCount for compare.
- **ArmorStatName / EquipmentSlot.armorSlots**: reused from DART-002.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/domain` includes optimizer-core suite green with enumerate/prune/score/constraints scenarios above.
- **SC-002**: Truncation fixture sets `truncated: true` with evaluatedCount bounded by maxCombinations (+1 guard as in TS tests).
- **SC-003**: No Flutter / isolate imports in domain package; pubspec runtime deps still empty.
- **SC-004**: Dual-exotic kits never appear in enumerate output for multi-exotic boards.

## Assumptions

- Constraints helpers (`isKitValid` et al.) are part of “enumerate pure core” because enumerate depends on them; full optimizeArmor orchestration stays out of scope.
- Ranking/top-N of enumerated kits after score is not required this slice (score compare APIs only); materialize/DTO is later.
- `energyCapacity` / `usedInSets` are carried on CandidatePiece for later slices but not consumed by prune/enumerate/score except reusePieceCount on RankableCombination.
- Armor slot order is `EquipmentSlot.armorSlots` wire names (helmet → arms → chest → legs → class_item).
