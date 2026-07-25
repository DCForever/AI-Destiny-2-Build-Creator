# Dart monorepo packages

**Workstream:** DART (multiplatform port)  
**Integration base:** `feature/multiplatform-dart`  
**Architecture:** [docs/multiplatform-dart-port-decisions.md](../docs/multiplatform-dart-port-decisions.md)

This directory holds **pure and host-shared Dart packages** for the multiplatform Destiny 2 Build Creator port. UI shells (Flutter Windows/mobile, Jaspr web) are **not** created in early P0 slices.

## Layout

```text
pubspec.yaml              # workspace root + Melos 7+ `melos:` scripts
melos.yaml                # pointer only (config lives in pubspec.yaml)
analysis_options.yaml     # shared analyzer defaults
packages/
  README.md               # this file
  domain/                 # pure domain (models + evaluators)
    pubspec.yaml          # package name: destiny2_domain
    lib/
      destiny2_domain.dart
      src/
        smoke.dart
        models/           # DART-002 pure DTOs
        evaluators/       # DART-003+ pure evaluators
    test/
  sandbox_data/           # pure static sandbox tables (DART-009)
    pubspec.yaml          # package name: destiny2_sandbox_data
    lib/
      destiny2_sandbox_data.dart
      src/                # stat benefits, verbs, champions, …
    test/
```

| Package path | Pub name | Role | Allowed deps |
| ------------ | -------- | ---- | ------------ |
| `packages/domain` | `destiny2_domain` | Pure domain library (models DART-002; evaluators DART-003+) | **SDK only** at runtime; `test` / pure lints as dev_dependencies. **No** Flutter, Jaspr, Drift, http, path_provider, or other IO/UI packages. |
| `packages/sandbox_data` | `destiny2_sandbox_data` | Pure static sandbox constants (stat benefits, synergy verbs, exotic ability requirements, archetypes, champion counters, vocabularies) | **SDK only** at runtime. Soft display tables only — never auto-apply / hard-block. |

Future packages (not in early P0) will appear here or under `apps/` when Flutter/Jaspr shells are introduced (DART-019+, DART-042+).

## Sandbox constants (DART-009)

`destiny2_sandbox_data` mirrors product `src/data/**` curated tables. After Destiny sandbox patches, follow [docs/sandbox-data-update-process.md](../docs/sandbox-data-update-process.md).

## Domain models (DART-002)

`destiny2_domain` exports pure immutable DTOs used by evaluators:

- Claims / resolved equipment / pins / equip-ready **shapes**
- Kits (subclass, ability, exotic composition, mod energy pieces)
- Hard/soft constraint envelopes + failure code constants
- Soft coverage result tree + soft stat shapes
- Core build / variant / set / synergy library shapes

## Hard evaluators (DART-003)

Pure functions in `src/evaluators/destiny_build_constraints.dart`:

- `evaluateExoticLimits`, `evaluateModEnergy`, `evaluateSubclassKit`
- `evaluateExoticAbilityMatch`, `evaluateSynergyRequirement`, `mergeConstraintEvaluations`
- Golden tests: `test/hard_constraints_test.dart` (parity with TS vitest)

## DIM builders (DART-010)

Pure variant → DIM Sync loadout document builders (no network):

- Models: `src/models/dim_loadout.dart` (`DimLoadout*`, class/stat hash constants)
- Builders: `src/evaluators/dim_builders.dart` — `buildVariantDimLoadout`, `buildJsonOnlyDimExport` (equipReady gate)
- Golden tests: `test/dim_builders_test.dart` (jsonOnly fixture parity with TS)

## Domain purity rule (hard)

`destiny2_domain` must remain free of I/O and UI frameworks so golden tests and hard/soft evaluators stay portable across Windows, mobile, and Jaspr.

Forbidden in `packages/domain/pubspec.yaml` **dependencies** (runtime):

- `flutter` / Flutter plugins
- Jaspr packages
- Drift / sqflite / sqlite3 (except pure in-memory fakes if ever justified later — prefer none)
- `http`, `dio`, and network clients
- `path_provider` and filesystem path packages used for app storage
- Any package that pulls a Flutter or browser DOM SDK transitively for product logic

Graph guard automation is enforced by **DART-011** (`dart run tool/pure_package_graph_guard.dart` / P0 gate). Review pubspecs in code review as a second line of defense.

## P0 phase gate (DART-011)

Before starting P1 (Drift / StorageRoot), the pure suite must be green and pure packages must stay free of IO/UI runtime deps:

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart run tool/p0_parity_gate.dart
```

Equivalents:

| Command | What it does |
| ------- | ------------ |
| `dart run tool/p0_parity_gate.dart` | **Gate**: graph guard + full pure suite |
| `dart run tool/pure_package_graph_guard.dart` | Dependency lint only |
| `dart run tool/run_all_pure_tests.dart` | All pure package tests only |
| `dart run melos run p0-gate` | Same gate via Melos (no global Melos required) |
| `dart run melos run test` | Full pure suite only |
| `dart run melos run graph-guard` | Graph guard only |
| `dart test tool/test` | Graph guard unit tests |

Pure packages guarded today: `packages/domain`, `packages/sandbox_data`.

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
# Optional Melos on PATH (after: dart pub global activate melos)
# Prefer: dart run melos …
```

## CI-friendly test entry

```powershell
# Preferred — full pure suite (non-interactive)
dart run tool/run_all_pure_tests.dart
# or
dart run melos run test

# Single package
dart test packages/domain
dart test packages/sandbox_data
```

## Coexistence with Next.js

The repository still contains the production Next.js app under `src/` / `package.json`. Dart workspace files at the repo root are additive and must not be required for Node product builds. Ignore Dart tool artifacts via root `.gitignore`.
