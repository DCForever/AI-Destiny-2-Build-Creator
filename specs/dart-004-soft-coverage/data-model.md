# Data Model: DART-004 Soft Coverage

## Reused (DART-002)

| Type | Role |
| ---- | ---- |
| `SlotClaim` | Equipment claims for match/estimate |
| `Synergy` / `SynergyLink` / `SynergyLinkKind` | Evidence links |
| `CoverageTier` / `SynergyCoverageRow` / `SetBonusSoftRow` / `ElementSoftMismatch` / `CoverageResult` | Soft result tree |
| `ArmorStatName` / `SoftStatTargets` / `StatEstimate` / `SoftStatWarningRow` | Soft stats |
| `EquipmentSlot` | Slot enums |
| `SynergyTypeDesignation` | Nudge source |
| `HardBlock` / `ConstraintEvaluation` | Contrasting hard surface (not emitted by soft APIs) |

## New this slice

### SetBonusRecord

| Field | Type | Notes |
| ----- | ---- | ----- |
| hash | int | Armor set hash |
| name | String | Display name |
| perks | List\<SetBonusPerk\> | 2pc/4pc thresholds |

### SetBonusPerk

| Field | Type |
| ----- | ---- |
| requiredCount | int |
| name | String |

### CoverageEvalInput

| Field | Type | Notes |
| ----- | ---- | ----- |
| claims | List\<SlotClaim\> | Required |
| synergies | List\<Synergy\> | Designated synergies with links |
| subclassElement | String? | Preferred resolved element |
| subclass | Map\<String, Object?\>? | Optional TS-like record for heuristic |
| setBonusByItemHash | Map\<int, SetBonusRecord\>? | itemHash → set |
| weaponElementByHash | Map\<int, String\>? | itemHash → element name |
| softStatTargets | SoftStatTargets | Default empty |
| statEstimate | StatEstimate? | Optional; enables softStats |

### StatNudge

| Field | Type |
| ----- | ---- |
| stat | ArmorStatName |
| suggested | int (default 100) |
| reason | String |
| synergyId | String? |

### SoftStatTargetsException

| Field | Type |
| ----- | ---- |
| code | String (`INVALID_ITEM`) |
| message | String |

## Constants

- `armorStatMax` / `STAT_MAX` = 200
- Armor slots for set count / estimate: 5 combat armor slots
- Weapon slots for element soft: primary, special, heavy
