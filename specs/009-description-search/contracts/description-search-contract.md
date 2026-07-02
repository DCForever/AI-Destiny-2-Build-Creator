# Contract: Description Search

**Feature**: 009-description-search  
**Type**: Cross-cutting search behavior for catalog, manifest, and synergy picker APIs  
**Auth**: Unchanged per underlying route

## Purpose

Define **consistent name + description keyword matching** and **entity scoping** across all search surfaces (FR-001–FR-019). Extends [006 catalog-picker-contract](../../006-synergy-refinement/contracts/catalog-picker-contract.md) and [008 catalog-set-lookup-contract](../../008-sets-catalog-lookup/contracts/catalog-set-lookup-contract.md) without replacing them.

## Global Match Rules

| Rule | Value |
|------|-------|
| Algorithm | Case-insensitive **substring** |
| Empty `q` | Return default list (unfiltered or capped catalog) — no error |
| Hash input | Numeric-only strings resolve by hash first; skip text match |
| Ranking | Name match before description-only match before `other` fields |
| Cross-entity | **Forbidden** in browse `q` — use scoped filter params (`perk`, `originTrait`, `setBonus`) |

### Shared module

Implementation: `src/lib/search/descriptionMatch.ts`

Tests: `src/lib/search/descriptionMatch.test.ts`

---

## Affected Endpoints

### GET `/api/catalog/synergy-pickers/links`

**Change**: `q` matches `name`, `searchName`, and `description` per kind.

| kind | Additional match fields (beyond name) |
|------|---------------------------------------|
| `weapon_perk` | `description` |
| `origin_trait` | `description` |
| `armor_set_bonus` | tier perk `description`; tier perk `name` |

**Response**: Unchanged JSON shape; `description` MUST be non-empty in items when source data provides text.

**Example**:

```http
GET /api/catalog/synergy-pickers/links?kind=weapon_perk&q=melee
```

Expect perks whose **description** contains "melee" even if name does not.

---

### GET `/api/catalog/synergy-pickers/subtypes`

**Change**: `q` matches `option.name` **and** `option.description`.

```http
GET /api/catalog/synergy-pickers/subtypes?category=melee&q=arc
```

---

### GET `/api/catalog/weapons`

**Change**:

| Param | Match fields |
|-------|--------------|
| `q` | `name`, `searchName`, `itemTypeName`, `frame`, exotic `intrinsic.name`, exotic `intrinsic.description` |
| `perk` | perk `name`, `searchName`, `description` → weapon hash allowlist |
| `originTrait` | trait `name`, `searchName`, `description` → weapon hash allowlist |

**Not in `q` scope**: rollable perk descriptions (use `perk` param).

```http
GET /api/catalog/weapons?scope=all&q=javelin
```

Expect exotic weapons whose intrinsic description mentions javelin.

```http
GET /api/catalog/weapons?perk=melee&scope=owned
```

Expect weapons rolling any perk whose name **or** description matches "melee".

---

### GET `/api/catalog/armor`

**Change**:

| Param | Match fields |
|-------|--------------|
| `q` | `name`, `searchName`, exotic intrinsic name/description |
| `setBonus` | set name, tier perk name, tier perk description → armor hash allowlist |

```http
GET /api/catalog/armor?setBonus=overshield&slot=Helmet
```

Expect sets where tier text contains "overshield" even if set name does not.

---

### GET `/api/manifest/search`

**Change**: Fuse index per store includes `description` where record has field; exotics include intrinsic description.

| category | Description search |
|----------|-------------------|
| `weapons` | N/A (legendary — name only) |
| `exotic-weapons` | intrinsic description |
| `exotic-armor` | intrinsic description |
| `mods` | mod description |
| (extended) | aspects, fragments, artifacts when category supported |

---

## UI Contract (debug)

| Surface | Requirement |
|---------|-------------|
| `/debug/synergies` | Link and subtype picker lists show `description` per row before selection |
| `/debug/catalog` | Exotic results show intrinsic description when present |
| `/debug/sets` | Inherits catalog filter description behavior |

Truncation: excerpt ≤200 chars in list; full text on hover/expand acceptable.

---

## Error / Empty States

| Condition | Response |
|-----------|----------|
| No text matches | `items: []` or `options: []` with 200; catalog filters use existing empty-filter `message` from 008 |
| Missing description on matched row | Include row; `description: ""`; UI shows unavailable indicator |

---

## Regression

- Name-only searches continue to return same results as pre-009.
- Hash-based filter params unchanged.
- Picker `limit` and sort order stable except description-rank insertion among same match tier.
