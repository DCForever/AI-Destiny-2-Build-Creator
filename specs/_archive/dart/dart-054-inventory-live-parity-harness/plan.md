# Implementation Plan: DART-054 Inventory Live Parity Harness

**Branch**: `dart-054-inventory-live-parity-harness` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-054-inventory-live-parity-harness/spec.md`

## Summary

Ship an offline **Next-vs-Dart inventory fidelity harness**: documented dual-run procedure, pure-Dart snapshot compare library/CLI, fixture-based **inventory fidelity gate** separate from `p0_parity_gate`, and cutover/gaps updates so RC-SYNC cites fidelity metrics, GAP-INV-05/PROC-03 close, and RB-06 clears with DART-050–054 evidence.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace root `tool/` scripts)  
**Primary Dependencies**: `dart:convert`, `dart:io`, package `test` for unit tests; no Flutter/Jaspr/Drift/http required for gate  
**Storage**: N/A (JSON fixtures on disk only)  
**Testing**: `dart test tool/test/inventory_fidelity_*.dart` + `dart run tool/inventory_fidelity_gate.dart`  
**Target Platform**: Operator workstation + CI (offline)  
**Project Type**: Repo tool + docs (not a host UI feature)  
**Performance Goals**: Compare thousands of bucket keys in <1s  
**Constraints**: No CLIENT_SECRET; no live Bungie in CI; soft never auto-applies; pure Dart only  
**Scale/Scope**: One doc, one compare library, one gate CLI, fixtures, cutover/gaps edits

## Constitution Check

- I. Small Testable Increments: Dual-run doc → compare lib → gate → cutover/gaps; each independently testable.
- II. Test-First: Compare unit tests + gate tests written with fixtures; implement until green.
- III. Green Commit Checkpoints: Commit when tool tests + gate + cutover validator green.
- IV-V. Co-located tool tests under `tool/test/`; validation-first CLI exit codes.

## Project Structure

### Documentation (this feature)

```text
specs/dart-054-inventory-live-parity-harness/
├── plan.md
├── research.md
├── quickstart.md
├── spec.md
├── tasks.md
└── checklists/requirements.md

docs/multiplatform-dart-inventory-live-parity-harness.md
docs/multiplatform-dart-cutover-parity-checklist.md   # RC-SYNC / RB-06
docs/multiplatform-dart-feature-gaps.md               # GAP-INV-05, PROC-*
docs/multiplatform-dart-slice-roadmap.md              # finish-spec
```

### Source Code

```text
tool/
├── inventory_fidelity/
│   ├── snapshot.dart    # parse/serialize InventoryFidelitySnapshot
│   ├── compare.dart     # compare + tolerance + diffs
│   └── markers.dart     # procedure-doc required markers for gate
├── inventory_fidelity_compare.dart   # CLI: --next --dart [--tolerance]
├── inventory_fidelity_gate.dart      # offline CI/operator gate
├── fixtures/inventory_fidelity/
│   ├── next_match.json
│   └── dart_match.json
└── test/
    ├── inventory_fidelity_compare_test.dart
    └── inventory_fidelity_gate_test.dart
```

## Implementation approach

1. **Snapshot model** — Map Next/Dart diagnostics JSON shape (membership, raw, parsed.byLocation/byBucket, dropped, resolution) into a single schema; lenient parse for optional maps.
2. **Compare** — Diff scalars and map keys; membership identity check; absolute tolerance per field (default 0).
3. **CLI** — `dart run tool/inventory_fidelity_compare.dart --next path --dart path [--tolerance 0]`.
4. **Gate** — Read harness doc for required markers; compare fixture pair; exit 0/1. Does **not** call `p0_parity_gate`.
5. **Docs** — Dual-run procedure + schema + gate policy; update cutover/gaps/roadmap.
6. **Tests** — Match/mismatch/membership/malformed/gate markers.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| None | — | — |
