# Data Model: DART-007 Finish Gaps

## Reused (DART-002)

| Type | Role |
| ---- | ---- |
| `EquipmentSlot.armorSlots` / `weaponSlots` | Required fill slots |
| `SetType` | Attachment set type filter (armor/weapon/mod) |
| `AttachmentMode` | live \| snapshot covering preference |

## New this slice

### FinishCategory

| Wire | Notes |
| ---- | ----- |
| `armor` | First in order |
| `weapon` | Second |
| `mod` | Third; no required combat slots |

### FinishGapStatus

| Wire | Meaning |
| ---- | ------- |
| `satisfied` | Category complete for finish guidance |
| `needs_set` | No covering set (and no claims for armor/weapon; mod without soft) |
| `needs_fill` | Covering set present; empty required slots |
| `capture_available` | Claims present without covering set (armor/weapon) |

### FinishAttachmentInput

| Field | Type | Notes |
| ----- | ---- | ----- |
| setId | String | Covering set id |
| mode | AttachmentMode | live preferred over snapshot |
| setType | SetType | armor / weapon / mod (pair/fashion ignored for covering) |
| setName | String? | Optional display |

### FinishEquipmentClaim

| Field | Type | Notes |
| ----- | ---- | ----- |
| slot | String | Wire slot name |
| itemHash | int | Must be finite and > 0 to count filled |
| itemName | String | Display |
| instanceId | String? | Optional; not required for fill status |

### FinishGap

| Field | Type | Notes |
| ----- | ---- | ----- |
| category | FinishCategory | |
| status | FinishGapStatus | |
| coveringSetId / Name / Mode | nullable | From preferred attachment |
| emptySlots | List\<String\> | Required slots still empty |
| filledSlotCount | int | |
| requiredSlotCount | int | Armor 5, weapon 3, mod 1 |
| resolvedClaimCount | int | Filled claims in required slots |
| canCapture | bool | true only for capture_available |

### FinishGapsResult

| Field | Type | Notes |
| ----- | ---- | ----- |
| variantId | String | Echo |
| isDefaultVariant | bool | Echo only; no math impact |
| complete | bool | All gaps satisfied |
| gaps | List\<FinishGap\> | Order armor → weapon → mod |
| nextActionable | FinishGap? | Skip-aware first unsatisfied |

### FinishWalkthroughStep

| Wire | Notes |
| ---- | ----- |
| `overview` | No actionable gap |
| `category` | Create/capture or snapshot category |
| `fill` | Auto-enter fill for live covering |
| `armor_optimize` | Live armor covering path |
| `done` | Reserved (TS type; not produced by resolvePostMutationStep today) |

### FinishPostMutationTarget

| Field | Type | Notes |
| ----- | ---- | ----- |
| step | FinishWalkthroughStep | |
| fillSlot | String? | When step is fill |
| category | FinishCategory? | |

No new persistent entities. No DB records.
