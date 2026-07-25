# Data model: DART-008 Optimizer Core

Pure in-memory types only (no persistence).

## CandidatePiece

| Field | Type | Notes |
| ----- | ---- | ----- |
| slot | EquipmentSlot (armor) | helmet/arms/chest/legs/class_item |
| itemHash | int | Bungie item hash |
| instanceId | String | Stable owned instance id |
| itemName | String? | Optional display |
| isExotic | bool | Contributes to exotic count |
| setBonusKey | String? | Armor set-bonus family key |
| statValues | Map&lt;ArmorStatName, int&gt; | Partial ok; incomplete estimate if missing any of six |
| energyCapacity | int | Carried for later mod estimate; unused by core this slice |
| usedInSets | List&lt;ReuseSetRef&gt; | Other sets using instance; reuse count derived elsewhere |

## ReuseSetRef

| Field | Type |
| ----- | ---- |
| id | String |
| name | String |

## SetBonusCoverageGoal

| Field | Type | Notes |
| ----- | ---- | ----- |
| setBonusKey | String | Non-empty |
| minPieces | int | 2 or 4 in product schema; core treats as min count |

## KitConstraints

| Field | Type | Notes |
| ----- | ---- | ----- |
| lockedExoticItemHash | int? | Must appear in kit when set |
| requireExotic | bool? | At least one exotic when true |
| setBonusGoals | List&lt;SetBonusCoverageGoal&gt;? | All goals must be met |

## EnumerateResult

| Field | Type |
| ----- | ---- |
| kits | List&lt;List&lt;CandidatePiece&gt;&gt; |
| evaluatedCount | int |
| truncated | bool |

## RankableCombination

| Field | Type |
| ----- | ---- |
| estimatedStats | Map&lt;ArmorStatName, int&gt; |
| reusePieceCount | int |

## SetBonusSummaryEntry

| Field | Type |
| ----- | ---- |
| setBonusKey | String |
| pieceCount | int |
| active2pc | bool |
| active4pc | bool |

## Constants

| Name | Value |
| ---- | ----- |
| defaultMaxCombinations | 250_000 |
| defaultPruneK | 16 |
