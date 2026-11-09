# Implementation Plan: DART-035 Optimizer Isolate

**Branch**: `dart-035-optimizer-isolate` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-035-optimizer-isolate/spec.md`

## Summary

Compose DART-008 pure enumerate/prune/score into an **optimize pipeline** that returns ranked combination DTOs, run that pipeline via **`Isolate.run`** for UI-thread safety, and add **confirm-only** app use cases to **materialize** a new Armor Set (or **apply in place**) only when the host explicitly confirms a combination. Optimize never writes library state.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: `destiny2_domain` (pipeline), `destiny2_db` + `destiny2_app` (materialize), `dart:isolate` (app runner), `test`  
**Storage**: SQLite via `AppDatabase` (memory for materialize tests)  
**Testing**: `dart test packages/domain`, `dart test packages/app`  
**Target Platform**: Pure Dart domain + app packages (Flutter Windows host consumes later in DART-036)  
**Project Type**: Workspace library slices (P4)  
**Performance Goals**: Isolate path usable for boards near prune×enumerate budget without blocking UI isolate  
**Constraints**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; hard piece validation on materialize  
**Scale/Scope**: Domain pipeline + app isolate + materialize/apply use cases; no Flutter UI widgets

## Constitution Check

- I. Small Testable Increments: US1 pipeline, US2 isolate, US3 materialize, US4 apply-in-place.
- II. Test-First: co-land tests; green before merge.
- III. Green Commit Checkpoints: domain + app package tests.
- IV-V. Co-located tests under package `test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-035-optimizer-isolate/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/domain/
  lib/
    destiny2_domain.dart                 # export pipeline + combination types
    src/
      models/optimizer.dart              # + combination / response / request DTOs
      evaluators/
        optimizer_pipeline.dart          # pure prune→enumerate→rank
        optimizer_explain_empty.dart     # empty reason codes
  test/
    optimizer_pipeline_test.dart

packages/app/
  lib/
    destiny2_app.dart                    # export optimizer modules
    src/
      optimizer_isolate.dart             # Isolate.run + local runners
      optimizer_use_cases.dart           # materialize + apply-in-place
      errors.dart                        # + instance not owned / combination invalid codes
  test/
    optimizer_isolate_test.dart
    optimizer_materialize_test.dart
```

## Implementation approach

1. Extend domain optimizer models with combination piece DTO, `ArmorCombination`, request/response, empty reason.
2. Implement pure `optimizeArmorCore` (groupBySlot → prune → enumerate → estimate/score → optional threshold filter → sort → maxResults).
3. Implement `explainEmpty` parity for empty boards.
4. App: serialize request/response maps; `optimizeArmorInIsolate` via `Isolate.run`; `optimizeArmorLocal` for tests.
5. App: `materializeArmorCombination` + `applyArmorCombinationInPlace` using existing set repos; five-slot validation; optional ownership map.
6. Tests for all user stories; confirm-only assertion that optimize does not write sets.
7. Update package exports/README notes; merge to `feature/multiplatform-dart`.

## Structure Decision

- **Pure core stays in `destiny2_domain`** (no `dart:isolate` dependency required in domain).
- **Isolate + DB materialize live in `destiny2_app`** (orchestration layer, matches DART-027/028).
- Do **not** implement Flutter optimizer UI (DART-036).
- Do **not** port auto-stat-mods this slice (A2).

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Map serialization for isolate | Reliable sendable messages | Passing custom class graphs across isolates is brittle |
| Ownership optional port | Tests without inventory | Forcing inventory load couples this slice to DART-024 wiring |

## Research notes

See [research.md](./research.md).
