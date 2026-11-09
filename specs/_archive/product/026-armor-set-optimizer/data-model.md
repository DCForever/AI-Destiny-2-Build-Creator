# Data Model: Armor Set Optimizer

**Feature**: 026-armor-set-optimizer  
**Date**: 2026-07-14  
**Related**: [spec.md](./spec.md), [research.md](./research.md)

## Persistence

**No new tables.** Optimizer search requests/results remain ephemeral. Durable state extends the existing `sets` row for Armor Sets:

| Existing entity | Use |
|-----------------|-----|
| `sets.optimizer_constraints` (TEXT JSON, nullable) | Persisted `ArmorSetOptimizerConstraints` on Armor Sets |
| `sets.linked_mod_set_id` (TEXT, nullable) | Optional companion Mod Set created/updated with assumed mods |
| `sets` + set items | Materialized / refreshed Armor / Weapon / Mod Sets |
| Build variant attachments | Live attach after create-from-build / materialize (replace-by-type) |
| `user_inventory_items.stat_values`, `gear_tier`, plugs | Candidate armor rolls |
| `builds.soft_stat_targets` | Seed priorities/thresholds on create-from-build / optimize-from-build |
| Set-bonus manifest maps | Family identity for coverage goals |

Presence of a non-null `optimizer_constraints` payload (even partial — exotic and/or soft stats only, empty set-bonus goals OK) makes the Armor Set **constrained** and eligible for post-sync / on-open improvement checks. Clearing the column (or writing `null`) opts the Set out until constraints are set again.

## Persisted entities

### ArmorSetOptimizerConstraints

Stored on the Armor Set as JSON. First materialize and create-from-build (armor) write this payload; refresh **does not** change it unless the user explicitly edits and saves constraints (FR-010a/b/d).

| Field | Type | Notes |
|-------|------|--------|
| `lockedExoticItemHash` | `number \| null` | Hard exotic lock when set |
| `setBonusGoals` | `SetBonusCoverageGoal[]` | Hard; may be `[]` |
| `statPriorities` | `ArmorStatName[]` | Ordered; higher index = lower priority |
| `statThresholds` | `Partial<Record<ArmorStatName, number>>` | Soft unless `requireThresholds` |
| `requireThresholds` | boolean | Default false |
| `includeModEstimates` | boolean | Default true when seeded from soft targets |
| `preferReuse` | boolean | Soft tie-break after lexicographic stats; **default false** |

### Linked Mod Set

| Field | Type | Notes |
|-------|------|--------|
| `linkedModSetId` | `string \| null` | On Armor Set; optional Mod Set holding assumed/applied mods |

On first materialize with mods, create Mod Set and set `linkedModSetId`. On refresh apply, update that Mod Set in place when present (or create if missing and user opts in).

### ImprovementSuggestion (ephemeral / API)

Not a table — computed when evaluating constrained Sets after sync or on Set open.

| Field | Type | Notes |
|-------|------|--------|
| `armorSetId` | string | Constrained Set under review |
| `buildIds` | `string[]` | Builds attaching this Set (empty if on-open unattached check) |
| `currentRankSummary` | object | Brief current-kit score/stats |
| `betterCombination` | `ArmorCombination` | Top better complete kit (or omitted if none) |
| `hasImprovement` | boolean | |

## Ephemeral entities (API / domain)

### ArmorOptimizationRequest

| Field | Type | Notes |
|-------|------|--------|
| `classType` | enum | Titan / Hunter / Warlock — required if no `buildId` / Set context |
| `buildId` | string? | Seeds class, exotic lock, soft targets |
| `variantId` | string? | Optional; default variant if omitted |
| `armorSetId` | string? | Refresh: load stored constraints; exclude this Set from reuse “other” list |
| `lockedExoticItemHash` | number? | Hard constraint; null = any/no force |
| `requireExotic` | boolean? | Default false; when true every kit has exactly one exotic armor |
| `setBonusGoals` | `SetBonusCoverageGoal[]` | Hard; empty = no set-bonus hard filter |
| `statPriorities` | `ArmorStatName[]` | Ordered; higher index = lower priority |
| `statThresholds` | `Partial<Record<ArmorStatName, number>>` | Soft unless `requireThresholds` |
| `requireThresholds` | boolean | Default false — soft ranking only |
| `includeModEstimates` | boolean | Default true |
| `preferReuse` | boolean? | Override for this search; persist only when saving constraints |
| `maxResults` | number | Cap (e.g. 1–50, default 25) |

### SetBonusCoverageGoal

| Field | Type | Notes |
|-------|------|--------|
| `setBonusKey` | string | Stable id or canonical name resolved against set-bonus map |
| `minPieces` | `2 \| 4` | Coverage required |

### ArmorCombination

| Field | Type | Notes |
|-------|------|--------|
| `pieces` | `CombinationPiece[]` | One per slot — **complete five-slot kits only** |
| `estimatedStats` | `Partial<Record<ArmorStatName, number>>` | Base ± mods |
| `incompleteEstimate` | boolean | Data gaps |
| `setBonusSummary` | `{ key, pieces, active2pc?, active4pc? }[]` | Display / verify |
| `assumedMods` | `AssumedMod[]` | Empty if mod estimates off |
| `reusePieceCount` | number | 0–5: pieces in ≥1 other Armor Set |
| `score` | number / breakdown | Lexicographic stats (+ preferReuse after ties) |
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
| `usedInOtherSets` | `{ id, name }[]` | Other Armor Sets with this instance as **active** item; empty if unused elsewhere |

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
| `attachNow` | boolean | Default true — **replace-by-type** |
| `variantId` | string? | Default variant |
| `namePrefix` | string? | Else derive from build name; auto-suffix on collision |

### CreateSetsFromBuildResult

| Field | Type | Notes |
|-------|------|--------|
| `createdSets` | `{ id, type, name, optimizerConstraints? }[]` | Armor includes seeded constraints |
| `attachments` | `{ setId, mode, replacedSetIds? }[]` | Empty if `attachNow` false |
| `skippedCategories` | string[] | Empty source |

### MaterializeRequest (first-time)

| Field | Type | Notes |
|-------|------|--------|
| `combination` | pieces (+ assumedMods) | Client echo |
| `constraints` | `ArmorSetOptimizerConstraints` | Persisted on new Armor Set |
| `armorSetName` | string | Base name; auto-unique suffix on collision |
| `createModSet` | boolean | Default true when assumedMods present |
| `modSetName` | string? | |
| `attachNow` | boolean | Replace-by-type when true |
| `buildId` / `variantId` | string? | Required if attachNow |

### ApplyCombinationRequest (refresh)

| Field | Type | Notes |
|-------|------|--------|
| `armorSetId` | string | Existing constrained Set — **items updated in place** |
| `combination` | pieces (+ assumedMods) | Chosen better kit |
| `updateLinkedModSet` | boolean | Default true when assumedMods + link/create |

## Validation rules

- At most **one** exotic armor piece across combination pieces (DBR-CMP-007).
- Returned kits MUST fill all five armor slots; incomplete kits are excluded.
- `setBonusGoals` must be satisfiable only with owned pieces; empty result + explanation otherwise.
- Mod assumptions must not exceed energy capacity per piece (10 / 11 by tier).
- Set names unique per user per set type; create-from-build and first-time materialize **auto-suffix** — never fail solely for name collision.
- Attach-now uses **replace-by-type**: detach existing live same-type attachment(s) on the variant, then attach the new Set(s).
- Soft thresholds never hard-fail Build save; optimizer may optionally hard-filter when `requireThresholds: true`.
- Cross-Set reuse counts **active** items on **other** Armor Sets owned by the user; soft-removed items and the Set under optimization/refresh are excluded.
- `preferReuse` affects ranking only after lexicographic stats (+ prioritized-stat sum); never above better stats.

## State transitions

```text
[Idle]
  → create-from-build → Sets created (+ Armor constraints seeded)
       → (optional) replace-by-type attach live
  → optimize → Combinations[] (ephemeral; reuse annotations)
       → select → materialize (first time) → NEW Armor Set + stored constraints
            → (+ optional Mod Set / linkedModSetId)
            → (optional) replace-by-type attach live
  → refresh (stored constraints) → Combinations[]
       → confirm apply → UPDATE Armor Set items in place (id unchanged)
            → (optional) update/create linked Mod Set
  → post-sync / on-open check → ImprovementSuggestion (soft)
       → user confirms → same in-place apply as refresh
       → user dismisses → items unchanged
```

No persisted “search job” state in v1. Refresh and soft suggestions **update items on the existing Set**; they do not create a duplicate Armor Set for the same constrained kit.
