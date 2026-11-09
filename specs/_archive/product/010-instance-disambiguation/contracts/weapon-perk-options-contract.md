# Contract: Weapon Perk Options

**Feature**: 010-instance-disambiguation
**Type**: New read-only catalog endpoint
**Auth**: Same as other `/api/catalog/*` routes (no inventory required; manifest-only)

## Purpose

Provide the **available plug options per socket** for a weapon so the user can choose which perks to record when attaching a copy to a set (US4 / FR-013, clarified: all plug options the copy can hold — equipped plus swappable alternatives — not the full manifest curated roll pool). Fetched lazily at the perk-selection step.

---

## GET `/api/catalog/weapons/perk-options`

### Query parameters

| Param | Required | Type | Notes |
|-------|----------|------|-------|
| `itemHash` | yes | positive int | The weapon whose socket options are requested. |

### Response 200

```json
{
  "itemHash": 789,
  "columns": [
    { "column": 0, "options": [ { "hash": 1, "name": "Corkscrew Rifling" }, { "hash": 2, "name": "Fluted Barrel" } ] },
    { "column": 1, "options": [ { "hash": 3, "name": "Appended Mag" }, { "hash": 4, "name": "Tactical Mag" } ] },
    { "column": 2, "options": [ { "hash": 5, "name": "Zen Moment" }, { "hash": 6, "name": "Enlightened Action" } ] },
    { "column": 3, "options": [ { "hash": 7, "name": "Golden Tricorn" }, { "hash": 8, "name": "One for All" } ] }
  ]
}
```

| Field | Type | Notes |
|-------|------|-------|
| `itemHash` | number | Echoes the request. |
| `columns` | array | One entry per perk socket/column, in column order. |
| `columns[].column` | number | Socket/column index. |
| `columns[].options` | array | De-duplicated union of curated + randomized plugs the weapon can roll in that column, each `{ hash, name }`. |

### Rules

- Options are the **weapon item-level pool** (identical across copies). The client marks which option is **equipped** on the chosen copy by intersecting `options[].hash` with that copy's instance `plugs[].hash`.
- Options are scoped to the copy's rollable pool, **not** the full manifest curated pool for unrelated variants (FR-013).
- Name resolution uses the `weapon-perks` store with graceful handling of unresolved hashes (name falls back to the hash string, consistent with FR-004).

### Degradation / errors

| Condition | Response |
|-----------|----------|
| Weapon record or `perkColumns` unavailable | `200` with `columns: []` → UI falls back to selecting from the copy's equipped perks only |
| `itemHash` missing/invalid | `400` invalid request |
| itemHash is not a weapon | `200` with `columns: []` (or `404` if the route enforces weapon-kind; UI treats empty as no-options) |

## Internal resolution

`resolveWeaponPerkOptions(itemHash)` (`src/lib/catalog/weaponPerkOptions.ts`):
1. Load `weapons` store, index by `hash`, read `perkColumns: { column, curated[], randomized[] }`.
2. For each column, union curated + randomized, de-dupe, resolve names via the `weapon-perks` name map (pattern from `src/lib/llm/tools.ts` `perkNamesForColumn`).
3. Return `{ itemHash, columns }`.

## Test expectations

- Weapon with multiple plugs per column → each column lists the curated ∪ randomized options, de-duplicated.
- Unresolved plug hash → option `name` falls back to the hash string (not dropped).
- Unknown/non-weapon `itemHash` → empty `columns`.
- Missing `itemHash` → `400`.
- Client cross-reference: given a copy's equipped `plugs`, exactly the equipped option per column is identifiable within `options`.
