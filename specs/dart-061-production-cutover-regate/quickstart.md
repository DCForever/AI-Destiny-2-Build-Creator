# Quickstart: DART-061 Production Cutover Re-Gate

## Offline re-gate (CI / agent)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test tool/test/production_cutover_regate_test.dart
dart run tool/production_cutover_regate.dart
dart test tool/test/cutover_parity_checklist_validate_test.dart
dart run tool/client_secret_scan.dart
dart run tool/dual_run_ops_gate.dart
dart run tool/inventory_fidelity_gate.dart
```

## Verdict markers (canonical checklist)

File: `docs/multiplatform-dart-cutover-parity-checklist.md`

```text
PROGRAM_GATE: GO
PRODUCTION_CUTOVER: GO
```

Every `RC-*` row Status = **PASS** (including **RC-BRANCH**).

## Branch policy after GO

See `docs/multiplatform-dart-branching.md` section **RC-BRANCH / production merge (after PRODUCTION_CUTOVER GO)**.

- Merge **toward** production/`main` is **allowed only after** `PRODUCTION_CUTOVER: GO`.
- DART slice finish-spec still merges to `feature/multiplatform-dart` only.
- Actual main merge is a human/release step.

## Non-goals that do not block GO

- dim.gg share (GAP-FEAT-02) — jsonOnly sufficient
- `/debug/*`, LLM multi-pass, Flutter Web, Node sidecar

## Exit criteria map

| Criterion | Evidence |
| --------- | -------- |
| All RC-* PASS | Checklist RC table + re-gate |
| PRODUCTION_CUTOVER GO + date/rationale | Verdict block |
| RC-BRANCH merge-after-GO | Branching + checklist |
| GAP-CUT-01 closed | feature-gaps |
| GAP-FEAT-02 non-goal | feature-gaps + re-gate markers |
| Soft / secrets | Advisory + client_secret_scan |
