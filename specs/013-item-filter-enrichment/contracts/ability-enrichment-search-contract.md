# Contract: Ability Enrichment Search

**Feature**: 013-item-filter-enrichment  
**Type**: Manifest search API extension for enriched abilities  
**Auth**: Unchanged (same as existing `/api/manifest/search`)

## Purpose

Expose structured **class**, **subclass affinity**, **element**, and **effect verb** enrichment on abilities, and support AND-combined advanced filters so lookups matching Phoenix Dive and Chaos Reach succeed without exact-name knowledge (FR-001–FR-011).

## Endpoint

### GET `/api/manifest/search`

#### Query parameters

| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| `category` | no (default `weapons`) | existing + **`abilities`** | Must include `abilities` |
| `q` | conditional | string 1–80 | Required unless ≥1 structured filter is set when `category=abilities` |
| `kind` | no | `super` \| `grenade` \| `melee` \| `classAbility` \| `movement` | Abilities only |
| `classType` | no | `Titan` \| `Hunter` \| `Warlock` | Abilities only; excludes shared (`null`) when set |
| `element` | no | `Kinetic` \| `Arc` \| `Solar` \| `Void` \| `Stasis` \| `Strand` \| `Prismatic` | Abilities only |
| `subclass` | no | Subclass display name (e.g. `Dawnblade`, `Stormcaller`, `Prismatic Warlock`) | Membership in `subclassAffinities` |
| `verb` | no | Curated verb or alias (e.g. `Cure`, `Jolt`, `Suppress`) | Resolved to canonical; membership in `verbs` |
| `slot` | no | Kinetic \| Energy \| Power | Unchanged; weapons only |
| `limit` | no | 1–20 (default 8) | Unchanged |

**Validation**:

- Unknown enum values → `400` with issue message.
- When `category=abilities` and neither `q` nor any of `kind`/`classType`/`element`/`subclass`/`verb` is provided → `400`.
- Structured filters on non-ability categories → `400` or ignored consistently (prefer `400` for explicit misuse).

#### Filter semantics (abilities)

| Rule | Behavior |
|------|----------|
| Combination | **AND** across all provided structured dimensions |
| `q` + filters | Text match first (or over-fetch), then apply structured filters |
| Empty enrichment | Empty `verbs` / `subclassAffinities` fail positive `verb` / `subclass` filters |
| Verb aliases | `Suppress` matches abilities tagged `Suppression` |
| Empty results | `200` with `results: []` (not an error) |

#### Response (`category=abilities`)

```json
{
  "results": [
    {
      "name": "Chaos Reach",
      "hash": 1018,
      "icon": "/common/destiny2_content/icons/...",
      "description": "Unleash a long-range Arc beam.",
      "kind": "super",
      "classType": "Warlock",
      "element": "Arc",
      "subclassAffinities": ["Stormcaller"],
      "verbs": ["Jolt"],
      "confidence": 1
    }
  ]
}
```

Non-ability categories retain existing response shape (no breaking removal of fields).

## Acceptance query examples

### Phoenix Dive (no name)

```http
GET /api/manifest/search?category=abilities&classType=Warlock&verb=Cure&subclass=Dawnblade
```

Expect Phoenix Dive in `results` with `verbs` containing `Cure` and affinities including `Dawnblade` and `Prismatic Warlock`.

```http
GET /api/manifest/search?category=abilities&classType=Warlock&verb=Cure&subclass=Prismatic%20Warlock
```

Same item included.

### Chaos Reach (no name)

```http
GET /api/manifest/search?category=abilities&kind=super&subclass=Stormcaller&element=Arc&verb=Jolt
```

Expect Chaos Reach with `element: "Arc"` and `verbs` containing `Jolt`.

### Negative cases

```http
GET /api/manifest/search?category=abilities&classType=Titan&verb=Cure
```

Must **not** include Phoenix Dive.

```http
GET /api/manifest/search?category=abilities&subclass=Voidwalker&q=Phoenix
```

Must **not** include Phoenix Dive when affinities exclude Voidwalker.

## Record contract (entity store)

`AbilityRecord` MUST include `subclassAffinities: string[]` and `verbs: string[]` after extract. Consumers (resolver, search route, debug pickers) MUST treat missing arrays as empty only during migration; new extracts always write arrays.

## Non-goals

- Production filter chrome beyond debug/search verification.
- Aspect/fragment structured subclass/verb filters in this contract version.
- Changing synergy CRUD APIs.
