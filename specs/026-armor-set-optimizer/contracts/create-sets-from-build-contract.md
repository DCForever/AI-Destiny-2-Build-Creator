# Contract: Create Sets from Build

**Type**: Authenticated API + debug UI  
**Stories**: US1  
**Rules**: DBR-CMP-001–003, BR-SET-*, BR-SLOT-*, BR-TAG-004 (name uniqueness)

## Endpoint

`POST /api/user/builds/[id]/create-sets`

**Auth**: Signed-in owner of build.  
**Content-Type**: `application/json`

### Request

```ts
type CreateSetsFromBuildBody = {
  variantId?: string; // default = build default variant
  categories?: Array<"armor" | "weapon" | "mod">; // default: all with ≥1 filled claim
  attachNow?: boolean; // default true
  namePrefix?: string; // default: build name
};
```

### Response 200

```ts
type CreateSetsFromBuildResponse = {
  createdSets: Array<{
    id: string;
    type: "armor" | "weapon" | "mod";
    name: string;
  }>;
  attachments: Array<{
    setId: string;
    mode: "live";
    variantId: string;
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
| 409 | `DUPLICATE_SET_NAME` | Only if auto-unique naming fails after retries |
| 409 | `EXOTIC_CONFLICT` / energy codes | Set item validation fails |

### Behavior

1. Resolve variant combat claims (and mod claims for `mod` category).
2. For each selected non-empty category, create a Set with unique name `{prefix} Armor` / `Weapons` / `Mods` (suffix ` (n)` on collision).
3. Upsert one item per filled slot (armor/weapon) or mod plugs keyed per existing Mod Set rules; preserve `instanceId` when present.
4. If `attachNow`, attach each created set to the variant as **live** (existing attachment merge rules; conflicts return error without leaving orphan attaches — prefer roll back attaches or document compensation in implement tasks).
5. Does **not** run the armor optimizer; snapshots current composition only.

### Debug UI

Builds debug page: form (categories multi-select, attachNow checkbox, optional namePrefix) → POST → JSON panel of response.
