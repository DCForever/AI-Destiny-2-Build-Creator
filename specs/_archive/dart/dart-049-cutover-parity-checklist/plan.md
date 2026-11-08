# Implementation Plan: DART-049 Cutover Parity Checklist

**Branch**: `dart-049-cutover-parity-checklist` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-049-cutover-parity-checklist/spec.md`

## Summary

Close **P5 / program gate** with a written **parity checklist** against PRODUCT production nav (`AppShell` NAV_LINKS) and core compose→equip capabilities across Flutter Windows, Flutter mobile, and Jaspr web. Record **Next retirement criteria** (`RC-*`) and dual **go/no-go** verdicts (program gate vs production cutover). Validate document structure with a small Dart test. No new host features; pure docs + validator.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace) for validator only; Markdown for checklist

**Primary Dependencies**: `test` package (root workspace); file I/O via `dart:io` in validator

**Storage**: N/A (documentation)

**Testing**: `dart test tool/test/cutover_parity_checklist_validate_test.dart` (or root-invoked tool)

**Target Platform**: Repo docs (all contributors); multiplatform hosts referenced by path only

**Project Type**: Documentation + lightweight structural validation

**Performance Goals**: N/A

**Constraints**: Pure Dart I/O only if any tooling; no CLIENT_SECRET; soft never auto-applies remains a cutover non-regression criterion; do not implement later product work; do not delete Next

**Scale/Scope**: One canonical doc, Spec Kit folder, one validator test, roadmap finish; ~12 tasks

## Constitution Check

- I. Small Testable Increments: US1 checklist → US2 verdicts → US3 retirement criteria
- II. Test-First: validator asserts required markers; fails if doc stripped
- III. Green Commit Checkpoints: validator green before merge
- IV–V: Co-located tool test; validate doc before claiming GO

## Project Structure

### Documentation (this feature)

```text
specs/dart-049-cutover-parity-checklist/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
docs/multiplatform-dart-cutover-parity-checklist.md
tool/cutover_parity_checklist_validate.dart
tool/test/cutover_parity_checklist_validate_test.dart
```

### Source Code

```text
# No app/package feature code required.
# Optional pure validator:
tool/cutover_parity_checklist_validate.dart
tool/test/cutover_parity_checklist_validate_test.dart
```

**Structure Decision**: Canonical human checklist lives under `docs/` (same pattern as legacy import + OPFS limits). Validator reads that path from repo root so CI/local runs stay path-stable.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Implementation approach

1. Author checklist from AppShell + host nav evidence (research).
2. Fill capability matrix from completed DART slices (DART-001…048).
3. Write `RC-*` retirement criteria and residual blockers.
4. Set PROGRAM_GATE=GO, PRODUCTION_CUTOVER=NO-GO (honest residual).
5. Implement validator for required headings/markers.
6. Finish-spec: merge to `feature/multiplatform-dart`, mark DART-049 done, close Current pointer.
