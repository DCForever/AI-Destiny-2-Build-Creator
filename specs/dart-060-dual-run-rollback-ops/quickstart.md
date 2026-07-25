# Quickstart: DART-060 Dual-Run + Rollback Ops

## Offline gate (CI / agent)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test tool/test/dual_run_ops_gate_test.dart
dart run tool/dual_run_ops_gate.dart
dart test tool/test/cutover_parity_checklist_validate_test.dart
dart run tool/client_secret_scan.dart
```

## Compose→equip automated re-verify (dual-run window)

```powershell
# Windows host equip / DIM
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter test test/equip_format_test.dart test/equip_panel_test.dart test/dim_export_format_test.dart test/dim_export_panel_test.dart

# Jaspr web equip / DIM (from web_host)
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\web_host
dart test test/equip_format_test.dart test/dim_export_format_test.dart test/dim_export_controller_test.dart test/no_client_secret_equip_test.dart

# Pure equip-ready domain
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain/test/equip_ready_test.dart
```

## Operator dual-run (release window)

See [docs/multiplatform-dart-dual-run-rollback-runbook.md](../../docs/multiplatform-dart-dual-run-rollback-runbook.md).

1. Keep **Next** as sole production.
2. Start Dart Windows + Jaspr for parallel validation.
3. Walk compose→equip re-verify checklist.
4. On problems: **ROLLBACK** = stop Dart dual-use; Next remains sole production.
5. Attach / update **EXECUTION_NOTES**.

## Exit criteria

| Criterion | Evidence |
| --------- | -------- |
| Runbook executed once | EXECUTION_NOTES + EXECUTED_ONCE |
| Compose→equip re-verify | Notes + automated test results |
| Rollback path | ROLLBACK_PROCEDURE = keep Next sole prod |
| RB-04 / RC-OPS | Cutover checklist cleared / PASS |
| Soft / secrets | Advisory + client_secret_scan |
