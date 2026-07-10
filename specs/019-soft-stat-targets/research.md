# Research: Soft Stat Targets

**Feature**: 019-soft-stat-targets  
**Date**: 2026-07-10

## R1 — Storage

**Decision**: `builds.soft_stat_targets` TEXT JSON — `Partial<Record<ArmorStatName, number>>`. Omit unset keys. Validate integers 1–200 (`STAT_MAX`).

**Rationale**: Build-level (DBR-STAT-002); matches `stat_values` / `artifact_config` patterns.

## R2 — Coverage extension

**Decision**: Extend `CoverageResult` with:
```ts
softStats: SoftStatWarningRow[]  // below-target only
statEstimate?: Partial<Record<ArmorStatName, number>> & { incomplete?: boolean }
targets?: Partial<Record<ArmorStatName, number>>
```
Update/remove 017 test that asserted no `softStats`.

**Rationale**: Spec assumes extend coverage; one Fetch Coverage debug path.

## R3 — Estimate scope (best-effort)

**Decision**: v1 estimate sums:
1. Pinned/owned armor instance `stat_values` on combat armor slots when `instanceId` present  
2. Exotic armor intrinsic ignored unless already in instance stats  
3. Document incompleteness when slots lack instance stats or mods/fragments not modeled  

Mods/fragments/aspects: include only if existing helpers already expose numeric bonuses; otherwise set `incomplete: true`.

**Rationale**: DBR-STAT-005 ideal vs available data; soft warnings still valuable.

## R4 — Nudges

**Decision**: Static map synergy `type` / tags → suggested stats (e.g. melee → Melee). `GET …/suggest-stat-targets` returns nudges; `PATCH` build with `acceptStatNudges: true` or explicit targets merges without lowering higher existing targets.

**Rationale**: DBR-STAT-006 opt-in.

## R5 — Soft save

**Decision**: Confirm `updateUserBuild` / variant save never reads softStats for hard fail. Regression test like 017 softSave.

## R6 — Debug

**Decision**: BuildsDebugPage: six optional target inputs + Save targets; Fetch Coverage shows softStats/estimate.
