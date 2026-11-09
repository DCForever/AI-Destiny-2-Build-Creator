# Data Model: Description Search for Pickers

**Feature**: 009-description-search  
**Extends**: Manifest records in `src/lib/manifest/types/records.ts`, picker DTOs from 006-synergy-refinement, catalog types from 008-sets-catalog-lookup

## Entities

### Searchable Text Fields (projection)

Logical fields concatenated for matching—not persisted.

| Entity type | `name` | `searchName` | `description` | Additional searchable text |
|-------------|--------|--------------|-----------------|---------------------------|
| Weapon perk | ✓ | ✓ | ✓ | — |
| Origin trait | ✓ | ✓ | ✓ | — |
| Set bonus (family) | ✓ | ✓ | — | tier perk `name`, tier perk `description` |
| Ability / verb | ✓ | — | ✓ | verb glossary text |
| Exotic weapon | ✓ | ✓ | — | `intrinsic.name`, `intrinsic.description` |
| Exotic armor | ✓ | ✓ | — | `intrinsic.name`, `intrinsic.description` |
| Mod / aspect / fragment / artifact | ✓ | ✓ | ✓ | — |
| Synergy record | composed `name` | — | linked entity `description` | — |

**Validation**: All text normalized to lowercase for comparison; null/empty description skipped in match but row still returned on name match.

---

### Description Match Result (derived)

Output of `matchDescriptionQuery`.

| Field | Type | Notes |
|-------|------|-------|
| matched | boolean | true if any configured field contains query substring |
| matchField | `'name' \| 'description' \| 'other'` | Highest-priority field that matched; used for sort rank |
| matchedTexts | string[]? | Optional debug: which fields hit (tests only) |

---

### Entity Scope (configuration)

Maps a picker/filter/surface to allowed entity types and field list.

| Scope ID | Allowed stores / surfaces | FR reference |
|----------|---------------------------|--------------|
| `weapon_perk` | `weapon-perks` store, links picker, `perk` filter | FR-001, FR-018 |
| `origin_trait` | `origin-traits` store, links picker, `originTrait` filter | FR-002 |
| `armor_set_bonus` | `set-bonuses` store, links picker, `setBonus` filter | FR-012, FR-015 |
| `synergy_subtype` | subtypes picker vocabularies | FR-003 |
| `catalog_weapon_browse` | catalog `q` on weapons route | FR-017, FR-019 |
| `catalog_armor_browse` | catalog `q` on armor route | FR-017 |
| `manifest_store` | per `category` param on manifest search | FR-014 |

**Rule**: A surface MUST NOT return entities outside its scope even if descriptions share keywords (FR-018).

---

### Picker Item DTO (unchanged shape, enriched usage)

Existing `SynergyPickerItem` and subtype `option` objects already include `description: string`. This feature requires:

| Field | Requirement |
|-------|-------------|
| name | Always present |
| description | Present when source record has text; empty string → UI shows "Description unavailable" |
| hash | When applicable for link build |

**UI projection**: Result list displays `name` + `description` (truncated) before selection.

---

### Catalog Searchable Row (extended projection)

Extends internal `SearchableCatalogRow` in `filterItems.ts` (not public API field unless added to response).

| Field | Type | Notes |
|-------|------|-------|
| … | | Existing catalog fields |
| intrinsicName | string? | Exotic weapons/armor only |
| intrinsicDescription | string? | Exotic weapons/armor only — Fuse key for `q` |

**Validation**: Legendary weapons have no intrinsic description in scope for `q` (FR-019).

---

### Filter Resolution (extended behavior)

`PerkFilterResolution`, `OriginTraitFilterResolution`, `SetBonusFilterResolution` unchanged shape; resolution logic expands candidate sets:

| Resolver | Previous match | New match |
|----------|----------------|-----------|
| `resolvePerkFilter` | name/searchName | + `description` |
| `resolveOriginTraitFilter` | name/searchName | + `description` |
| `resolveSetBonusFilter` | set name/searchName | + tier perk name/description |

**OR semantics**: Multiple perk hashes from description matches union into `weaponHashes` (unchanged structure).

---

## State Transitions

N/A — read-only search; no persisted state.

## Relationships

```text
User query (q)
    → Entity scope config
        → Searchable field projection (manifest record)
            → Description match result
                → Ranked result list DTO
                    → UI selection → existing link/filter apply (006/008)
```
