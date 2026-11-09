# Data Model: Finish Slot-First Chrome

**Feature**: 029-finish-slot-first  
**Date**: 2026-07-23

No durable schema changes. Session/DTO refinements over 028 finish gaps.

## InheritedSetCreateIntent (Finish)

| Field | Type | Rules |
|-------|------|-------|
| `variantId` | string | Active variant |
| `type` | `armor` \| `weapon` \| `mod` | Fixed from Finish category (pair not in Finish primary) |
| `name` | omitted | Server inherits from build + type label |
| `tagIds` | omitted in Finish | Optional only on Sets-tab create |
| `attachNow` | true | Always for Finish create |

## FinishSlotCursor

| Field | Type | Notes |
|-------|------|-------|
| `category` | FinishCategory | armor \| weapon \| mod |
| `coveringSetId` | string | Live covering set |
| `slot` | string | Current empty required slot |
| `remainingEmptySlots` | string[] | After current, in required order |

Derived from `FinishGap.emptySlots` (already required-order filtered in `evaluateFinishGaps`).

## FinishCategoryStepMode (UI)

| Mode | When |
|------|------|
| `capture_or_create` | status `needs_set` or `capture_available`; show Capture (if canCapture) + one-tap Create; no link form |
| `fill_loop` | status `needs_fill` + live covering; auto or continue empty slots |
| `snapshot_blocked` | needs_fill + snapshot covering; prompt live path |
| `satisfied` | leave category |

## Relationships

FinishGap (028) → step mode → InheritedSetCreateIntent \| Capture intent → refresh → FinishSlotCursor → InlineSlotFillIntent (028) → refresh

## Validation rules

- Finish never sends user-entered name/tags for one-tap create.
- `emptySlots[0]` is the only auto-opened slot; order stable per category required list.
- Skip keys client-only; do not mark satisfied.
- Sets-tab create may still send name/tags (out of Finish intent).

## Non-goals

No walkthrough persistence table; no change to set item schema; no optimizer constraint entities (030/031).
