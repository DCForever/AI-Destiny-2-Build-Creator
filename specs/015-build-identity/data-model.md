# Data Model: Build Identity & Default Completeness

**Feature**: 015-build-identity  
**Date**: 2026-07-10  
**Spec**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

## Entities

### Build (evolved)

| Field | Type | Identity? | Notes |
|-------|------|-----------|-------|
| `id` | uuid | — | PK |
| `userId` | string | — | Owner |
| `name` | string | No | Derived or user; unique per `(userId, className)` |
| `className` | Titan \| Hunter \| Warlock | No* | Class-bound; *required for uniqueness scope |
| `subclass` | object | Partial | Shared tree/kit JSON; Super pin is separate |
| `exoticArmorHash` | number \| null | **Yes when set** | Item hash; null = no exotic armor identity |
| `exoticArmorName` | string \| null | — | Display |
| `exoticWeaponHash` | number \| null | **Yes when set** | **NEW** build-shared weapon; null = variant-level |
| `exoticWeaponName` | string \| null | — | **NEW** |
| `pinnedSuper` | string \| null | **Yes when set** | **NEW**; null = Super not identity |
| `synergyIds` | uuid[] (≥1) | **Yes** | Primary identity via junction |
| `tagIds` | string[] | **No** | Filter-only; changes never identity edits |

### Build Variant (evolved)

| Field | Type | Notes |
|-------|------|-------|
| `id` | uuid | PK |
| `buildId` | uuid | FK |
| `name` | string | User label |
| `isDefault` | boolean | Exactly one true per build |
| `exoticWeaponHash` | number \| null | Used when build-level weapon is null |
| `exoticWeaponName` | string \| null | |
| `notes` | string \| null | Not identity |
| attachments | set links | Live/snapshot; fork clones as snapshot |

### Identity Edit Decision (ephemeral)

Not persisted. Request carries `identityAction: "confirm" | "fork"` when identity fields change.

### Designated Synergy

Unchanged entity; ≥1 required on Build (`NO_SYNERGY`).

### Concept Tag

Unchanged vocabulary; Build association is filter metadata only.

## Relationships

```text
User 1──* Build
Build 1──* BuildVariant (exactly one isDefault)
Build *──* Synergy (designated, ≥1)
Build *──* ConceptTag (0..n, not identity)
BuildVariant *──* SetAttachment
```

## Validation rules

| Rule | When | Outcome |
|------|------|---------|
| ≥1 synergy | create/update synergies | `NO_SYNERGY` |
| Default full loadout | save default variant with attachments/resolve | `DEFAULT_VARIANT_INCOMPLETE` + missing slots |
| Non-default empty OK | save non-default | Allowed even with zero combat slots |
| Identity change without action | PATCH identity fields | `IDENTITY_CONFIRM_REQUIRED` |
| Duplicate name per class | create/rename | `DUPLICATE_BUILD_NAME` |
| Exotic limits | resolve/save | Existing exotic conflict rules; null armor skips pair armor match |

## State transitions

### Identity mutation

```text
[stable] --PATCH identity fields--> [needs action]
[needs action] --identityAction=confirm--> [stable, same build id]
[needs action] --identityAction=fork--> [original stable] + [new build with new identity]
[stable] --PATCH tags/name only--> [stable] (no action)
```

### Default completeness

```text
[default incomplete] --fill all required slots+mods--> [default complete]
[default incomplete] --save as complete--> REJECT
[non-default incomplete] --save--> OK
```

## Migration notes

1. Alter `builds.exotic_armor_hash` / `exotic_armor_name` to nullable (table rebuild if SQLite requires).
2. Add `exotic_weapon_hash`, `exotic_weapon_name`, `pinned_super` nullable columns.
3. Backfill: existing builds keep armor hashes; weapon/super pins null (variant-level / unpinned behavior).
4. No data loss expected for existing rows.

## Out of model (later slices)

Instance pins, wishlist rolls, artifacts, fashion equip fields, soft stat targets, class-item intent allow-lists.
