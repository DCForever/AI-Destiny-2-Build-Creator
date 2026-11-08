# Data Model: Soft Guidance & Coverage Indicators

**Feature**: 017-soft-guidance  
**Spec**: [spec.md](./spec.md)

## Ephemeral entities (evaluate-on-read)

### SynergyCoverage

| Field | Notes |
|-------|-------|
| `synergyId` | Designated synergy |
| `tier` | `supported` \| `weak` \| `missing` |
| `matchedLinks` / `unmatchedLinks` | Evidence link ids/summaries |
| `hint` | Optional advisory |

### SetBonusSoftRow

| Field | Notes |
|-------|-------|
| `setName` / `armorSetHash` | Set identity |
| `pieceCount` | Armor claims in set |
| `activeBonuses` | e.g. 2pc/4pc active |
| `supportedSynergyIds` | Designated synergies that care |
| `status` | `active` \| `partial` \| `inactive` |
| `hint` | Optional |

### ElementSoftMismatch

| Field | Notes |
|-------|-------|
| `slot` | Weapon slot |
| `weaponElement` / `subclassElement` | Compared elements |
| `hint` | Soft advisory |

## Persistence

None new. Inputs: resolved `SlotClaim`s, designated synergies+links, set-bonus store, weapon element metadata, build subclass.

## Out of model (slice 5)

Soft-stat targets and below-target warnings.
