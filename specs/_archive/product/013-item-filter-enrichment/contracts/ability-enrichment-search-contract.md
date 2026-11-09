# Contract: Ability Enrichment Search

**Feature**: 013-item-filter-enrichment  
**Type**: Manifest search API + minimal debug filter controls for enriched abilities  
**Auth**: Unchanged (same as existing `/api/manifest/search`)  
**Updated**: 2026-07-08 (post-clarify)

## Purpose

Expose structured **class**, **subclass affinity**, **element**, and **effect verb** enrichment on abilities, and support AND-combined advanced filters so lookups matching Phoenix Dive and Chaos Reach succeed without exact-name knowledge (FR-001–FR-011).

## Endpoint

### GET `/api/manifest/search`

#### Query parameters

| Param | Required | Values | Notes |
|-------|----------|--------|-------|
| `category` | no (default `weapons`) | existing + **`abilities`** | Must include `abilities` |
| `q` | conditional | string 0–80 | Empty allowed for ability browse when category supports it; otherwise require `q` or ≥1 structured filter |
| `kind` | no | `super` \| `grenade` \| `melee` \| `classAbility` \| `movement` | Abilities only |
| `classType` | no | `Titan` \| `Hunter` \| `Warlock` | Abilities (and other scoped categories); **includes shared** (`classType` null) when set |
| `element` | no | `Kinetic` \| `Arc` \| `Solar` \| `Void` \| `Stasis` \| `Strand` \| `Prismatic` | Equality filter |
| `subclass` | no | Subclass display name (e.g. `Dawnblade`, `Stormcaller`, `Prismatic Warlock`) | Membership in `subclassAffinities`; Prismatic MUST be class-qualified |
| `verb` | no | Curated verb or alias (e.g. `Cure`, `Jolt`, `Suppress`) | Resolved to canonical; membership in `verbs` |
| `slot` | no | Kinetic \| Energy \| Power | Unchanged; weapons only |
| `limit` | no | 1–50 | Existing browse default 50 when empty `q`; search default 8 when `q` set |

**Validation**:

- Unknown enum values → `400` with issue message.
- When `category=abilities` and neither `q` nor any of `kind`/`classType`/`element`/`subclass`/`verb` is provided → prefer browse-all (existing empty-search behavior) or `400` if browse is disabled for that deployment; contract tests MUST document the chosen behavior consistently with current route.
- `subclass` / `verb` on non-ability categories → `400` or ignored consistently (prefer `400` for explicit misuse).

#### Filter semantics (abilities)

| Rule | Behavior |
|------|----------|
| Combination | **AND** across all provided structured dimensions |
| `q` + filters | Text match first (or over-fetch / browse), then apply structured filters |
| Class + shared | `classType=X` matches records with `classType === X` **or** `classType == null` |
| Empty enrichment | Empty `verbs` / `subclassAffinities` fail positive `verb` / `subclass` filters |
| Verb aliases | `Suppress` matches abilities tagged `Suppression` |
| Prismatic subclass | Filter value `Prismatic Warlock` (etc.); bare `Prismatic` is not a valid subclass affinity |
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

### Class filter includes shared

```http
GET /api/manifest/search?category=abilities&classType=Warlock&kind=grenade
```

Expect Warlock-exclusive grenades **and** shared grenades (`classType` null); exclude Titan-/Hunter-only grenades.

### Negative cases

```http
GET /api/manifest/search?category=abilities&classType=Titan&verb=Cure
```

Must **not** include Phoenix Dive.

```http
GET /api/manifest/search?category=abilities&subclass=Voidwalker&q=Phoenix
```

Must **not** include Phoenix Dive when affinities exclude Voidwalker.

## Debug UI contract (minimal)

Existing ability/subclass debug surface (`SubclassStructuredForm` or adjacent) MUST expose simple controls that set:

| UI control | Query param |
|------------|-------------|
| Class (may be derived from subclass scope) | `classType` |
| Element (may be derived from subclass scope) | `element` |
| Ability kind | `kind` |
| Subclass affinity (optional free/select) | `subclass` |
| Effect verb (optional free/select from curated list) | `verb` |
| Text search | `q` |

Results MUST show enough enrichment (`name`, and when available `verbs` / `subclassAffinities`) to verify FR-006/FR-007 without using only the network tab.

## Record contract (entity store)

`AbilityRecord` MUST include `subclassAffinities: string[]` and `verbs: string[]` after extract. Consumers (resolver, search route, debug pickers) MUST treat missing arrays as empty only during migration; new extracts always write arrays.

## Non-goals

- Full production / polished multi-select filter chrome.
- Aspect/fragment structured subclass/verb filters in this contract version.
- Changing synergy CRUD APIs.
