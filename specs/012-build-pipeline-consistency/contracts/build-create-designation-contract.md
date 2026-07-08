# Contract: Build Create & Synergy Designation

**Feature**: 012-build-pipeline-consistency  
**Type**: API behavior + debug Builds create/edit  
**Related**: [build-variant-contract.md](../../001-build-sets-synergies/contracts/build-variant-contract.md), [set-attachment-contract.md](../../001-build-sets-synergies/contracts/set-attachment-contract.md)

## Purpose

Tighten create/update designation rules so builds never receive **invisible** synergy seeding, and document debug create payloads produced by pickers.

## POST `/api/user/builds`

### Request (happy path)

```json
{
  "name": "Solar Titan",
  "className": "Titan",
  "subclass": {
    "name": "Sunbreaker",
    "super": "Hammer of Sol",
    "classAbility": "Towering Barricade",
    "movement": "Catapult Lift",
    "melee": "Hammer Strike",
    "grenade": "Solar Grenade",
    "aspects": ["Roaring Flames"],
    "fragments": ["Facet of Courage"],
    "rationale": "Debug pipeline"
  },
  "exoticArmorHash": 1234567890,
  "exoticArmorName": "Hallowfire Heart",
  "tagIds": ["solar", "pve"],
  "synergyIds": ["<existing-synergy-uuid>"],
  "defaultVariant": { "name": "Default" }
}
```

### 012 behavior changes

| Rule | Before | After |
|------|--------|-------|
| Missing/empty `synergyIds` | Server seeded defaults / first synergy | **400** `NO_SYNERGY` — client must designate explicitly |
| `exoticArmorName` | Optional; default `Exotic (hash)` | Still optional at API, but debug happy path **always** sets name from picker |
| Subclass | Validated zod object | Unchanged schema; debug builds object via structured form |

### Response

Unchanged build detail shape including `variants[]` and designated synergies with `id`/`name`/`type` when expanded by detail endpoint.

## PATCH `/api/user/builds/:id`

### Synergy designation update

```json
{ "synergyIds": ["id-a", "id-b"] }
```

- When `synergyIds` is present: **min 1**; replaces junction rows.
- Unknown ids → `NO_SYNERGY`.
- Debug Builds MUST expose this after create (US4).

## Variant-scoped attach (unchanged API, clarified client)

### PATCH `/api/user/builds/:id/variants/:variantId`

```json
{
  "attachments": [
    { "setId": "...", "mode": "live" },
    { "setId": "...", "mode": "snapshot" }
  ]
}
```

**Semantics**: `attachments` is a **full replacement** of that variant’s attachments. Debug UI MUST:

1. Load current attachments from build detail.
2. Apply add/update mode in memory.
3. Submit the complete array.
4. Target the **selected** variant id only.

## Manifest search extension

### GET `/api/manifest/search`

Add category:

| `category` | Store | Optional params |
|------------|-------|-----------------|
| `abilities` | `abilities` entity cache | `kind` = `super` \| `grenade` \| `melee` \| `classAbility` \| `movement` when filtering |

Response `results[]` include at least `name`, `hash`, `icon`, and `kind` when available.

Existing categories (`exotic-armor`, `aspects`, `fragments`, …) unchanged.

## Error codes (relevant)

| Code | When |
|------|------|
| `NO_SYNERGY` | Empty/missing designations on create; unknown ids; update with empty array |
| `PAIR_ARMOR_MISMATCH` | Unchanged on attach |
| `VARIANT_EMPTY` | Unchanged when saving empty equipment composition |
| `INVALID_TAG` | Unchanged |

## Debug Builds page requirements

1. Create form uses ExoticArmorLookup, SynergyMultiSelect, SubclassStructuredForm, Concept tags (existing checkboxes OK).
2. No primary-path raw exotic hash / variant id / subclass JSON.
3. VariantSelect lists all variants; variant-scoped buttons disabled without selection.
4. SetAttachPicker uses type + tag AND filters; confirm shows variant name.
5. JSON panel continues to show request/response/errors per 001 debug-service contract.
