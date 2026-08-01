# Research: DART-004 Soft Coverage

**Date**: 2026-07-24

## Source modules (TypeScript product)

| TS module | Responsibility | Dart target |
| --------- | -------------- | ----------- |
| `src/lib/builds/coverage.ts` | Evidence match, tiers, set-bonus soft, element soft, attach softStats | `evaluators/soft_coverage.dart` |
| `src/lib/builds/statEstimate.ts` | Loadout stat sum + soft warnings | `evaluators/stat_estimate.dart` |
| `src/lib/builds/softStatTargets.ts` | Normalize/merge targets (drop UI draft helpers) | `evaluators/soft_stat_targets.dart` |
| `src/lib/builds/statNudges.ts` | Synergy-type → stat suggestions | `evaluators/stat_nudges.dart` |

## Decisions

### R1 — Soft envelope type

**Decision**: Keep using DART-002 `CoverageResult` / soft rows; do not extend `ConstraintEvaluation` with coverage tiers.

**Rationale**: Hard vs soft confusion is an exit criterion. ConstraintEvaluation is for hard gates (+ rare soft warnings co-located with hard paths like exotic ability pin proposed). Soft coverage is a separate product surface (DBR-GUID-*).

### R2 — Validation without ApiError

**Decision**: `normalizeSoftStatTargets` throws `SoftStatTargetsException` with `code == 'INVALID_ITEM'` and a human message matching TS intent.

**Rationale**: Pure domain cannot depend on Next `ApiError`. Adapters map later.

### R3 — Inventory stats input

**Decision**: `estimateLoadoutStats(claims, Map<String, Map<ArmorStatName, int>> inventoryStatsByInstanceId)` — no inventory entity type.

**Rationale**: Zero IO; caller projects DB/Bungie instance stats into a pure map.

### R4 — Set bonus input

**Decision**: Pure `SetBonusRecord` + `SetBonusPerk` models; `evaluateCoverage` accepts `Map<int, SetBonusRecord>? setBonusByItemHash`.

### R5 — Subclass element extraction

**Decision**: Accept `String? subclassElement` on `CoverageEvalInput` (already-resolved), plus optional `Object? subclass` JSON-like map for parity with TS heuristic (`element` field or substring scan). Prefer explicit `subclassElement` when provided.

**Rationale**: Avoids pulling full subclass entity types; tests pass explicit element.

### R6 — Out of scope keep-outs

- `coverageGapsForSuggest` → later suggest slice / product
- Save import lint (`softSave.coverage.test.ts`) → product TS; Dart save in DART-028
- SoftStat draft UI strings → Flutter slice later

## Parity notes

- Armor slots: helmet, arms, chest, legs, class_item
- Weapon slots for element: primary, special, heavy
- Kinetic weapons skip element soft mismatch
- Prismatic subclass skips element soft mismatch
- Soft-stat max: 200
- Nudge default suggested: 100
- TYPE_TO_STAT keys lowercase: melee, grenade, super, class, ability→Class, weapons/weapon→Weapons, health/survivability→Health
