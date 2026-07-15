# Contract: Materialize Armor Combination

**Type**: Authenticated API + debug UI  
**Stories**: US5  
**Rules**: BR-SET-*, BR-SLOT-002/009, BR-SLOT-010, DBR-MOD-001–002, DBR-CMP-003, BR-OPT-001–002

## Endpoint

`POST /api/user/armor/optimize/materialize`

**Auth**: Signed-in user.  
**Content-Type**: `application/json`

**Scope**: **First-time** materialize only — creates a **new** Armor Set and persists constraints. For updating an existing constrained Set, see [refresh-constrained-set-contract.md](./refresh-constrained-set-contract.md).

### Request

```ts
type ArmorSetOptimizerConstraints = {
  lockedExoticItemHash?: number | null;
  setBonusGoals: SetBonusCoverageGoal[];
  statPriorities: ArmorStatName[];
  statThresholds?: Partial<Record<ArmorStatName, number>>;
  requireThresholds?: boolean;
  includeModEstimates?: boolean;
  preferReuse?: boolean; // default false
};

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

  /** Required — stored on the new Armor Set */
  constraints: ArmorSetOptimizerConstraints;

  armorSetName: string; // base name; auto-unique suffix on collision
  createModSet?: boolean; // default: true if assumedMods?.length
  modSetName?: string;

  attachNow?: boolean; // default false — replace-by-type when true
  buildId?: string;
  variantId?: string; // required with buildId when attachNow
};
```

### Response 200

```ts
type MaterializeCombinationResponse = {
  armorSet: {
    id: string;
    name: string; // may include numeric suffix
    type: "armor";
    optimizerConstraints: ArmorSetOptimizerConstraints;
    linkedModSetId?: string;
  };
  modSet?: { id: string; name: string; type: "mod" };
  attachments: Array<{
    setId: string;
    mode: "live";
    variantId: string;
    replacedSetIds?: string[];
  }>;
};
```

### Errors

| Status | Code | When |
|--------|------|------|
| 401 | — | Not signed in |
| 400 | `VALIDATION` | Missing slots, duplicate slots, bad hashes, missing constraints |
| 400 | `EXOTIC_LIMIT` | >1 exotic in pieces |
| 400 | `INSTANCE_NOT_OWNED` | instanceId not in user inventory / hash mismatch |
| 409 | `DUPLICATE_SET_NAME` | Only if auto-unique naming fails after retries |
| 409 | `MOD_ENERGY` | Assumed mods illegal for energy/slot |
| 400 | `ATTACH_REQUIRES_BUILD` | attachNow without build/variant |
| 404 | `BUILD_NOT_FOUND` | |

### Behavior

1. Validate pieces (unique slots, all five present, owned instances, ≤1 exotic).
2. Create **new** Armor Set with auto-unique name; upsert items; **persist `constraints`** on the Set (including `preferReuse` default false).
3. If `createModSet` and mods present: create Mod Set with per-piece keys; validate energy using instance tiers; set `linkedModSetId` on the Armor Set.
4. If `attachNow`: **replace-by-type** live-attach Armor Set and Mod Set (when created) to variant (FR-002a / FR-010).
5. Selecting a combination in UI must **not** call this endpoint until confirm (US3).
6. Does **not** overwrite an existing Armor Set’s items — that path is refresh/apply (US5b).

### Debug UI

Optimize results table → “Materialize” → name fields + constraints summary + attachNow → POST → link/ids in JSON panel.
