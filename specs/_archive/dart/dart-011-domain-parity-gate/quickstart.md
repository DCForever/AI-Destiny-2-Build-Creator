# Quickstart: DART-011 Domain Parity Gate (P0)

## Prerequisites

- Dart SDK ≥ 3.5 (`dart --version`)
- From multiplatform worktree root:
  `F:\Destiny2BuildCreator-multiplatform-dart`

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
```

Global Melos is **optional**. Prefer `dart run melos …` if using Melos scripts.

## P0 phase gate (single command)

Runs **pure package graph guard** then **full pure test suite** (`domain` + `sandbox_data`):

```powershell
dart run tool/p0_parity_gate.dart
```

Melos equivalent (non-interactive):

```powershell
dart run melos run p0-gate
```

Exit code **0** = P0 pure domain gate green. Non-zero = do not start P1 (Drift/storage) until fixed.

## Pieces

| Command | Purpose |
| ------- | ------- |
| `dart run tool/p0_parity_gate.dart` | **Gate**: graph guard + all pure tests |
| `dart run tool/pure_package_graph_guard.dart` | Dependency lint only |
| `dart run tool/run_all_pure_tests.dart` | All pure package tests only |
| `dart run melos run test` | Same as run_all_pure_tests (Melos script) |
| `dart run melos run graph-guard` | Same as pure_package_graph_guard |
| `dart test tool/test` | Graph guard unit tests |

## Manual package tests (debug)

```powershell
dart test packages/domain
dart test packages/sandbox_data
```

## Pure packages (guarded)

- `packages/domain` → `destiny2_domain`
- `packages/sandbox_data` → `destiny2_sandbox_data`

These must keep **zero IO/UI runtime dependencies** (no Flutter, Jaspr, Drift, http, path_provider, …).

## After this gate

Next slice: **DART-012** `storage-root` (P1). Do not open Drift schema work until this gate is green on `feature/multiplatform-dart`.
