# Dart monorepo packages

**Workstream:** DART (multiplatform port)  
**Integration base:** `feature/multiplatform-dart`  
**Architecture:** [docs/multiplatform-dart-port-decisions.md](../docs/multiplatform-dart-port-decisions.md)

This directory holds **pure and host-shared Dart packages** for the multiplatform Destiny 2 Build Creator port. UI shells (Flutter Windows/mobile, Jaspr web) are **not** created in DART-001.

## Layout

```text
pubspec.yaml              # workspace root + Melos 7+ `melos:` scripts
melos.yaml                # pointer only (config lives in pubspec.yaml)
analysis_options.yaml     # shared analyzer defaults
packages/
  README.md               # this file
  domain/                 # pure domain shell (DART-001 smoke; evaluators later)
    pubspec.yaml          # package name: destiny2_domain
    lib/
    test/
```

| Package path | Pub name | Role | Allowed deps |
| ------------ | -------- | ---- | ------------ |
| `packages/domain` | `destiny2_domain` | Pure domain library (evaluators, models in later slices) | **SDK only** at runtime; `test` / pure lints as dev_dependencies. **No** Flutter, Jaspr, Drift, http, path_provider, or other IO/UI packages. |

Future packages (not in DART-001) will appear here or under `apps/` when Flutter/Jaspr shells are introduced (DART-019+, DART-042+).

## Domain purity rule (hard)

`destiny2_domain` must remain free of I/O and UI frameworks so golden tests and hard/soft evaluators stay portable across Windows, mobile, and Jaspr.

Forbidden in `packages/domain/pubspec.yaml` **dependencies** (runtime):

- `flutter` / Flutter plugins
- Jaspr packages
- Drift / sqflite / sqlite3 (except pure in-memory fakes if ever justified later — prefer none)
- `http`, `dio`, and network clients
- `path_provider` and filesystem path packages used for app storage
- Any package that pulls a Flutter or browser DOM SDK transitively for product logic

Graph guard automation is planned for **DART-011**; until then, review pubspecs in code review.

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
# Optional Melos (after: dart pub global activate melos)
melos bootstrap
```

## CI-friendly test entry

```powershell
# Preferred
melos run test

# Without global Melos
dart test packages/domain
```

## Coexistence with Next.js

The repository still contains the production Next.js app under `src/` / `package.json`. Dart workspace files at the repo root are additive and must not be required for Node product builds. Ignore Dart tool artifacts via root `.gitignore`.
