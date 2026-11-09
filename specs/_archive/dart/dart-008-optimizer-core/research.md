# Research: DART-008 Optimizer Core

**Date**: 2026-07-24

## Source modules (TypeScript product)

| Module | Path | Role |
| ------ | ---- | ---- |
| Types | `src/lib/optimizer/types.ts` | CandidatePiece, ARMOR_OPTIMIZER_SLOTS, SetBonusCoverageGoal |
| Constraints | `src/lib/optimizer/constraints.ts` | isKitValid, exotic/set-bonus |
| Enumerate | `src/lib/optimizer/enumerate.ts` | DFS Cartesian, DEFAULT_MAX_COMBINATIONS=250_000 |
| Prune | `src/lib/optimizer/prune.ts` | DEFAULT_PRUNE_K=16, top-K + retain |
| Score | `src/lib/optimizer/score.ts` | estimate/compare/soft thresholds |

## Decisions

### R1 — Include constraints in this slice

**Decision**: Port `constraints.ts` helpers with enumerate.  
**Rationale**: `enumerateKits` calls `isKitValid`; without constraints the core is incomplete. Full pipeline (`optimizeArmor.ts`) remains later.  
**Alternatives**: Thin stub always-true validity — rejected (breaks locked exotic / set-bonus tests).

### R2 — Soft thresholds stay in score only

**Decision**: `meetsSoftThresholds` is score-side; not used by `isKitValid`.  
**Rationale**: Domain soft guidance never hard-blocks; product TS separates requireThresholds filtering at orchestration layer (out of scope).

### R3 — Models live in domain models/, functions in evaluators/

**Decision**: Follow prior DART slices (models vs evaluators).  
**Rationale**: Consistency with DART-002–007 package layout.

### R4 — No isolate

**Decision**: Synchronous pure functions only.  
**Rationale**: Roadmap assigns isolates to DART-035.

## Truncation semantics (parity)

From `enumerate.ts`:

1. Before evaluating a complete kit, if `evaluated >= max` → set `truncated=true` and return.
2. Else increment `evaluated`, then validate/push kit.
3. DFS aborts early when truncated.

Test expectation: with `maxCombinations: 10`, `truncated === true` and `evaluatedCount <= 11`.

## Reuse of existing domain types

- `EquipmentSlot.armorSlots` ≡ `ARMOR_OPTIMIZER_SLOTS`
- `ArmorStatName.all` ≡ `ARMOR_STAT_NAMES`
