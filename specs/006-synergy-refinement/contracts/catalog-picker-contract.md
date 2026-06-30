# Contract: Synergy Catalog Pickers

**Feature**: 006-synergy-refinement  
**Type**: Read-only catalog API for debug synergy form  
**Auth**: Same as `/api/catalog/*` (manifest loaded; no user write)

## Purpose

Supply searchable lists for synergy **sub-types** and **link targets** so the debug UI never uses free-text or raw hash entry (FR-012).

## Endpoints

### GET `/api/catalog/synergy-pickers/subtypes`

**Query**:

| Param | Required | Values |
|-------|----------|--------|
| category | yes | `verb` \| `melee` \| `grenade` \| `super` \| `element` \| `weapon_archetype` |
| q | no | case-insensitive substring on `name` |
| limit | no | default 2000 when `q` empty, 50 when filtering; max 2000 |

**Response 200**:

```json
{
  "category": "melee",
  "options": [
    { "id": "base", "name": "Base", "description": "Applies to all melee abilities." },
    { "id": "1020", "name": "Storm Fist", "description": "Arc charged melee attack." }
  ]
}
```

**Sources** (see [research.md](../research.md)):

- `verb` → deduplicated `subclasses.meta` verbs
- `melee` \| `grenade` \| `super` → `Base` + manifest `abilities` filtered by kind, deduplicated by display name
- `element` → fixed seven elements (includes Kinetic)
- `weapon_archetype` → deduplicated legendary weapon types (`itemTypeDisplayName`) and frames (manifest intrinsic sockets ending in ` Frame`)

**Errors**: 400 invalid category; 503 manifest not loaded.

---

### GET `/api/catalog/synergy-pickers/links`

**Query**:

| Param | Required | Values |
|-------|----------|--------|
| kind | yes | `origin_trait` \| `weapon_perk` \| `armor_set_bonus` |
| q | no | case-insensitive substring on name |
| limit | no | default 2000 when `q` empty, 50 when filtering; max 2000 |

**Response 200**:

```json
{
  "kind": "origin_trait",
  "items": [
    {
      "kind": "origin_trait",
      "hash": 9001,
      "name": "Cast No Shadows",
      "description": "...",
      "originTraitName": "Cast No Shadows"
    }
  ]
}
```

**Kind-specific fields**:

| kind | Extra fields for link build |
|------|----------------------------|
| `origin_trait` | `originTraitName`, `originTraitHash` |
| `weapon_perk` | `perkHash`, optional `parentItemHash` |
| `armor_set_bonus` | Flattened rows: `armorSetName`, `bonusPieces`, `bonusName`, `armorSetHash`, `description` (bonus text) |

**Note**: `weapon` links use existing **`GET /api/catalog/weapons?q=&limit=`** — items include `hash`, `name`, `description` from catalog projection.

---

## SynergyLink build (client)

After picker selection, client sends standard `SynergyLink` body to `POST /api/user/synergies` — no picker-specific fields persisted beyond link schema.

## Description preview (FR-014)

Debug UI MUST render `description` from the selected picker row (weapons catalog item or picker `items[]` entry) read-only before submit.

## Performance

- Responses SHOULD return within 2s with manifest cached.
- Server-side filter + limit; no full-store client download.

See [synergy-refinement-contract.md](./synergy-refinement-contract.md).
