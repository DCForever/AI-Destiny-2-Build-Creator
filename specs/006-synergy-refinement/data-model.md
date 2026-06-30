# Data Model: Synergy Refinement

**Feature**: 006-synergy-refinement  
**Date**: 2026-06-29  
**Extends**: [001-build-sets-synergies/data-model.md](../001-build-sets-synergies/data-model.md)

## Overview

Adds **sub-type** metadata to Synergy, updates the **type enum**, and documents picker DTOs. `synergy_links` unchanged (many-to-many already supported).

## Entity Changes

### Synergy (updated)

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | unchanged |
| userId | integer FK | unchanged |
| name | text | **auto-generated** on create/update from type + subType + primary link |
| type | enum | see **SynergyType** below |
| **subType** | text nullable | **NEW** — required when type requires sub-type |
| description | text | optional curator notes (unchanged) |
| createdAt, updatedAt | text ISO | unchanged |

### SynergyType (updated enum)

**Creatable values**:

```text
verb | melee | grenade | super | element |
primary_weapon | special_weapon | heavy_weapon | dps | healing
```

**Legacy (read-only, migrate on re-save)**:

| Legacy `type` | Migrates to |
|---------------|-------------|
| `kinetic_weapon` | `type: element`, `subType: Kinetic` |
| `damage` | `type: dps`, `subType: null` |

**Removed from creatable picker**: `kinetic_weapon`, `damage`

### SynergySubType (validation rules)

| type | subType required | Allowed values |
|------|------------------|----------------|
| verb | yes | Curated verb names (deduplicated); **not** `Base` |
| melee | yes | `Base` or specific ability name from `abilities` store (`kind: melee`) |
| grenade | yes | `Base` or specific grenade name |
| super | yes | `Base` or specific super name |
| element | yes | `Kinetic`, `Solar`, `Arc`, `Void`, `Stasis`, `Strand`, `Prismatic`; **not** `Base` |
| primary_weapon, special_weapon, heavy_weapon, dps, healing | no | must be null |

**Validation codes** (new/extended):

| Code | When |
|------|------|
| `INVALID_SYNERGY_SUBTYPE` | Missing subType when required; Base on verb/element; unknown subType value |
| `INVALID_SYNERGY_TYPE` | Creatable request uses removed type |

Link validation (`INVALID_SYNERGY_LINK`) unchanged per 001.

### SynergyLink (unchanged)

Same fields and kinds: `weapon`, `weapon_perk`, `origin_trait`, `armor_set_bonus`.

**Association**: Many-to-many — multiple synergies per target; multiple links per synergy (001).

## Derived / API Types

### AutoNameInput

```ts
{
  type: SynergyType;
  subType: string | null;
  linkDisplayName: string; // primary link displayName
}
```

### SynergyPickerItem (link picker row)

```ts
{
  kind: SynergyLinkKind;
  hash?: number;
  name: string;
  description: string;
  // kind-specific optional fields for form prefill
  originTraitName?: string;
  armorSetName?: string;
  bonusPieces?: 2 | 4;
  bonusName?: string;
  perkHash?: number;
  itemHash?: number;
}
```

### SynergySubTypeOption

```ts
{
  id: string;       // stable key, e.g. "base", "scorch", ability hash string
  name: string;     // display label ("Base", "Scorch", "Hammer of Sol")
  description?: string; // abilities/verbs only when available
}
```

## State Transitions

```text
[legacy synergy kinetic_weapon] --re-save--> [type=element, subType=Kinetic, name regenerated]
[legacy synergy damage]         --re-save--> [type=dps, subType=null, name regenerated]
[create with pickers]           --> [validated links + subType + auto name] --> persisted
```

## Indexes

No new indexes required for v1 (user-scoped synergy count ≪ 1000). Optional future: `synergies(user_id, type, sub_type)`.

## Migration

Drizzle migration: `ALTER TABLE synergies ADD COLUMN sub_type TEXT;` — nullable, no backfill (legacy rows have null subType until edited).
