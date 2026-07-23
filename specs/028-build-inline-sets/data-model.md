# Data Model: Build Inline Sets

**Feature**: 028-build-inline-sets  
**Date**: 2026-07-23

Ephemeral evaluation/session DTOs over existing Sets, attachments, and resolved equipment. **No new durable tables in v1.**

## FinishCategory

| Value | Set type(s) covering | Required combat slots (default variant) |
|-------|----------------------|----------------------------------------|
| `armor` | `armor` | helmet, arms, chest, legs, class item |
| `weapon` | `weapon` | primary, special, heavy |
| `mod` | `mod` | v1: presence of covering Mod Set **or** explicit product rule if armor-embedded mods count; capture may skip |

Order: **armor → weapon → mod** (FR-020).

## FinishGapStatus

| Status | Meaning |
|--------|---------|
| `satisfied` | Covering Set attached **and** all required slots for category filled on resolved loadout |
| `needs_set` | No covering Set (may still have resolved gear elsewhere) |
| `needs_fill` | Covering Set attached; one or more required slots empty |
| `capture_available` | `needs_set` (or unsatisfied) **and** ≥1 resolved claim in category suitable for create-from-build |

## FinishGap

| Field | Type | Notes |
|-------|------|-------|
| `category` | FinishCategory | |
| `status` | FinishGapStatus | |
| `coveringSetId` | string \| null | Attached set of matching type |
| `coveringSetName` | string \| null | |
| `emptySlots` | string[] | Required slots lacking equipment |
| `filledSlotCount` | number | |
| `requiredSlotCount` | number | |
| `resolvedClaimCount` | number | From resolveVariant equipment/mod claims |
| `canCapture` | boolean | Prefer Capture CTA when true |
| `skippedInSession` | boolean | Client session only; not satisfied |

## FinishGapsResult

| Field | Type | Notes |
|-------|------|-------|
| `variantId` | string | |
| `isDefaultVariant` | boolean | Drives CTA strength |
| `complete` | boolean | All categories satisfied for this variant's completeness rules |
| `gaps` | FinishGap[] | Ordered armor → weapon → mod |
| `nextActionable` | FinishGap \| null | First non-satisfied, preferring non-skipped-in-session |

## InlineSetCreateIntent

| Field | Type | Rules |
|-------|------|-------|
| `name` | string | optional; default from build name + type label; auto-suffix unique |
| `type` | `armor` \| `weapon` \| `mod` \| `pair` | Fashion not in primary walkthrough |
| `tagIds` | string[] optional | concept tags |
| `variantId` | string | attach target |
| `attachNow` | boolean | default true |

## InlineSlotFillIntent

| Field | Type | Notes |
|-------|------|-------|
| `setId` | string | live-attached set |
| `slot` | string | set slot key |
| `itemHash` / `itemName` / `instanceId` / `selectedPerks` | as set item upsert | Same as Sets fill |

## CreateFromBuildIntent (existing)

`variantId`, `categories[]`, `attachNow`, `namePrefix` — see [026 create-sets contract](../026-armor-set-optimizer/contracts/create-sets-from-build-contract.md).

## FinishWalkthroughSession (client)

| Field | Type | Notes |
|-------|------|-------|
| `buildId` / `variantId` | string | |
| `step` | `overview` \| `category` \| `fill` \| `done` | |
| `activeCategory` | FinishCategory \| null | |
| `skippedKeys` | string[] | e.g. `armor`, `armor:helmet` |
| `activeSetId` | string \| null | set being filled |

## Relationships

Build Variant → Attachments → Sets → SetItems  
`resolveVariantEquipment` → claims  
`evaluateFinishGaps` → FinishGapsResult → Walkthrough UI → InlineSetCreateIntent | SetAttach | CreateFromBuildIntent | InlineSlotFillIntent → refreshed Variant

## Validation rules

- Satisfied requires **both** covering Set and required fills (FR-021).
- Skip for now does not change durable state (FR-022).
- Capture preferred when `canCapture` (FR-023).
- Live attach default; replace-by-type on same-type live when attaching new covering set for finish (align BR-OPT-001).
- Snapshot attachments: do not mutate underlying library Set via live fill path; guide to live set or existing snapshot editors.

## Non-goals

No walkthrough persistence table; no change to set item schema; no Fashion finish path.
