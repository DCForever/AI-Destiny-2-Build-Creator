# Inventory live parity harness (DART-054 / GAP-INV-05)

**Status:** shipped (fixture gate + operator dual-run procedure)  
**Updated:** 2026-07-25  
**Program:** DART-054 `inventory-live-parity-harness`  
**Closes:** GAP-INV-05, PROC-03; advances PROC-04 / PROC-05  
**Related:** [feature gaps](./multiplatform-dart-feature-gaps.md), [cutover checklist RC-SYNC](./multiplatform-dart-cutover-parity-checklist.md), DART-050–053 inventory fidelity program

This document is the **dual-run procedure** and inventory fidelity gate contract for Next.js vs multiplatform Dart inventory counts.

## Markers (machine-checked)

The offline gate requires these markers to remain in this file:

- `DUAL_RUN_PROCEDURE`
- `INVENTORY_FIDELITY_SNAPSHOT`
- `INVENTORY_FIDELITY_GATE`
- References to `p0_parity_gate`, `byLocation`, `byBucket`, `resolvedFromTransfer`, `storedTotal`, `tolerance`, `inventory_fidelity_compare`, `inventory_fidelity_gate`, `PROC-05`, `GAP-INV-05`

---

## Why this exists (GAP-INV-05 / PROC-03)

Vault/postmaster and enrichment regressions shipped while pure unit tests stayed green (empty `equipmentBucketLookup` still “worked”). Live dual-use then showed Dart under-counting vault copies vs Next for the same membership.

DART-050–053 fixed product fidelity (lookup wiring, roll tags, sockets, diagnostics UI). **DART-054** prevents silent drift by requiring:

1. A written dual-run path for the **same** Bungie membership  
2. A pure-Dart compare tool on portable count snapshots  
3. An **inventory fidelity gate** that CI/operators can run **without** live tokens  

### Separation from pure domain gate (PROC-05)

| Gate | Command | What it proves |
| ---- | ------- | -------------- |
| Pure domain **p0_parity_gate** | `dart run tool/p0_parity_gate.dart` | Domain packages clean + pure suite green; soft never auto-applies at domain layer |
| **INVENTORY_FIDELITY_GATE** | `dart run tool/inventory_fidelity_gate.dart` | Procedure doc present + fixture Next-vs-Dart count parity (byLocation/byBucket/resolution) |

**p0_parity_gate green does not claim inventory sameness vs Next.** Claiming inventory parity after inventory-sync changes requires the fidelity gate (and operator dual-run when changing production parse/resolve paths).

Soft guidance never auto-applies. No `CLIENT_SECRET` / session secrets in clients or harness fixtures.

---

## DUAL_RUN_PROCEDURE

Operator path for live same-membership compare (not run in CI).

### Prerequisites

- Same Bungie membership on both hosts (membershipType + membershipId).
- Next app signed in (confidential session as today).
- Dart Windows host signed in (Public + PKCE; no client secret in binary).
- Manifest / entity cache available on Dart so Owned is not empty solely for entity reasons (GAP-INV-06).
- Prefer capturing both sides within a short window to avoid inventory churn mid-session.

### Steps

1. **Next**
   - Open Settings → inventory sync (or existing product sync path).
   - Run a full inventory sync.
   - From server logs / diagnostics (or debugger), capture `InventoryParseDiagnostics` fields listed under [INVENTORY_FIDELITY_SNAPSHOT](#inventory_fidelity_snapshot).
   - Save as `next.json` using the snapshot schema below.

2. **Dart (Windows)**
   - Open Settings → inventory sync card.
   - Ensure equipment bucket lookup is wired (DART-050) so vault/postmaster resolve.
   - Run **Sync now**.
   - Capture diagnostics from the UI block (raw/parsed/dropped/resolution) and, if needed, host debug of `parsed.byLocation` / `parsed.byBucket` from `lastDiagnostics`.
   - Save as `dart.json` with the same schema.

3. **Compare**
   ```text
   dart run tool/inventory_fidelity_compare.dart --next next.json --dart dart.json
   ```
   Default **tolerance** is `0` (exact). For exploratory mid-session churn only:
   ```text
   dart run tool/inventory_fidelity_compare.dart --next next.json --dart dart.json --tolerance 2
   ```
   Permanent thinning must open/update a GAP/RB residual (PROC-06), not hide under tolerance.

4. **Interpret**
   - **PASS** — counts by location/bucket and resolution metrics match within tolerance; membership identity matches.
   - **FAIL** — report lists field paths (e.g. `parsed.byLocation.vault`, `resolution.resolvedFromTransfer`). Investigate parse/resolve regressions before claiming inventory parity.

5. **Attach evidence (cutover)**
   - Paste compare report (or note PASS + membership id hash) into release/dual-run notes referenced by **RC-SYNC**.
   - Live dual-run is operator evidence; fixture gate remains the offline regression net.

---

## INVENTORY_FIDELITY_SNAPSHOT

JSON object. Optional fields may be omitted; compare treats missing map keys as `0`. Resolution may be omitted only if **both** sides omit it.

```json
{
  "source": "next",
  "capturedAt": "2026-07-25T12:00:00Z",
  "membership": {
    "membershipType": 3,
    "membershipId": "…",
    "displayName": "optional"
  },
  "raw": {
    "total": 0,
    "vault": 0,
    "characterInventoriesTotal": 0,
    "characterEquipmentTotal": 0
  },
  "parsed": {
    "total": 0,
    "equipmentTotal": 0,
    "subclassTotal": 0,
    "byLocation": {
      "vault": 0,
      "character": 0,
      "equipped": 0
    },
    "byBucket": {
      "1498876634": 0
    }
  },
  "dropped": {
    "total": 0,
    "invalidShape": 0,
    "unknownBucket": 0,
    "missingInstanceId": 0
  },
  "resolution": {
    "resolvedFromTransfer": 0,
    "droppedNonEquipment": 0,
    "storedTotal": 0,
    "storedEquipment": 0
  }
}
```

### Compared fields (high signal)

| Path | Why |
| ---- | --- |
| `membership.identity` | Same-membership dual-run |
| `raw.total` / raw sub-totals | Bungie surface area |
| `parsed.total`, `equipmentTotal`, `subclassTotal` | Parse fidelity |
| `parsed.byLocation.*` | Vault vs character vs equipped |
| `parsed.byBucket.*` | Equipment bucket distribution |
| `dropped.*` | Drop path visibility |
| `resolution.resolvedFromTransfer` | Vault/postmaster resolve (DART-050) |
| `resolution.storedTotal` / `storedEquipment` | What landed in Drift |
| `resolution.droppedNonEquipment` | Intentional non-equipment drop |

Reference types:

- Next: `src/lib/bungie/types.ts` → `InventoryParseDiagnostics`
- Dart: `packages/bungie` → `InventoryParseDiagnostics` / `InventoryResolutionCounts`
- Human format (Settings): `formatSyncDiagnostics` (DART-053)

### Fixture pair (CI)

```text
tool/fixtures/inventory_fidelity/next_match.json
tool/fixtures/inventory_fidelity/dart_match.json
```

These are **synthetic matching** snapshots proving the harness, not a live account dump.

---

## INVENTORY_FIDELITY_GATE

### Offline gate (CI / pre-merge)

```text
dart run tool/inventory_fidelity_gate.dart
```

Checks:

1. This procedure doc exists and contains required markers (including PROC-05 separation language).  
2. Fixture pair parses and **inventory_fidelity_compare** passes at **tolerance** 0.

Does **not**:

- Call Bungie APIs  
- Read OAuth tokens  
- Run `p0_parity_gate` / pure domain suite  

### Ad-hoc compare

```text
dart run tool/inventory_fidelity_compare.dart --next <path> --dart <path> [--tolerance N]
```

Exit codes: `0` pass, `1` count/membership fail, `2` usage/parse error.

### Unit tests

```text
dart test tool/test/inventory_fidelity_compare_test.dart tool/test/inventory_fidelity_gate_test.dart
```

### When to re-run (operator gate for inventory-sync changes)

Re-run fidelity gate (and prefer live dual-run) when changing:

- `packages/bungie` inventory parse / transfer resolution / sync replace  
- Host `equipmentBucketLookup` wiring  
- Next `syncInventory` / `resolveEquipmentBuckets` / inventory parse  

Domain-only changes still use `p0_parity_gate` only.

---

## Cutover / residuals

- **RC-SYNC** requires vault/postmaster fidelity within agreed Next tolerance (default exact) **or** a documented residual GAP/RB — not only “Settings sync card exists” (PROC-04).  
- **RB-06** (inventory fidelity program) is cleared by DART-050–054 shipped evidence; **RB-02** / web owned depth cleared by **DART-056** (Jaspr Settings sync + Owned catalog).  
- Soft never auto-applies; no CLIENT_SECRET in clients.

---

## Quick commands

```text
# Offline inventory fidelity gate (separate from p0)
dart run tool/inventory_fidelity_gate.dart

# Pure domain gate (not inventory sameness)
dart run tool/p0_parity_gate.dart

# Live dual-run compare
dart run tool/inventory_fidelity_compare.dart --next next.json --dart dart.json
```
