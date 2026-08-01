# Implementation Plan: DART-061 Production Cutover Re-Gate

**Branch**: `dart-061-production-cutover-regate` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-061-production-cutover-regate/spec.md`

## Summary

Formal production cutover re-gate: confirm all **RC-*** are **PASS**, set **`PRODUCTION_CUTOVER: GO`** with date/rationale, set **RC-BRANCH PASS** (merge `feature/multiplatform-dart` toward production/`main` only after GO), close **GAP-CUT-01**, keep **GAP-FEAT-02** non-goal (jsonOnly sufficient), and ship an offline re-gate tool. Soft never auto-applies; no CLIENT_SECRET. Finish-spec still merges only to `feature/multiplatform-dart`.

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: Pure Dart tool scripts (mirror DART-049/060 gates); existing cutover checklist + dual-run + fidelity + secret scan  

**Storage**: N/A (docs + offline gate only)  

**Testing**: `dart test tool/test/production_cutover_regate_test.dart`; `dart run tool/production_cutover_regate.dart`; cutover checklist validator; client secret scan  

**Target Platform**: Ops/docs + CI gate  

**Project Type**: Production readiness re-gate (P8 final slice)  

**Performance Goals**: Gate < few seconds offline  

**Constraints**: Pure Dart I/O tools; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; do not merge to main in finish-spec  

**Scale/Scope**: Checklist + branching policy + gaps/roadmap + offline re-gate; no new product UI

## Constitution Check

- I. Small Testable Increments: US1 RC re-walk → US2 GO verdict → US3 branch policy.
- II. Test-First: re-gate unit tests with marker fixtures.
- III. Green Commit Checkpoints: re-gate + cutover validator + secret scan green before merge.
- Soft never auto-applies; no secrets.

## Project Structure

### Documentation (this feature)

```text
specs/dart-061-production-cutover-regate/
├── plan.md
├── research.md
├── quickstart.md
├── spec.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code / docs

```text
tool/production_cutover/markers.dart              # NEW marker constants
tool/production_cutover_regate.dart                # NEW offline re-gate CLI
tool/test/production_cutover_regate_test.dart      # NEW
docs/multiplatform-dart-cutover-parity-checklist.md  # GO + RC-BRANCH PASS
docs/multiplatform-dart-branching.md                 # merge-after-GO policy
docs/multiplatform-dart-feature-gaps.md              # GAP-CUT-01 closed
docs/multiplatform-dart-slice-roadmap.md             # DART-061 done
docs/multiplatform-dart-port-decisions.md            # cutover open item closed
```

## Implementation approach

1. **Markers + re-gate** — require PRODUCTION_CUTOVER GO, PROGRAM_GATE GO, each RC-* PASS, RC-BRANCH merge-after-GO policy, GAP-CUT-01 closed, GAP-FEAT-02 non-goal, soft/secrets non-regression markers.
2. **Checklist** — flip PRODUCTION_CUTOVER to GO with date/rationale; RC-BRANCH PASS; residual blockers section notes formal GO; keep dim.gg N/A.
3. **Branching** — explicit RC-BRANCH / PRODUCTION_CUTOVER_GO merge policy section.
4. **Gaps / roadmap / decisions** — close GAP-CUT-01; FEAT-OPS-CUTOVER shipped; DART-061 done; pointer to program complete.
5. **Tests** — unit tests for missing markers + workspace green; run secret scan + cutover structural validator.

## Complexity Tracking

None — ops + gate pattern mirrors DART-060 / DART-054 / DART-049.
