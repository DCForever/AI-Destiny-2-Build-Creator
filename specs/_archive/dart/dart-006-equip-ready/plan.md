# Implementation Plan: DART-006 Equip Ready

**Branch**: `dart-006-equip-ready` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-006-equip-ready/spec.md`

## Summary

Port pure equipReady / wishlist vs owned-pin gates into `packages/domain` with golden parity against TypeScript `src/lib/builds/equipReady.ts`. Wishlist cannot be equip-ready; stale pins (missing instance, hash mismatch) and post-sync re-evaluation are covered by unit tests. No inventory DB, equip execution, or DIM payload.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace uses 3.11.x)  
**Primary Dependencies**: None at runtime (pure domain package)  
**Storage**: N/A  
**Testing**: `package:test` via `dart test packages/domain`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package (`packages/domain`)  
**Performance Goals**: Negligible; pure in-memory  
**Constraints**: Zero IO/UI deps; pure Dart only; no Node sidecar; soft guidance not in scope  
**Scale/Scope**: One evaluator module + one test file

## Constitution Check

- I. Small Testable Increments: US1 wishlist, US2 owned pins, US3 stale/post-sync — each independently testable.
- II. Test-First: Golden tests with implementation; suite green before finish merge.
- III. Green Commit Checkpoints: Domain tests + analyze green before merge to base.
- IV-V. Co-located tests under `packages/domain/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-006-equip-ready/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/domain/
├── lib/
│   ├── destiny2_domain.dart
│   └── src/
│       ├── models/                    # DART-002 (reuse pin + resolve shapes)
│       └── evaluators/
│           ├── ...
│           └── equip_ready.dart       # NEW
└── test/
    └── equip_ready_test.dart          # NEW
```

## Implementation approach

1. Add `EquipReadyException` with `code`, `message`, optional `details`.
2. Port `buildInventoryPinIndex` (list → Map).
3. Port per-claim `statusForClaim` logic and `computeEquipReady` over `EquipmentSlot.combatSlots`.
4. Port `assertEquipReady` using `DomainFailureCodes.notEquipReady`.
5. Golden tests from `equipReady.test.ts` plus explicit `hash_mismatch` case.
6. Export from library barrel; update package description; keep pubspec free of IO/UI.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Confusing completeness with equip-ready | Completeness is DART-005; this slice is ownership pins only |
| Inventory IO leaking into domain | Accept only pure map/list of ids+hashes |
| ApiError coupling | Domain exception with same product code |

## Complexity Tracking

None — pure function port with existing models.
