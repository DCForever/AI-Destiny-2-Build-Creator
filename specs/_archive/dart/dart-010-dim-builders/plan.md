# Implementation Plan: DART-010 DIM Builders

**Branch**: `dart-010-dim-builders` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-010-dim-builders/spec.md`

## Summary

Port pure DIM variant loadout JSON builders into `packages/domain`, plus a jsonOnly export helper that calls existing `assertEquipReady` (DART-006) before returning `{ loadout }`. No network, no dim.gg share, no DB mod collection. Golden tests mirror `buildVariantDimLoadout.test.ts` and prove one fixed-id fixture matches the TS jsonOnly body shape.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace uses 3.11.x)  
**Primary Dependencies**: None at runtime (pure domain package)  
**Storage**: N/A  
**Testing**: `package:test` via `dart test packages/domain`  
**Target Platform**: Pure library (all hosts later)  
**Project Type**: Melos monorepo package (`packages/domain`)  
**Performance Goals**: Negligible; pure in-memory  
**Constraints**: Zero IO/UI deps; pure Dart only; no Node sidecar; soft never auto-applies  
**Scale/Scope**: DIM models + builder module + gate helper + one test file

## Constitution Check

- I. Small Testable Increments: US1 builder golden, US2 gate, US3 constants/sockets — independent.
- II. Test-First: Golden tests land with implementation; suite green before finish merge.
- III. Green Commit Checkpoints: Domain tests + analyze green before merge to base.
- IV-V. Co-located tests under `packages/domain/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-010-dim-builders/
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
│       ├── models/
│       │   └── dim_loadout.dart          # NEW — Dim* types + constants + toJson
│       └── evaluators/
│           └── dim_builders.dart         # NEW — buildVariantDimLoadout + jsonOnly gate
└── test/
    └── dim_builders_test.dart            # NEW
```

## Implementation approach

1. Add pure DIM DTOs + `DIM_CLASS_TYPE` / `DIM_STAT_HASHES` matching TS.
2. Add thin fashion/artifact/subclass input shapes used only by the builder.
3. Port `buildVariantDimLoadout` combat equipped, fashion unequipped, notes, parameters.
4. Port soft-stat constraint sort (descending minStat) and exoticArmorHash from `build_exotic_armor`.
5. Add `buildJsonOnlyDimExport` that `assertEquipReady` then returns envelope with `loadout.toJson()`.
6. Injectable `id` for deterministic goldens.
7. Export from barrel; keep pubspec free of IO/UI.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Random UUID breaks golden | Injectable loadout id in builder |
| collectVariantMods IO creep | Accept `List<int> modHashes` only |
| Confusing sheet builder vs variant builder | Only port variant path for exit; note sheet builder deferred |
| Fashion map key order | Single-piece goldens; document multi-piece order as map values |

## Complexity Tracking

None — pure function port with existing models + thin DIM DTOs.
