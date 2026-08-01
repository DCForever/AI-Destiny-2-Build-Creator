# Quickstart: DART-049 Cutover Parity Checklist

## Read the checklist

Open the canonical document:

[`docs/multiplatform-dart-cutover-parity-checklist.md`](../../docs/multiplatform-dart-cutover-parity-checklist.md)

## Validate structure

From the multiplatform worktree root:

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test tool/test/cutover_parity_checklist_validate_test.dart
```

Or run the tool as a script (prints OK / lists missing markers):

```powershell
dart run tool/cutover_parity_checklist_validate.dart
```

## How to re-evaluate production cutover

1. Walk each `RC-*` row in the checklist; attach evidence (test logs, screenshots, Bungie app config).
2. Clear residual blockers only when pass conditions are met.
3. Flip `PRODUCTION_CUTOVER: NO-GO` → `GO` and update **Updated** date + rationale.
4. Do **not** merge to `main` or delete Next without that GO and an explicit ops dual-run plan.
