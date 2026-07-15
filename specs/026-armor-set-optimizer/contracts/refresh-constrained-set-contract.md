# Contract: Refresh Constrained Armor Set

**Type**: Authenticated API + debug UI  
**Stories**: US5b  
**Rules**: FR-010a–d, BR-OPT-002, BR-OPT-004  
**Implements**: T051 routes `POST /api/user/sets/[id]/optimize`, `POST /api/user/sets/[id]/apply-combination`

## Endpoints

### 1. Optimize from stored constraints

`POST /api/user/sets/[id]/optimize`

**Auth**: Signed-in owner of the Armor Set.  
**Content-Type**: `application/json`

#### Request

```ts
type RefreshOptimizeBody = {
  /** Override stored constraints for this run only (not saved unless PATCH constraints) */
  overrides?: Partial<ArmorSetOptimizerConstraints>;
  maxResults?: number; // 1–50, default 25
};
```

Uses the Set’s stored `optimizerConstraints` as the search request (class from Set items / inventory). Passes `armorSetId` into optimize so self is excluded from reuse annotations. Empty/missing constraints → `400 NO_CONSTRAINTS`.

#### Response 200

Same shape as [armor-optimize-contract.md](./armor-optimize-contract.md) `ArmorOptimizeResponse`, plus:

```ts
type RefreshOptimizeResponse = ArmorOptimizeResponse & {
  armorSetId: string;
  constraintsUsed: ArmorSetOptimizerConstraints;
  /** True when top valid kit is lexicographically better than current Set pieces */
  hasImprovement: boolean;
};
```

---

### 2. Apply combination in place

`POST /api/user/sets/[id]/apply-combination`

**Auth**: Signed-in owner of the Armor Set.  
**Content-Type**: `application/json`

#### Request

```ts
type ApplyCombinationBody = {
  pieces: Array<{
    slot: "helmet" | "arms" | "chest" | "legs" | "class_item";
    itemHash: number;
    instanceId: string;
  }>;
  assumedMods?: Array<{
    armorSlot: "helmet" | "arms" | "chest" | "legs" | "class_item";
    itemHash: number;
  }>;
  /** Update linked Mod Set (or create if missing when mods present); default true if assumedMods */
  updateLinkedModSet?: boolean;
};
```

#### Response 200

```ts
type ApplyCombinationResponse = {
  armorSet: {
    id: string; // unchanged
    name: string; // unchanged
    type: "armor";
    optimizerConstraints: ArmorSetOptimizerConstraints; // unchanged by apply
    linkedModSetId?: string;
  };
  modSet?: { id: string; name: string; type: "mod"; updated: boolean };
  /** true when items were rewritten; false when kit equal / already optimal and no write */
  itemsUpdated: boolean;
};
```

### Errors

| Status | Code | When |
|--------|------|------|
| 401 | — | Not signed in |
| 404 | `SET_NOT_FOUND` | Unknown / other user’s / non-armor Set |
| 400 | `NO_CONSTRAINTS` | Optimize without stored constraints payload |
| 400 | `VALIDATION` | Bad pieces / slots |
| 400 | `EXOTIC_LIMIT` | >1 exotic |
| 400 | `INSTANCE_NOT_OWNED` | Instance not owned |
| 409 | `MOD_ENERGY` | Illegal assumed mods |

### Behavior

1. **Optimize**: search owned inventory with stored constraints (optional overrides for this run); return ranked complete kits + `hasImprovement` vs current pieces.
2. **Apply**: replace slot items **in place** on the same Armor Set id; do **not** change stored constraints; do **not** create a duplicate Armor Set.
3. If `updateLinkedModSet` and assumed mods: update linked Mod Set in place, or create + link when missing and opted in.
4. If no better kit / equal kit and apply is a no-op, return `itemsUpdated: false` with a clear message path for “already optimal.”
5. Manual refresh remains available anytime (independent of post-sync suggestions).

### Debug UI

Sets debug: constrained Set → “Refresh / Optimize from Set” → result table → confirm “Apply in place” → JSON panel (same Set id).
