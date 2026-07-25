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
  domain/                 # pure domain (smoke + models; evaluators later)
    pubspec.yaml          # package name: destiny2_domain
    lib/
      destiny2_domain.dart
      src/
        smoke.dart
        models/           # DART-002 pure DTOs
    test/
```

| Package path | Pub name | Role | Allowed deps |
| ------------ | -------- | ---- | ------------ |
| `packages/domain` | `destiny2_domain` | Pure domain library (models DART-002; evaluators DART-003+) | **SDK only** at runtime; `test` / pure lints as dev_dependencies. **No** Flutter, Jaspr, Drift, http, path_provider, or other IO/UI packages. |

Future packages (not in early P0) will appear here or under `apps/` when Flutter/Jaspr shells are introduced (DART-019+, DART-042+).

## Domain models (DART-002)

`destiny2_domain` exports pure immutable DTOs used by later evaluators:

- Claims / resolved equipment / pins / equip-ready **shapes**
- Kits (subclass, ability, exotic composition, mod energy pieces)
- Hard/soft constraint envelopes + failure code constants
- Soft coverage result tree + soft stat shapes
- Core build / variant / set / synergy library shapes

No evaluator algorithms (exotic limits, soft matching, resolve merge) live here yet.

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
