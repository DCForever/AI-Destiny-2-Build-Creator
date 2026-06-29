# Data Model: Exotic Loadouts by Type

**Updated**: 2026-06-29

## Overview

No new persistence tables. Feature adds **derived views** and **filter criteria** over existing **`SavedLoadout`** records (`loadouts` table). Classification reads `resolvedSheet` (and `buildRequest.className` for class scoping).

## Persisted Entity (unchanged)

### SavedLoadout

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | |
| userId | integer FK | FR-009 scope |
| name | text | |
| source | enum | generator \| analyzer \| manual-edit |
| manifestVersion | text | |
| buildRequest | JSON optional | `className` for armor class scoping |
| generatedBuild | JSON | |
| resolvedSheet | JSON | **Source for exotic classification** |
| createdAt, updatedAt | text | |

Relevant `resolvedSheet` subtrees:

- `exoticArmor`: `{ requestedName, resolved?: { hash, name }, status }`
- `weapons[]`: `{ slot, isExotic, reference: { requestedName, resolved? } }`

## Derived Entities

### LoadoutExoticSummary

Projection attached to list API responses and used in UI row labels.

| Field | Type | Notes |
|-------|------|-------|
| loadoutId | text | |
| className | `DestinyClassName` | from `buildRequest` or default |
| exoticArmor | object \| null | see below |
| exoticWeapon | object \| null | see below |

**exoticArmor** (when present):

| Field | Type | Notes |
|-------|------|-------|
| hash | number \| null | resolved hash |
| name | text | display: resolved name or requestedName |
| slot | `ArmorSlotName` \| null | from manifest when hash resolves |
| classType | `DestinyClassName` \| null | from manifest |
| status | `ResolutionStatus` | verified \| fuzzy \| unresolved |

**exoticWeapon** (when `isExotic` weapon exists):

| Field | Type | Notes |
|-------|------|-------|
| hash | number \| null | |
| name | text | |
| slot | `WeaponSlotName` | Kinetic \| Energy \| Power |
| status | `ResolutionStatus` | |

**Validation**: At most one exotic weapon per loadout sheet. Armor exotic always attempted; null when genuinely absent from sheet.

### ExoticFilterCriteria

In-memory / query-string filter. Armor and weapon dimensions are **independent** (FR-006).

| Field | Type | Notes |
|-------|------|-------|
| armor | ArmorExoticFilter \| null | null = no armor constraint |
| weapon | WeaponExoticFilter \| null | null = no weapon constraint |

### ArmorExoticFilter

| Field | Type | Notes |
|-------|------|-------|
| mode | `exact` \| `slot` | |
| hash | number | required when mode=exact (preferred) |
| name | text | optional fallback for exact when hash omitted |
| slot | `ArmorSlotName` | required when mode=slot |

**Matching rules**:
- `exact`: summary armor hash matches, OR normalized names match when hash missing
- `slot`: summary armor slot matches AND `classType` matches loadout `className`

### WeaponExoticFilter

| Field | Type | Notes |
|-------|------|-------|
| mode | `exact` \| `slot` | |
| hash | number | required when mode=exact |
| name | text | optional fallback |
| slot | `WeaponSlotName` | required when mode=slot |

**Matching rules**:
- `exact`: weapon hash or name match
- `slot`: exotic weapon exists and slot matches

### LoadoutFilterState (UI)

Client state mirroring `ExoticFilterCriteria` plus UX fields:

| Field | Type | Notes |
|-------|------|-------|
| criteria | ExoticFilterCriteria | |
| source | `list` \| `context` | whether filter set from bar or sheet action |
| contextLoadoutId | text optional | loadout that triggered contextual discovery |

## State Transitions

```text
[All loadouts] --apply armor/weapon filter--> [Filtered subset]
[Filtered] --clear armor OR weapon OR all--> [All or partial filter]
[Sheet open] --"same exotic" / "same slot"--> [Filtered subset + list scroll]
```

All transitions are **read-only** — no loadout mutation (FR-004, assumptions).

## Relationships

```text
User 1--* SavedLoadout
SavedLoadout --derives--> LoadoutExoticSummary (via classifyExotics + manifest)
ExoticFilterCriteria --selects--> subset of SavedLoadout
```

## Index / Query Notes

v1: load all user loadouts ordered by `updatedAt`; filter in application code. Future pagination may add denormalized exotic hash columns if lists exceed ~200 rows.
