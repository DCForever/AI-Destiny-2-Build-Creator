# Research: DART-057

**Date**: 2026-07-25

## R1 — Mobile equip/catalog product decision

**Decision**: Mark equip, DIM, and catalog as **N/A** on mobile for this slice (not MISS).

**Rationale**: Mobile host has no OAuth session, inventory sync, or Bungie write clients (DART-040/041 deferred sign-in). Shipping equip without owned instance pins would violate DBR equip-ready rules. Catalog Owned without sync is empty theater. Desktop Windows + Jaspr remain equip/DIM/catalog paths.

**Alternatives rejected**:
- Port full EquipController to mobile now — blocked on auth (DART-058) and vault sync.
- Leave MISS without note — overstates defect vs intentional phone thinning (PROC-06 product mark).

## R2 — Finish-gaps host placement

**Decision**: Wire `evaluateFinishGaps` on **Windows** and **Jaspr** compose hosts from already-loaded attachment rows + slot pin claims. Gate equip Apply + DIM Copy with `finishComplete && equipReady`.

**Rationale**: Exit requires at least one production host; both already have equip/DIM. Pure evaluator shipped DART-007. Next FinishTab uses the same category model.

**Alternatives rejected**:
- Full FinishBuildWalkthrough port (create-set one-taps, skip keys, optimizer workspace) — larger than residual polish; deferred walkthrough actions stay residual UX if needed.
- Display-only without CTA gate — weaker than Next policy; exit allows thinning only with product note; we implement the AND policy instead.

## R3 — Soft-stat Jaspr completeness

**Decision**: Expand Health-only input to all `ArmorStatName.all` fields using existing `saveSoftStatTargetsFromFields` / `softStatTargetsFromFieldMap`.

**Rationale**: Windows already loops `ArmorStatName.all`; format helpers already iterate all stats. Soft never auto-applies.

## R4 — Optimizer

**Decision**: Remain deferred on mobile/web (GAP-FEAT-01). Matrix status `deferred`.

## R5 — Finish input mapping

**Decision**:
- Attachments → `FinishAttachmentInput` using `record.mode` wire + `setType` wire (`SetType.tryParse`, default skip unknown types by treating as non-covering if null).
- Slot pins → `FinishEquipmentClaim` keyed by slot wire; filled when itemHash > 0.
- `hasModCoverage`: true when any attachment setType is `mod`.

**Rationale**: Mirrors `evaluateFinishGapsFromVariant` TS path without resolved-equipment network call; pins already expanded from sets.
