# Data Model: Armor Set Optimizer

**Feature**: 026-armor-set-optimizer  
**Date**: 2026-07-14  
**Related**: [spec.md](./spec.md), [research.md](./research.md)

## Persistence

**No new tables.** Optimizer inputs/outputs are request/response. Durable writes use existing Sets / set items / build variant attachments.

| Existing entity | Use |
|-----------------|-----|
| `sets` + set items | Materialized Armor / Weapon / Mod Sets |
| Build variant attachments | Live attach after create-from-build / materialize |
| `user_inventory_items.stat_values`, `gear_tier`, plugs | Candidate armor rolls |
| `builds.soft_stat_targets` | Seed priorities/thresholds |
| Set-bonus manifest maps | Family identity for coverage goals |

## Ephemeral entities (API / domain)

### ArmorOptimizationRequest

| Field | Type | Notes |
|-------|------|--------|
| `classType` | enum | Titan / Hunter / Warlock — required if no `buildId` |
| `buildId` | string? | Seeds class, exotic lock, soft targets |
| `variantId` | string? | Optional; default variant if omitted |
| `lockedExoticItemHash` | number? | Hard constraint; null = any/no force |
| `requireExotic` | boolean? | Default false; when true every kit has exactly one exotic armor |
| `setBonusGoals` | `SetBonusCoverageGoal[]` | Hard; empty = no set-bonus hard filter |
| `statPriorities` | `ArmorStatName[]` | Ordered; higher index = lower priority |
| `statThresholds` | `Partial<Record<ArmorStatName, number>>` | Soft unless `requireThresholds` |
| `requireThresholds` | boolean | Default false — soft ranking only |
| `includeModEstimates` | boolean | Default true |
| `maxResults` | number | Cap (e.g. 1–50, default 25) |

### SetBonusCoverageGoal

| Field | Type | Notes |
|-------|------|--------|
| `setBonusKey` | string | Stable id or canonical name resolved against set-bonus map |
| `minPieces` | `2 \| 4` | Coverage required |

### ArmorCombination

| Field | Type | Notes |
|-------|------|--------|
| `pieces` | `CombinationPiece[]` | One per filled slot |
| `estimatedStats` | `Partial<Record<ArmorStatName, number>>` | Base ± mods |
| `incompleteEstimate` | boolean | Data gaps |
| `setBonusSummary` | `{ key, pieces, active2pc?, active4pc? }[]` | Display / verify |
| `assumedMods` | `AssumedMod[]` | Empty if mod estimates off |
| `score` | number / breakdown | For stable sort |
| `meetsSoftThresholds` | boolean | Informational |

### CombinationPiece

| Field | Type | Notes |
|-------|------|--------|
| `slot` | armor slot | `helmet` \| `arms` \| `chest` \| `legs` \| `class_item` |
| `itemHash` | number | |
| `instanceId` | string | Owned instance |
| `itemName` | string? | Display |
| `isExotic` | boolean | |
| `setBonusKey` | string? | |
| `statValues` | record | Snapshot used for score |

### AssumedMod

| Field | Type | Notes |
|-------|------|--------|
| `armorSlot` | armor slot | |
| `itemHash` | number | Mod plug |
| `name` | string? | |
| `energyCost` | number | |
| `statDeltas` | partial EoF six | |

### CreateSetsFromBuildRequest

| Field | Type | Notes |
|-------|------|--------|
| `categories` | `('armor'\|'weapon'\|'mod')[]` | Default: all non-empty |
| `attachNow` | boolean | Default true |
| `variantId` | string? | Default variant |
| `namePrefix` | string? | Else derive from build name |

### CreateSetsFromBuildResult

| Field | Type | Notes |
|-------|------|--------|
| `createdSets` | `{ id, type, name }[]` | |
| `attachments` | `{ setId, mode }[]` | Empty if `attachNow` false |
| `skippedCategories` | string[] | Empty source |

### MaterializeRequest

| Field | Type | Notes |
|-------|------|--------|
| `combination` | `ArmorCombination` pieces (+ assumedMods) | Client echo |
| `armorSetName` | string | Uniqueness per type |
| `createModSet` | boolean | Default true when assumedMods present |
| `modSetName` | string? | |
| `attachNow` | boolean | |
| `buildId` / `variantId` | string? | Required if attachNow |

## Validation rules

- At most **one** exotic armor piece across combination pieces (DBR-CMP-007).
- `setBonusGoals` must be satisfiable only with owned pieces; empty result + explanation otherwise.
- Mod assumptions must not exceed energy capacity per piece (10 / 11 by tier).
- Set names unique per user per set type; create-from-build auto-suffixes.
- Soft thresholds never hard-fail Build save; optimizer may optionally hard-filter when `requireThresholds: true`.

## State transitions

```text
[Idle]
  → create-from-build → Sets created → (optional) attached live
  → optimize → Combinations[] (ephemeral)
       → select → materialize → Armor Set (+ Mod Set) → (optional) attached live
```

No persisted “search job” state in v1.
