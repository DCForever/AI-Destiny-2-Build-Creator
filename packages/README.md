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
  storage/                # StorageRoot paths (DART-012) — not pure
    pubspec.yaml          # package name: destiny2_storage
    lib/
      destiny2_storage.dart
      src/
        storage_root.dart
        version_dir.dart
    test/
  db/                     # Drift schema (DART-013) — not pure
    pubspec.yaml          # package name: destiny2_db
    lib/
      destiny2_db.dart
      src/
        tables.dart
        app_database.dart
        schema_notes.dart
    test/
```

| Package path | Pub name | Role | Allowed deps |
| ------------ | -------- | ---- | ------------ |
| `packages/domain` | `destiny2_domain` | Pure domain library (models DART-002; evaluators DART-003+) | **SDK only** at runtime; `test` / pure lints as dev_dependencies. **No** Flutter, Jaspr, Drift, http, path_provider, or other IO/UI packages. |
| `packages/sandbox_data` | `destiny2_sandbox_data` | Pure static sandbox constants (stat benefits, synergy verbs, exotic ability requirements, archetypes, champion counters, vocabularies) | **SDK only** at runtime. Soft display tables only — never auto-apply / hard-block. |
| `packages/storage` | `destiny2_storage` | **StorageRoot** app-support path layout (DART-012). Not pure — may use `dart:io` for `ensureLayout`. | `path` (+ SDK). Hosts inject path_provider application-support path; package does **not** depend on Flutter/path_provider. **Not** in P0 pure graph guard list. |
| `packages/db` | `destiny2_db` | Drift SQLite **schema + migrations** for core tables (users, inventory, sets, synergies, builds/variants, attachments). schemaVersion 1 create-all (DART-013); ensure* upgrades on open (DART-014). | `drift`, `sqlite3`, `path`. Repos DART-015+. **Not** pure. |

UI shells (Flutter Windows/mobile, Jaspr web) land under `apps/` in later slices (DART-019+, DART-042+).

## StorageRoot (DART-012)

Canonical multiplatform on-disk layout. **Windows Flutter hosts** resolve the base with path_provider, then build `StorageRoot`:

```dart
// Host (Flutter Windows) — path_provider not imported by destiny2_storage
final support = await getApplicationSupportDirectory();
final root = StorageRoot.windowsAppSupport(support.path);
await root.ensureLayout();
// root.appDbPath → <app support>/app.db
```

**Do not** use process CWD or repo `.cache` (Next.js legacy: `src/lib/manifest/cachePaths.ts`).

| Relative path | Purpose |
| ------------- | ------- |
| `app.db` | Primary SQLite (Drift opens later) |
| `current-version.json` | Active manifest version pointer |
| `manifest/<versionDir>/<table>.json` | Raw Bungie tables |
| `entities/<versionDir>/<store>.json` | Derived entity stores |
| `entities/<versionDir>/meta.json` | Entity cache meta |
| `entities/<versionDir>/perk-weapon-index.json` | Perk–weapon index |
| `users/<membershipId>/preferences.json` | Per-user preferences |

`versionDir` = `versionToDirName` (unsafe chars → `_`). Unit tests inject a fake base path (no real AppData required).

## Drift schema + migrations (DART-013 / DART-014)

`destiny2_db` mirrors product `src/lib/db` core tables. Open helpers:

```dart
import 'package:destiny2_db/destiny2_db.dart';

final mem = AppDatabase.memory();
final file = AppDatabase.file(root.appDbPath); // StorageRoot from destiny2_storage
// beforeOpen: foreign_keys ON + applyEnsureUpgrades (product ensure* parity)
```

- **PRAGMA**: `foreign_keys = ON` on open
- **schemaVersion**: **1** = current create-all; see `migration_version_table.dart` + `specs/dart-014-drift-migrations/data-model.md`
- **Ensure upgrades**: idempotent ADD COLUMN / table create / builds rebuild mirroring `src/lib/db/client.ts` (import prep for DART-048)
- **Critical uniques**: `users.bungie_membership_id`; `inventory_items(user_id, instance_id)`; `sets(user_id, type, name)`; tag/synergy-type pairs — see `schema_notes.dart` and `specs/dart-013-drift-schema/data-model.md`
- **RESTRICT**: cannot delete a set while `variant_set_attachments` reference it
- Tests: `dart test packages/db`

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
