# Contract: Create Sets from Build

**Type**: Authenticated API + debug UI  
**Stories**: US1  
**Rules**: DBR-CMP-001–003, BR-SET-*, BR-SLOT-*, BR-TAG-004 (name uniqueness), BR-OPT-001–002 (026 stubs)

## Endpoint

`POST /api/user/builds/[id]/create-sets`

**Auth**: Signed-in owner of build.  
**Content-Type**: `application/json`

### Request

```ts
type CreateSetsFromBuildBody = {
  variantId?: string; // default = build default variant
  categories?: Array<"armor" | "weapon" | "mod">; // default: all with ≥1 filled claim
  attachNow?: boolean; // default true — replace-by-type
  namePrefix?: string; // default: build name; auto-suffix on collision
};
```

### Response 200

```ts
type CreateSetsFromBuildResponse = {
  createdSets: Array<{
    id: string;
    type: "armor" | "weapon" | "mod";
    name: string; // may include numeric suffix
    /** Present on armor when seeded from build exotic / soft targets */
    optimizerConstraints?: ArmorSetOptimizerConstraints;
  }>;
  attachments: Array<{
    setId: string;
    mode: "live";
    variantId: string;
    /** Prior same-type live attachments detached (library retained) */
    replacedSetIds?: string[];
  }>;
  skippedCategories: Array<"armor" | "weapon" | "mod">;
};
```

### Errors

| Status | Code | When |
|--------|------|------|
| 401 | — | Not signed in |
| 404 | `BUILD_NOT_FOUND` | Unknown / other user’s build |
| 400 | `VARIANT_NOT_FOUND` | Bad variantId |
| 400 | `NOTHING_TO_CREATE` | No filled claims in selected categories |
| 409 | `DUPLICATE_SET_NAME` | Only if auto-unique naming fails after retries (should be rare) |
| 409 | `EXOTIC_CONFLICT` / energy codes | Set item validation fails |

### Behavior

1. Resolve variant combat claims (and mod claims for `mod` category).
2. For each selected non-empty category, create a Set with unique name `{prefix} Armor` / `Weapons` / `Mods` (suffix ` (n)` on collision — never fail solely for name collision).
3. Upsert one item per filled slot (armor/weapon) or mod plugs keyed per existing Mod Set rules; preserve `instanceId` when present.
4. For **Armor** Sets: seed `optimizerConstraints` with Build exotic armor identity (when set) and soft-stat priorities/thresholds from soft targets (when present); `setBonusGoals` starts empty; `preferReuse` defaults false (FR-001a).
5. If `attachNow`, **replace-by-type**: detach existing live attachment(s) of the same set type on the variant, then attach each created set as **live**. Other set types unchanged. Detached Sets stay in the library (FR-002a).
6. Does **not** run the armor optimizer; snapshots current composition only. Set-bonus goals are not inferred from equipped pieces.

### Debug UI

Builds debug page: form (categories multi-select, attachNow checkbox, optional namePrefix) → POST → JSON panel of response (show seeded constraints on armor).
