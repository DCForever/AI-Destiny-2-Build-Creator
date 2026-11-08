# Requirements checklist: DART-008 Optimizer Core

**Feature**: `dart-008-optimizer-core`  
**Updated**: 2026-07-24

## Completeness

- [x] Scope limited to pure enumerate/prune/score + maxCombinations (no isolate, no IO)
- [x] User stories cover enumerate+truncation, prune, score
- [x] Functional requirements FR-001–FR-009 map to exit criteria
- [x] Success criteria are testable via `dart test packages/domain`
- [x] Assumptions documented (constraints included; no top-N materialize)

## Domain alignment

- [x] Soft thresholds remain soft (no auto-apply; not hard enumerate filters)
- [x] Hard exotic limit (≤1) preserved as hard kit validity
- [x] Wire names match product (`class_item`, Armor 3.0 stat names)
- [x] Zero IO/UI in domain package (D-IO)

## Test plan

- [x] Enumerate empty slot / single kit / dual exotic / locked+set bonus / truncation
- [x] Prune top-K / locked exotic / set-bonus family
- [x] Score estimate / priorities / compare / soft thresholds / incomplete
- [x] Constraints completeness / requireExotic / set-bonus summary

## Out of scope verified

- [x] No Flutter isolate (DART-035)
- [x] No loadArmorCandidates / optimizeArmor pipeline
- [x] No Node sidecar
