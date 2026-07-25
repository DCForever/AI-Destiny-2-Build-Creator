# Implementation Plan: DART-001 Domain Foundation

**Branch**: `dart-001-domain-foundation` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-001-domain-foundation/spec.md`

## Summary

Stand up a Melos-managed Dart monorepo skeleton beside the existing Next.js tree: workspace root config, a pure smoke `destiny2_domain` package with a unit test, documented layout, and a single CI-friendly test entry. No Flutter/Jaspr apps and no domain evaluator logic.

## Technical Context

**Language/Version**: Dart SDK ≥ 3.5 (stable 3.11 available on implementer machine)

**Primary Dependencies**: Melos (dev orchestration); `package:test` for domain smoke tests only

**Storage**: N/A

**Testing**: `dart test` via Melos script `test`

**Target Platform**: Pure Dart VM (no device/UI)

**Project Type**: Multi-package library monorepo skeleton

**Performance Goals**: Bootstrap + smoke tests complete quickly locally/CI (<60s)

**Constraints**: Domain package: zero IO/UI runtime deps; no Flutter/Jaspr apps this slice; pure Dart I/O only (future slices); no Node sidecar

**Scale/Scope**: One workspace root + one package (`packages/domain`); docs only for layout

## Constitution Check

- I. Small Testable Increments: Single vertical slice (skeleton) independently testable via smoke test.
- II. Test-First: Smoke test lands with package shell; proves load + trivial pure export.
- III. Green Commit Checkpoints: Commit only after `dart pub get` + test entry green.
- IV-V. Co-located tests under `packages/domain/test/`; validation via pubspec purity.

No constitution violations requiring complexity tracking.

## Project Structure

### Documentation (this feature)

```text
specs/dart-001-domain-foundation/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
pubspec.yaml                 # workspace root + Melos 7+ `melos:` scripts
melos.yaml                   # pointer only (Melos 7+ obsolete full config file)
analysis_options.yaml        # shared analyzer defaults (optional thin)
packages/
  README.md                  # documented layout + purity rules
  domain/
    pubspec.yaml             # pure SDK + dev_dependency test only
    lib/
      destiny2_domain.dart   # barrel export
      src/
        smoke.dart           # trivial pure symbol for smoke test
    test/
      smoke_test.dart
```

**Structure Decision**: Root-level Melos 7+ (config in `pubspec.yaml`) + Dart pub workspace coexisting with Next.js. Packages live under `packages/`. Domain package directory is `packages/domain` with pub name `destiny2_domain`.

## Complexity Tracking

> None
