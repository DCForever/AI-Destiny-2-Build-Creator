# Implementation Plan: DART-069 Nest Dart/Flutter Workspace Under `flutter/`

**Branch**: `044-nest-flutter-workspace` | **Date**: 2026-08-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-069-nest-flutter-workspace/spec.md`

## Summary

Nest the entire multiplatform Dart workspace (packages, apps including Jaspr web_host, tool, pub/melos config) under monorepo `flutter/`, keep Next.js and specs/docs at repo root, fix workspace-root detection and operational paths, then validate pure/P0 gate + Node smoke.

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter (existing hosts); Node ≥20 for Next.js residual

**Primary Dependencies**: Melos 7+ pub workspace; existing path deps between packages/apps (unchanged relative layout under `flutter/`)

**Storage**: N/A (layout only)

**Testing**: `dart test` pure packages; `dart run tool/p0_parity_gate.dart`; tool unit tests for `findWorkspaceRoot`; `npm run typecheck` or `npm test` at monorepo root

**Target Platform**: Developer workstation (Windows primary); all existing host targets unchanged

**Project Type**: Monorepo restructuring (DX / repo layout)

**Performance Goals**: N/A

**Constraints**: Preserve git history via `git mv`; no pub package renames; single cwd convention `flutter/` for Dart workspace commands; root detection works from monorepo root and `flutter/`

**Scale/Scope**: ~10 packages + 3 apps + tool/; bulk of path string updates in docs/specs is secondary to operational paths

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- I. Small Testable Increments: Stories US1 (tree + run), US2 (gates/root detect), US3 (docs) are independently verifiable.
- II. Test-First (NON-NEGOTIABLE): Extend/add tests for `findWorkspaceRoot` (and any dual-root detection) before changing detection logic; gate runs after move.
- III. Green Commit Checkpoints: After mechanical move + root detect fix, run pure/P0 gate; after IDE/docs, re-run; Node smoke before final checkpoint.
- IV-V. Co-located tool tests under `tool/test/`; no external untrusted data in this slice.

**Post-design**: Still pass. Complexity: one-shot tree move is inherently cross-cutting; justified because split moves would break the pub workspace mid-way.

## Project Structure

### Documentation (this feature)

```text
specs/dart-069-nest-flutter-workspace/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── workspace-layout.md
└── tasks.md
```

### Source Code (repository root after change)

```text
package.json
src/
specs/
docs/
scripts/
.specify/
flutter/
  pubspec.yaml
  pubspec.lock
  melos.yaml
  analysis_options.yaml
  packages/
  apps/
    windows_host/
    mobile_host/
    web_host/
  tool/
.vscode/launch.json
.gitignore
```

**Structure Decision**: Single nested Dart workspace at `flutter/`; monorepo root remains Next.js. Sibling `packages/` + `apps/` under `flutter/` preserves existing relative path deps (`../../packages/...`).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Large single move across many paths | Pub workspace must move atomically | Moving only Flutter hosts leaves pure packages at root and splits Melos |
