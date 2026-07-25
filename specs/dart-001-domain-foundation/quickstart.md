# Quickstart: DART-001 Domain Foundation

## Prerequisites

- Dart SDK ≥ 3.5 on PATH (`dart --version`)
- Optional: Melos via `dart pub global activate melos`

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
# Optional: dart pub global activate melos  (ensure Pub\Cache\bin on PATH)
melos bootstrap
```

Melos **7+** stores scripts under root `pubspec.yaml` → `melos:` (not a full `melos.yaml`).

## Test (CI-friendly entry)

```powershell
# Preferred P0 gate (DART-011): graph guard + full pure suite
dart run tool/p0_parity_gate.dart

# Full pure suite only
dart run tool/run_all_pure_tests.dart
# or: dart run melos run test

# Single package
dart test packages/domain
```

## Layout

See [packages/README.md](../../packages/README.md).

## Domain purity rule

`packages/domain` must not take Flutter, Jaspr, Drift, http, or path_provider (or other IO/UI) dependencies.
