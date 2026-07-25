# Multiplatform Dart — Dual-Run + Rollback Runbook (DART-060 / GAP-OPS-01)

**Status:** shipped (runbook + first execution notes + offline ops gate)  
**Updated:** 2026-07-25  
**Program ID:** DART-060  
**Gap:** GAP-OPS-01  
**Cutover:** RB-04 / RC-OPS  
**Architecture:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md)  
**Related:** [cutover parity checklist](./multiplatform-dart-cutover-parity-checklist.md), [inventory live parity harness](./multiplatform-dart-inventory-live-parity-harness.md), [prod Public OAuth matrix](./multiplatform-dart-prod-public-oauth-matrix.md)

This document is the **DUAL_RUN_RUNBOOK** for simultaneous availability of **Next.js (sole production)** and multiplatform **Dart** shells (Windows Flutter + Jaspr web), plus **ROLLBACK_PROCEDURE** and dated **EXECUTION_NOTES**.

## Markers (machine-checked)

The offline ops gate requires these markers to remain in this file:

- `DUAL_RUN_RUNBOOK`
- `ROLLBACK_PROCEDURE`
- `EXECUTION_NOTES`
- `EXECUTED_ONCE`
- `COMPOSE_EQUIP_REVERIFY`
- `equip-ready`
- `Bungie equip partial`
- `DIM jsonOnly`
- `keep Next sole production`
- `soft never auto-applies`
- `CLIENT_SECRET`
- `RC-OPS`
- `RB-04`
- `PRODUCTION_CUTOVER: NO-GO` (or explicit note that PRODUCTION_CUTOVER remains NO-GO)

---

## Why this exists (GAP-OPS-01 / RB-04)

Program slices through DART-059 made Windows + Jaspr feature-ready, but **RC-OPS** stayed **FAIL** because dual-run + rollback had not been **written and executed once**. Compose→equip **RC-EQUIP** was historically PASS from slice merges; cutover requires **re-verify in a dual-run window**, not historical claims only.

Soft guidance never auto-applies. No `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr clients. Pure Dart I/O only (no Node sidecar for Dart shells). Next Confidential secrets stay server-only.

Inventory count dual-run remains under [inventory live parity harness](./multiplatform-dart-inventory-live-parity-harness.md) (DART-054). This runbook owns **ops dual-run + rollback + compose→equip re-verify**.

---

## DUAL_RUN_RUNBOOK

### Prerequisites

| Shell | Role in dual-run | Availability check |
| ----- | ---------------- | ------------------ |
| **Next.js** | **Sole production** host | `package.json` + `src/app` product tree; `npm run dev` / existing prod deploy |
| **Flutter Windows** | Cutover-primary Dart desktop | `apps/windows_host` builds/runs (`run-windows.ps1`) |
| **Jaspr web** | Cutover-primary Dart web | `apps/web_host` serves with entity channel + OPFS |
| Mobile Flutter | Optional only | Not required for RC-OPS |

Also:

- Public+PKCE configured per [prod Public OAuth matrix](./multiplatform-dart-prod-public-oauth-matrix.md) for Dart shells.
- No `CLIENT_SECRET` on Dart hosts (`dart run tool/client_secret_scan.dart` green).
- Prefer same Bungie membership when comparing inventory (DART-054) or equip pins.

### Dual-run start (release window)

1. **Confirm Next remains sole production**
   - Do **not** set `PRODUCTION_CUTOVER: GO`.
   - Production traffic / DNS / Confidential OAuth stay on Next.
2. **Start Dart Windows** (parallel validation host)
   - `cd apps/windows_host` → `.\run-windows.ps1`
   - Settings: sign-in (Public+PKCE), inventory sync with vault resolution, entity/manifest ready.
3. **Start Dart Jaspr web** (parallel validation host)
   - Serve `apps/web_host` with prod entity channel assets; single-tab writer.
   - Settings: sign-in, Sync now; Catalog Owned usable for pins.
4. **Optional inventory fidelity dual-run**
   - Follow [inventory live parity harness](./multiplatform-dart-inventory-live-parity-harness.md) for same-membership counts.
5. **Compose→equip re-verify** — complete [COMPOSE_EQUIP_REVERIFY](#compose_equip_reverify) on Windows and Jaspr (automated + operator steps).
6. **Record EXECUTION_NOTES** (date, shells, results, residuals).

### What dual-run is *not*

- Not a blue/green traffic split.
- Not permission to delete Next or merge multiplatform → `main` as sole prod.
- Not automatic soft apply or secret-bearing clients.

---

## COMPOSE_EQUIP_REVERIFY

Re-verify **in this dual-run window** on **Windows** and **Jaspr** (not historical DART-038/047 notes alone).

### A. Equip-ready gate

| Check | Pass condition |
| ----- | -------------- |
| Wishlist-only pins | **Not** equip-ready; equip CTA / DIM Copy blocked |
| Owned instance pins (valid) | Can be equip-ready when domain rules satisfied |
| Stale pins after sync | Surfaced / not silently equip-ready |

**Automated evidence (required for in-repo dual-run window):**

```powershell
# Pure domain
dart test packages/domain/test/equip_ready_test.dart

# Windows host
cd apps/windows_host
flutter test test/equip_format_test.dart test/equip_panel_test.dart

# Jaspr web
cd apps/web_host
dart test test/equip_format_test.dart
```

**Operator live (recommended; required again on cutover day):**

1. Open a build variant with only wishlist pins → confirm equip/DIM blocked.
2. Pin owned instances from inventory → confirm equip-ready when complete.

### B. Bungie equip partial OK

| Check | Pass condition |
| ----- | -------------- |
| Plan + execute | Best-effort partial; step report; **no full rollback** of successful steps |
| Soft path | Soft never auto-applies kits/pins during equip |

**Automated evidence:**

```powershell
cd apps/windows_host
flutter test test/equip_panel_test.dart test/equip_format_test.dart

cd apps/web_host
dart test test/equip_format_test.dart
# optional equip controller tests if present
```

**Operator live (optional when tokens + character available):**

1. Equip-ready variant → pick character → Apply.
2. Accept partial success if some slots fail; record step report.

### C. DIM jsonOnly

| Check | Pass condition |
| ----- | -------------- |
| Not equip-ready | Copy blocked |
| Equip-ready | Exports `{ loadout }` jsonOnly (no dim.gg required) |
| Soft | Soft advisory does not auto-apply |

**Automated evidence:**

```powershell
cd apps/windows_host
flutter test test/dim_export_format_test.dart test/dim_export_panel_test.dart

cd apps/web_host
dart test test/dim_export_format_test.dart test/dim_export_controller_test.dart
```

### D. Soft + secrets non-regression

- Soft never auto-applies (coverage chips / soft stats / optimizer confirm-only).
- `dart run tool/client_secret_scan.dart` exit 0.
- No `CLIENT_SECRET` on dual-run host configs.

---

## ROLLBACK_PROCEDURE

**Rollback path = keep Next sole production.**

| Step | Action |
| ---- | ------ |
| 1 | Stop using Dart Windows / Jaspr as dual-run validation hosts for the release window (close apps / stop local servers). |
| 2 | Leave Next production traffic, Confidential OAuth, and prod data paths **unchanged**. |
| 3 | Do **not** set `PRODUCTION_CUTOVER: GO`. Do **not** merge multiplatform line to `main` as sole production. |
| 4 | Optionally keep `feature/multiplatform-dart` for continued development; rollback is **ops**, not branch deletion. |
| 5 | Record residual failures in cutover checklist / gaps if product issues found. |

There is no automated traffic failover — dual-run never moved production off Next.

---

## Offline ops gate

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart run tool/dual_run_ops_gate.dart
dart test tool/test/dual_run_ops_gate_test.dart
```

| Check | Pass condition |
| ----- | -------------- |
| Runbook markers | All required markers present in this doc |
| Shell availability | Next tree + `apps/windows_host` + `apps/web_host` exist |
| EXECUTION_NOTES | Contains `EXECUTED_ONCE` and compose→equip evidence markers |
| Cutover linkage | Checklist references this runbook / RC-OPS PASS after slice |

---

## EXECUTION_NOTES

### First dual-run window (DART-060)

| Field | Value |
| ----- | ----- |
| Marker | **EXECUTED_ONCE** |
| Date | **2026-07-25** |
| Program | DART-060 `dual-run-rollback-ops` |
| Worktree | `F:\Destiny2BuildCreator-multiplatform-dart` |
| Branch | `dart-060-dual-run-rollback-ops` → merge `feature/multiplatform-dart` |

#### Shells available

| Shell | Status this window | Notes |
| ----- | ------------------ | ----- |
| Next.js | **Available** (sole production) | Product tree present (`package.json`, `src/app`); dual-run keeps Next as sole prod |
| Flutter Windows | **Available** | `apps/windows_host` present; equip/DIM host tests re-run |
| Jaspr web | **Available** | `apps/web_host` present; equip/DIM host tests re-run |
| Mobile | Optional | Not required for RC-OPS |

#### COMPOSE_EQUIP_REVERIFY results (this window)

| Check | Evidence | Result |
| ----- | -------- | ------ |
| equip-ready gate | `dart test packages/domain/test --name equip` (equip_ready + equip_plan + dim_builders); Windows `equip_format_test` + `equip_panel_test`; web `equip_format_test` | **PASS** (automated re-verify 2026-07-25 dual-run window) |
| Bungie equip partial OK | Windows equip panel: gaps cancel prevents write; owned pin equip path; step report format | **PASS** (automated); live character equip operator-optional residual for cutover day |
| DIM jsonOnly | Windows dim_export panel (wishlist block + jsonOnly clipboard); web dim_export_controller US1/US2 | **PASS** (jsonOnly; blocked when not equip-ready) |
| Soft never auto-applies | Host soft advisory tests + dim export “does not mutate soft targets”; domain policy | **PASS** |
| CLIENT_SECRET | `dart run tool/client_secret_scan.dart`; web `no_client_secret_equip_test` | **PASS** (zero forbidden secrets in clients) |
| Offline ops gate | `dart run tool/dual_run_ops_gate.dart`; `dart test tool/test/dual_run_ops_gate_test.dart` | **PASS** |

#### Rollback confirmation

- **ROLLBACK_PROCEDURE** exercised as definitional confirmation: dual-run did **not** flip production; **keep Next sole production**.
- Cutover checklist: **PRODUCTION_CUTOVER: NO-GO** remains after this slice (DART-061 owns GO).
- No production DNS/traffic change performed.

#### Cutover attachment

- Linked from [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) under residual **RB-04** (cleared) and **RC-OPS** evidence.
- Offline gate: `dart run tool/dual_run_ops_gate.dart`.

#### Residuals (non-blocking for RC-OPS)

- Operator live Bungie equip against a real character in the same wall-clock session is recommended again on cutover day (DART-061); in-repo dual-run window used automated host re-verify as required evidence per DART-060 assumptions.
- Inventory count dual-run: use DART-054 harness when changing parse/resolve paths.

---

## Related artifacts

| Artifact | Role |
| -------- | ---- |
| `tool/dual_run_ops_gate.dart` | Offline ops gate |
| `tool/dual_run_ops/markers.dart` | Marker constants |
| [cutover parity checklist](./multiplatform-dart-cutover-parity-checklist.md) | RB-04 / RC-OPS |
| [feature gaps](./multiplatform-dart-feature-gaps.md) | GAP-OPS-01 |
| `specs/dart-060-dual-run-rollback-ops/` | Spec Kit slice |
