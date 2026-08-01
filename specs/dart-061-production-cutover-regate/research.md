# Research: DART-061 Production Cutover Re-Gate

**Date**: 2026-07-25  
**Slice**: DART-061

## Decisions

### R1 — GO is documentary + gated; not an auto-merge to main

**Decision:** Setting `PRODUCTION_CUTOVER: GO` records that Next may stop being the sole production host and that merge of `feature/multiplatform-dart` toward production/`main` is **policy-allowed**. This slice does **not** execute `git merge` into `main`.

**Rationale:** Branching rules and finish-spec contract keep DART landings on `feature/multiplatform-dart`. Production main merge is a human/release step after GO.

### R2 — RC-BRANCH PASS condition

**Decision:** RC-BRANCH was **FAIL** solely because GO was not set. After GO + written “merge only after GO” policy in branching.md + checklist, RC-BRANCH is **PASS**.

**Rationale:** Checklist pass condition: “Explicit decision to merge … only after PRODUCTION_CUTOVER GO.” The GO decision *is* that explicit decision.

### R3 — Re-use offline gate pattern

**Decision:** Ship `tool/production_cutover_regate.dart` + markers module (same style as dual_run_ops_gate / inventory_fidelity_gate / cutover_parity_checklist_validate).

**Rationale:** Machine-checkable exit criteria; CI/agent evidence for SC-001.

### R4 — GAP-FEAT-02 stays non-goal

**Decision:** dim.gg share remains deferred; jsonOnly sufficient. Re-gate asserts non-goal residual markers so cutover cannot silently require share URL parity.

**Rationale:** Slice exit criteria and feature-gaps deferred table.

### R5 — Evidence for prior RC-* PASS

**Decision:** Do not re-implement DART-050–060 features. Re-gate + checklist updates cite existing evidence (RB-01…06 cleared, dual-run EXECUTED_ONCE, fidelity gate, OAuth matrix, entity channel, loadouts, etc.).

**Rationale:** Scope is re-gate, not feature rebuild.

## Alternatives considered

| Alt | Why rejected |
| --- | ------------ |
| Auto-merge to main in finish-spec | Violates DART land-on-feature-base rule; too aggressive for agents |
| Leave PRODUCTION_CUTOVER NO-GO forever | Blocks program goal / GAP-CUT-01 |
| Require dim.gg for GO | Contradicts GAP-FEAT-02 non-goal |

## Open items (none for this slice)

Operator live Bungie portal re-smoke on cutover day remains recommended ops hygiene, not a code deliverable.
