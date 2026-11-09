# Implementation Plan: DART-060 Dual-Run + Rollback Ops

**Branch**: `dart-060-dual-run-rollback-ops` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-060-dual-run-rollback-ops/spec.md`

## Summary

Ship a written dual-run + rollback runbook, execute it once (dated execution notes + automated compose→equip re-verify), validate with an offline ops gate, attach notes to the cutover checklist, clear **RB-04**, set **RC-OPS PASS**, and close **GAP-OPS-01**. Rollback remains **keep Next sole production**. Soft never auto-applies; no CLIENT_SECRET. **PRODUCTION_CUTOVER** stays **NO-GO** (DART-061).

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: Pure Dart tool scripts (no Flutter runtime required for gate); existing Windows/web host equip/DIM tests  

**Storage**: N/A (docs + offline gate only)  

**Testing**: `dart test tool/test/dual_run_ops_gate_test.dart`; `dart run tool/dual_run_ops_gate.dart`; host equip/DIM re-verify as execution evidence  

**Target Platform**: Ops/docs + CI gate (Windows + Jaspr dual-run targets documented)  

**Project Type**: Ops procedure + offline gate (P8 readiness)  

**Performance Goals**: Gate < few seconds offline  

**Constraints**: No Node sidecar; no CLIENT_SECRET; soft never auto-applies; do not flip PRODUCTION_CUTOVER GO  

**Scale/Scope**: Runbook + gate + cutover/gaps/roadmap updates only; no new product UI

## Constitution Check

- I. Small Testable Increments: US1 runbook → US2 re-verify evidence → US3 rollback + cutover.
- II. Test-First: gate unit tests with marker fixtures before/with gate implementation.
- III. Green Commit Checkpoints: gate + cutover validator green before merge.
- Soft never auto-applies; no secrets.

## Project Structure

### Documentation (this feature)

```text
specs/dart-060-dual-run-rollback-ops/
├── plan.md
├── research.md
├── quickstart.md
├── spec.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code / docs

```text
docs/multiplatform-dart-dual-run-rollback-runbook.md   # NEW runbook + EXECUTION_NOTES
tool/dual_run_ops/markers.dart                         # NEW marker constants
tool/dual_run_ops_gate.dart                            # NEW offline gate CLI
tool/test/dual_run_ops_gate_test.dart                  # NEW
docs/multiplatform-dart-cutover-parity-checklist.md    # RB-04 / RC-OPS / notes link
docs/multiplatform-dart-feature-gaps.md                # GAP-OPS-01 closed
docs/multiplatform-dart-slice-roadmap.md               # DART-060 done → DART-061
```

## Implementation approach

1. **Runbook** — prerequisites, dual-run start, compose→equip re-verify (equip-ready / equip partial / DIM jsonOnly), soft + secrets non-regression, **ROLLBACK_PROCEDURE** (Next sole prod), **EXECUTION_NOTES** (first window).
2. **Gate** — require markers + shell paths (Next `package.json`/`src/app`, `apps/windows_host`, `apps/web_host`) + executed-once notes.
3. **Re-verify** — run Windows/web equip+DIM format/panel tests (and pure equip-ready if quick); record commands/results in EXECUTION_NOTES.
4. **Cutover / gaps** — clear RB-04; RC-OPS PASS; GAP-OPS-01 closed; roadmap next DART-061; PRODUCTION_CUTOVER remains NO-GO.

## Complexity Tracking

None — ops + gate pattern mirrors DART-054 / DART-058.
