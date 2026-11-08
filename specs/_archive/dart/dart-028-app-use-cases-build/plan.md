# Implementation Plan: DART-028 App Use Cases Build

**Branch**: `dart-028-app-use-cases-build` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-028-app-use-cases-build/spec.md`

## Summary

Extend **`destiny2_app`** with **build/variant save pipeline** use cases that enforce hard DBR gates in product order and expose a **soft coverage query** that never blocks save. Orchestrate DART-015 repos + DART-003–005 pure evaluators with injectable ports for manifest-backed inputs. Prove with in-memory Drift tests: illegal kits hard-block; soft misses do not block non-default.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace)  
**Primary Dependencies**: `destiny2_db`, `destiny2_domain`, `destiny2_sandbox_data` (exotic ability table), `test`  
**Storage**: SQLite via `AppDatabase` (memory for tests)  
**Testing**: `dart test packages/app`  
**Target Platform**: Pure Dart application package (Flutter/Jaspr hosts later)  
**Project Type**: Workspace application-layer library (P3)  
**Performance Goals**: Full package suite &lt; 30s  
**Constraints**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; hard blocks stay hard  
**Scale/Scope**: ~4 new modules + ports + mappers + tests in existing `packages/app`

## Constitution Check

- I. Small Testable Increments: US1 build identity, US2 variant gates, US3 soft coverage.
- II. Test-First: co-land tests; green before merge.
- III. Green Commit Checkpoints: `dart test packages/app`.
- IV-V. Co-located tests under `packages/app/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-028-app-use-cases-build/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/app/
  pubspec.yaml                         # + destiny2_sandbox_data
  lib/
    destiny2_app.dart                  # export new modules
    src/
      hard_gate_ports.dart             # injectable ports + defaults
      hard_gates.dart                  # assert identity + variant save
      build_use_cases.dart             # create/list/get/update/delete build
      variant_use_cases.dart           # variant CRUD + validate + expand
      coverage_use_cases.dart          # soft coverage query only
      mappers.dart                     # + build/variant/subclass mapping
      errors.dart                      # + hard-gate error codes
  test/
    build_use_cases_test.dart
    variant_use_cases_test.dart
    coverage_use_cases_test.dart
```

## Implementation approach

1. Extend `UseCaseErrorCode` with hard-gate codes aligned to `DomainFailureCodes` wires.
2. Add `HardGatePorts` (fragment capacity, ability requirements, exotic composition, mod energy pieces, exotic slots).
3. Implement `assertBuildIdentityHardGates` and `assertVariantSaveHardGates` wrapping pure domain evaluators.
4. Build use cases: create (empty default variant + optional attachments with R2 rollback), update, list, get detail, delete.
5. Variant use cases: expand attachments → claims, validate save order, update with R1 rollback.
6. Coverage use case: load claims + designated synergies → `evaluateCoverage`; never throw for soft tiers.
7. Tests for US1–US3; run `dart test packages/app`.
8. Update packages README note; merge to `feature/multiplatform-dart`.

## Structure Decision

Keep orchestration in **`destiny2_app`**. Do **not** pull Drift into domain. Do **not** depend on `destiny2_manifest` for this slice — inject ports so Windows host can wire entity cache later without coupling tests.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Injectable ports vs always calling manifest | Tests + pure default path without entity cache | Would force app→manifest dependency and fixture stores for every unit test |
