# Research: DART-060 Dual-Run + Rollback Ops

**Date**: 2026-07-25  
**Branch**: `dart-060-dual-run-rollback-ops`

## Decision 1 — Dual-run means parallel availability, not traffic split

**Decision**: Dual-run = Next remains **sole production** traffic while Dart Windows + Jaspr are **available** for operator compose→equip validation in the same release window.

**Rationale**: Port decisions keep Next production until explicit cutover GO. RC-OPS fails because the procedure was never executed; not because a blue/green proxy is missing.

**Alternatives considered**:

- Proxy traffic split Next/Dart — rejected (no hosting decision; DART-061 cutover owns production flip).
- Dart-only dual-run without Next — rejected (exit criteria require Next + Dart).

## Decision 2 — Rollback = keep Next sole production

**Decision**: Rollback is operational: stop dual-use of Dart shells; leave Next production and Confidential OAuth unchanged. No requirement to delete Dart branches.

**Rationale**: Explicit exit criteria; matches cutover dual-gate model (`PRODUCTION_CUTOVER: NO-GO` until DART-061).

## Decision 3 — Re-verify vs historical slice PASS

**Decision**: Compose→equip must be re-verified **in this dual-run window** via (a) re-running host equip/DIM/equip-ready tests as automated evidence and (b) documented operator live Bungie steps for cutover day. Historical DART-038/047 merge notes alone do not clear RC-OPS.

**Rationale**: Checklist RC-EQUIP already PASS historically; RC-OPS requires dual-run executed once with live re-verify, not historical only.

**CI vs live Bungie**: Automated host tests prove gates (equip-ready blocks wishlist, DIM jsonOnly, equip partial orchestration). Live Bungie equip against a character remains operator-optional for in-repo RB-04 clearance and is recommended again on cutover day.

## Decision 4 — Offline ops gate (DART-054/058 pattern)

**Decision**: `tool/dual_run_ops_gate.dart` validates runbook markers, shell tree presence, and EXECUTION_NOTES executed-once markers without network.

**Rationale**: Same process pattern as inventory fidelity gate and client secret scan — CI can prove ops artifacts exist and stay complete.

## Decision 5 — Inventory dual-run stays DART-054

**Decision**: Do not re-implement inventory count compare here; link to [multiplatform-dart-inventory-live-parity-harness.md](../../docs/multiplatform-dart-inventory-live-parity-harness.md) for inventory fidelity dual-run.

**Rationale**: Scope discipline; GAP-OPS-01 is ops dual-run + rollback + compose→equip re-verify.

## Non-regressions

- Soft never auto-applies
- No CLIENT_SECRET / SESSION_SECRET in clients
- Pure Dart I/O; no Node sidecar for Dart shells
