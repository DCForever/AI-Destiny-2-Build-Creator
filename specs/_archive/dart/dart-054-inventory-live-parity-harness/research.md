# Research: DART-054 Inventory Live Parity Harness

**Date**: 2026-07-25

## Decision: Offline fixture gate + operator live dual-run

**Choice**: CI runs pure JSON fixture compare + procedure-doc marker checks. Live Bungie dual-run is a documented operator procedure that produces the same JSON snapshots for the compare CLI.

**Why**: Exit criteria require both “documented dual-run” and “operator/CI gate.” Live tokens cannot ship in CI (no CLIENT_SECRET, no account secrets). Fixture path prevents silent harness rot; operator path prevents silent product drift.

**Rejected**: Embedding live OAuth in the gate (secrets + flaky network). Requiring Node to dump Next diagnostics (violates pure Dart I/O for the harness tooling path — operators may still copy from Next console manually).

## Decision: Snapshot schema mirrors InventoryParseDiagnostics

**Choice**: JSON fields align with Next `InventoryParseDiagnostics` + Dart `InventoryParseDiagnostics` / `InventoryResolutionCounts` (raw, parsed.byLocation/byBucket, dropped, resolution). Optional `source` (`next`|`dart`) and `capturedAt` for human notes.

**Why**: Operators can paste from existing diagnostics without inventing a third model. DART-053 already surfaces these counts on Windows Settings.

## Decision: Default tolerance = 0 (exact)

**Choice**: CI and default CLI use absolute delta ≤ 0. Optional `--tolerance N` for exploratory dual-runs when inventory churn mid-session is known; residuals must be documented if permanent.

**Why**: “Within Next tolerance” is agreed here as exact for same-membership same-session captures. Loose default would hide vault under-count regressions (the original silent failure mode).

## Decision: Fidelity gate separate binary from p0_parity_gate

**Choice**: `tool/inventory_fidelity_gate.dart` is a sibling of `tool/p0_parity_gate.dart`, not a step inside it.

**Why**: PROC-05 — pure domain green ≠ inventory sameness. Historical empty-lookup unit tests passed while production hosts dropped vault. Keeping gates separate makes the claim surface explicit.

## Decision: RB-06 clearance on DART-054 merge

**Choice**: Clear RB-06 when DART-050–054 are done; leave RC-SYNC **FAIL** only if other blockers remain (RB-02 web inventory depth). Note that live dual-run operator evidence can still be attached later under RC-OPS / dual-run notes without reopening RB-06.

**Why**: Exit criteria: “clears RB-06 when combined with DART-050–053 evidence.” RB-06 described vault unwired + enrichment thinner + no harness; those product gaps are closed by 050–053 and process gap by 054.

## Next / Dart field mapping

| Snapshot path | Next | Dart |
| ------------- | ---- | ---- |
| `membership.*` | diagnostics.membership | InventoryParseDiagnostics.membership |
| `raw.total` | diagnostics.raw.total | same |
| `parsed.byLocation` | vault/character/equipped | same keys |
| `parsed.byBucket` | Record string→count | Map string→int |
| `resolution.resolvedFromTransfer` | diagnostics.resolution | InventoryResolutionCounts |
| `resolution.storedTotal` | same | same |

## References

- `src/lib/bungie/types.ts` — InventoryParseDiagnostics
- `packages/bungie/lib/src/profile/profile_types.dart`
- `packages/bungie/lib/src/sync/format_sync_diagnostics.dart` (DART-053)
- `docs/multiplatform-dart-feature-gaps.md` GAP-INV-05, PROC-03/04/05
- `docs/multiplatform-dart-cutover-parity-checklist.md` RC-SYNC, RB-06
