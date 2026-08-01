# Quickstart: DART-054 Inventory Live Parity Harness

## Offline fidelity gate (CI / local)

```bash
cd /path/to/Destiny2BuildCreator-multiplatform-dart
dart run tool/inventory_fidelity_gate.dart
dart test tool/test/inventory_fidelity_compare_test.dart tool/test/inventory_fidelity_gate_test.dart
```

## Ad-hoc Next vs Dart compare

1. Capture snapshots per [docs/multiplatform-dart-inventory-live-parity-harness.md](../../docs/multiplatform-dart-inventory-live-parity-harness.md).
2. Run:

```bash
dart run tool/inventory_fidelity_compare.dart --next next.json --dart dart.json
```

## Not this gate

```bash
dart run tool/p0_parity_gate.dart   # pure domain only — PROC-05 separation
```

## Soft / secrets

Soft never auto-applies. No CLIENT_SECRET in fixtures or clients.
