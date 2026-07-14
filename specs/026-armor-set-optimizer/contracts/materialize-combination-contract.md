# Contract: Materialize Armor Combination

**Type**: Authenticated API + debug UI  
**Stories**: US5  
**Rules**: BR-SET-*, BR-SLOT-002/009, BR-SLOT-010, DBR-MOD-001–002, DBR-CMP-003

## Endpoint

`POST /api/user/armor/optimize/materialize`

**Auth**: Signed-in user.  
**Content-Type**: `application/json`

### Request

```ts
type MaterializeCombinationBody = {
  pieces: Array<{
    slot: "helmet" | "arms" | "chest" | "legs" | "class_item";
    itemHash: number;
    instanceId: string;
  }>;
  assumedMods?: Array<{
    armorSlot: "helmet" | "arms" | "chest" | "legs" | "class_item";
    itemHash: number;
  }>;

  armorSetName: string;
  createModSet?: boolean; // default: true if assumedMods?.length
  modSetName?: string;

  attachNow?: boolean; // default false
  buildId?: string;
  variantId?: string; // required with buildId when attachNow
};
```

### Response 200

```ts
type MaterializeCombinationResponse = {
  armorSet: { id: string; name: string; type: "armor" };
  modSet?: { id: string; name: string; type: "mod" };
  attachments: Array<{
    setId: string;
    mode: "live";
    variantId: string;
  }>;
};
```

### Errors

| Status | Code | When |
|--------|------|------|
| 401 | — | Not signed in |
| 400 | `VALIDATION` | Missing slots, duplicate slots, bad hashes |
| 400 | `EXOTIC_LIMIT` | >1 exotic in pieces |
| 400 | `INSTANCE_NOT_OWNED` | instanceId not in user inventory / hash mismatch |
| 409 | `DUPLICATE_SET_NAME` | Name taken for type |
| 409 | `MOD_ENERGY` | Assumed mods illegal for energy/slot |
| 400 | `ATTACH_REQUIRES_BUILD` | attachNow without build/variant |
| 404 | `BUILD_NOT_FOUND` | |

### Behavior

1. Validate pieces (unique slots, owned instances, ≤1 exotic).
2. Create Armor Set + upsert items (`confirmReplace` N/A on new set).
3. If `createModSet` and mods present: create Mod Set with per-piece keys; validate energy using instance tiers.
4. If `attachNow`: live-attach Armor Set and Mod Set (when created) to variant.
5. Selecting a combination in UI must **not** call this endpoint until confirm (US3).

### Debug UI

Optimize results table → “Materialize” → name fields + attachNow → POST → link/ids in JSON panel.
