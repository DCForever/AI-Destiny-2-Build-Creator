# Implementation Plan: DART-011 Domain Parity Gate

**Branch**: `dart-011-domain-parity-gate` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-011-domain-parity-gate/spec.md`

## Summary

Close **P0** with (1) a single non-interactive command that runs the full pure test suite (`destiny2_domain` + `destiny2_sandbox_data`), (2) a package dependency graph guard that fails if pure packages declare IO/UI runtime deps, and (3) Melos/root docs wiring this as the **P0 phase gate** before Drift/storage (DART-012+).

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace 3.11.x)  
**Primary Dependencies**: Existing workspace only; gate tools use `dart:` + optional root `yaml` if needed for pubspec parse  
**Storage**: N/A  
**Testing**: `package:test` for guard unit tests; existing package golden suites aggregated  
**Target Platform**: Pure library monorepo tooling (Windows/CI)  
**Project Type**: Melos/pub workspace tooling slice (no UI apps)  
**Performance Goals**: Full pure suite + guard &lt; 2 minutes  
**Constraints**: Pure Dart I/O only; no Node sidecar; no Flutter/Jaspr in pure packages; soft never auto-applies  
**Scale/Scope**: Small tool scripts + melos script fixes + docs

## Constitution Check

- I. Small Testable Increments: US1 suite entry, US2 graph guard, US3 docs.
- II. Test-First: Guard detection covered by unit test before/with implementation.
- III. Green Commit Checkpoints: Gate command green before merge.
- IV-V. Co-located guard tests under `tool/test/` or workspace test package path documented.

## Project Structure

### Documentation (this feature)

```text
specs/dart-011-domain-parity-gate/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
tool/
  pure_packages.dart          # list of pure package dirs + forbidden dep names
  pure_package_graph_guard.dart  # library: parse pubspec deps, report violations
  p0_parity_gate.dart         # CLI: guard then dart test each pure package
  run_all_pure_tests.dart     # CLI: tests only (melos-friendly)
  test/
    pure_package_graph_guard_test.dart

pubspec.yaml                  # melos scripts: test, graph-guard, p0-gate (non-interactive)
packages/README.md            # P0 gate section
docs/multiplatform-dart-slice-roadmap.md  # finish: status + pointer
```

## Implementation approach

1. Encode pure package paths + forbidden runtime dependency names.
2. Implement pubspec runtime-`dependencies` scanner (minimal YAML section parse without heavy deps if possible).
3. Unit-test: clean empty deps pass; forbidden `http`/`flutter` fail.
4. CLI `p0_parity_gate.dart`: run guard → `dart test` each pure package → aggregate exit code.
5. Fix Melos `test` script to be root-level non-interactive (avoid nested `melos` PATH requirement and package select prompts).
6. Document single command in quickstart + packages README; mark P0 gate.

## Structure Decision

Tools live under repo-root `tool/` (not a new workspace package) so the gate has no package graph of its own and pure packages remain untouched. Melos scripts invoke `dart run tool/….dart` from workspace root.
