# Data Model: Build Sets and Synergies

**Updated**: 2026-06-28

## Overview

Extends SQLite (Drizzle) with first-class **Builds** (parent) and **BuildVariants** (equipment composition via attached Sets). Sets are typed collections with **slot-scoped items** and **concept tags** from a controlled vocabulary (`src/data/conceptTags.ts`). Synergies link to builds for suggestion weighting (equal when multiple).

Equipment slots (canonical enum):

| Domain | Slots |
|--------|-------|
| Weapon | `primary`, `special`, `heavy` |
| Armor | `helmet`, `arms`, `chest`, `legs`, `class_item` |
| Pair | `exotic_weapon`, `exotic_armor` |

Logical slots for variant resolution map manifest buckets to the above. Mods are optional metadata on armor slots or via Mod Sets.

## Entities

### Set

User-curated collection with a user-defined name and zero or more concept tags.

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | uuid/cuid |
| userId | integer FK → users | |
| name | text | user-defined; unique per (userId, type) |
| type | enum | `weapon` \| `armor` \| `mod` \| `pair` \| `fashion` |
| createdAt | text ISO | |
| updatedAt | text ISO | |

**Validation**: FR-005 name uniqueness per (userId, type); FR-004/029 tag validation; fashion excluded from functional resolution (FR-018).

### SetTag (junction)

| Field | Type | Notes |
|-------|------|-------|
| setId | text FK → sets | |
| tagId | text | `ConceptTagId` from controlled vocabulary |

**Validation**: tagId MUST exist in `conceptTags.ts` enum (FR-029). Zero tags allowed.

### SetItem

Item occupying one slot within a set.

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | |
| setId | text FK → sets | |
| slot | enum | slot valid for parent set type |
| itemHash | integer | Bungie manifest hash |
| itemName | text | denormalized display |
| selectedPerks | text JSON | perk plug hashes (weapons) |
| masterworkHash | integer nullable | |
| modHashes | text JSON nullable | armor/mods |
| sortOrder | integer | display |
| removedAt | text nullable | soft-remove; roll retained for history UI |

**Validation**:
- At most one **active** row per (setId, slot) where `removedAt IS NULL` (FR-020).
- Replace flow: confirm in UI, then UPDATE row or INSERT after soft-delete previous (FR-027).
- Weapon perks validated against manifest sockets on save.

### Synergy

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | |
| userId | integer FK | |
| name | text | |
| type | enum | melee, verb, grenade, primary-weapon, … |
| description | text | |
| elements | text JSON | optional item/set/name references |
| createdAt, updatedAt | text | |

### Build

Parent configuration shared by variants.

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | |
| userId | integer FK | |
| name | text | |
| className | enum | Titan, Hunter, Warlock |
| subclass | text JSON | aspects, fragments, abilities (subset of GeneratedBuild subclass) |
| exoticArmorHash | integer | build-level exotic armor |
| exoticArmorName | text | |
| createdAt, updatedAt | text | |

**Validation**: FR-022 — must have default variant with ≥1 slot filled before save completes; FR-024 — ≥1 synergy in `build_synergies`; FR-030 — concept tags via `build_tags`.

### BuildTag (junction)

| Field | Type | Notes |
|-------|------|-------|
| buildId | text FK → builds | |
| tagId | text | `ConceptTagId` from controlled vocabulary |

**Validation**: tagId MUST exist in `conceptTags.ts` enum (FR-029/030).

### BuildVariant

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | |
| buildId | text FK → builds | |
| name | text | e.g. `Default`, `DPS` |
| isDefault | integer boolean | exactly one per build |
| exoticWeaponHash | integer nullable | per-variant exotic weapon |
| exoticWeaponName | text nullable | |
| createdAt, updatedAt | text | |

**Validation**: FR-025 — resolved slot map must have ≥1 equipment slot before save.

### BuildSynergy (junction)

| Field | Type | Notes |
|-------|------|-------|
| buildId | text FK | |
| synergyId | text FK | |
| attachedAt | text | |

**Validation**: ≥1 row per build for save (FR-024). All rows weighted equally in suggestions.

### VariantSetAttachment

| Field | Type | Notes |
|-------|------|-------|
| id | text PK | |
| variantId | text FK → build_variants | |
| setId | text FK → sets | |
| mode | enum | `live` \| `snapshot` |
| snapshotConfigs | text JSON nullable | frozen slot→{itemHash, selectedPerks, …} |
| attachedAt | text | |

**Validation**:
- Pair Set: `exotic_armor` in resolved set must match `builds.exoticArmorHash` (FR-028).
- Deleting Set blocked if any attachment exists (FR-017).
- Cross-set slot conflicts block variant save (FR-026).

### ResolvedVariantEquipment (computed, not stored)

Service output merging variant attachments + variant exotic weapon + build exotic armor into slot map for UI/sheet export.

## Tag Filter Queries (AND semantics)

To list sets matching tags `[solar, melee]` (FR-031):

1. For each tagId, select `set_id` from `set_tags`.
2. Intersect result sets → entities with **all** tags.
3. Join to `sets` scoped by `userId`; optional `type` filter.

Same pattern for `build_tags` when filtering builds.

## Relationships

```text
User 1──* Set 1──* SetItem
Set *──* ConceptTag (via set_tags)
User 1──* Synergy
User 1──* Build 1──* BuildVariant 1──* VariantSetAttachment *──1 Set
Build *──* ConceptTag (via build_tags)
Build *──* Synergy (via BuildSynergy)
```

## State Transitions

| Entity | Lifecycle |
|--------|-----------|
| Set | create → assign tags → add/edit items (slot replace with confirm) → delete if unattached |
| Build | create + default variant → assign tags + synergies → save when variant valid |
| BuildVariant | create → attach/detach sets → save when ≥1 slot + no conflicts |
| VariantSetAttachment | attach (live default) → optional switch to snapshot → detach |

## Indexes

- `sets(user_id, type, name)` unique
- `set_tags(tag_id, set_id)` — supports AND intersection queries
- `set_tags(set_id)`
- `build_tags(tag_id, build_id)`
- `build_tags(build_id)`
- `set_items(set_id, slot)` unique partial where active
- `build_variants(build_id)`
- `variant_set_attachments(variant_id)`
- `build_synergies(build_id)`

## Integration with Existing Models

- **`loadouts`**: unchanged in P1–P3; future task may export a variant to `SavedLoadout` (`generatedBuild` + `resolvedSheet`).
- **`GeneratedBuild`**: build subclass JSON aligns with `generatedBuildSchema.subclass` for familiarity.
- **`conceptTags.ts`**: canonical tag vocabulary for validation, UI pickers, and filter queries.
- **Manifest**: all `itemHash` resolved via existing entity stores; validation-first (constitution V).

See [contracts/](./contracts/) for API/UI shapes and [quickstart.md](./quickstart.md) for validation flows.
