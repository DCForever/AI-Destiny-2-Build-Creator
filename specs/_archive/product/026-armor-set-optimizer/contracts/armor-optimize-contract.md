# Contract: Armor Optimize (Combination Search)

**Type**: Authenticated API + debug UI  
**Stories**: US2, US3, US4, US6, US7  
**Rules**: DBR-CMP-007, DBR-STAT-001–005, DBR-MOD-001–002, DBR-SETB-001, BR-OPT-003 (prefer-reuse)

## Endpoint

`POST /api/user/armor/optimize`

**Auth**: Signed-in user with synced inventory (empty inventory → empty result + explanation).  
**Content-Type**: `application/json`

### Request

```ts
type ArmorStatName = "Class" | "Grenade" | "Melee" | "Super" | "Health" | "Weapons";

type SetBonusCoverageGoal = {
  /** Canonical set-bonus name or stable key resolvable by server */
  setBonusKey: string;
  minPieces: 2 | 4;
};

type ArmorOptimizeBody = {
  buildId?: string;
  variantId?: string;
  /** When refreshing / excluding self from reuse annotations */
  armorSetId?: string;
  /** Required if buildId omitted */
  classType?: "Titan" | "Hunter" | "Warlock";

  lockedExoticItemHash?: number | null;
  requireExotic?: boolean; // default false

  setBonusGoals?: SetBonusCoverageGoal[];

  /** Highest priority first */
  statPriorities?: ArmorStatName[];
  /** Soft thresholds unless requireThresholds */
  statThresholds?: Partial<Record<ArmorStatName, number>>;
  requireThresholds?: boolean; // default false

  includeModEstimates?: boolean; // default true
  /** Soft tie-break after lexicographic stats; default false */
  preferReuse?: boolean;
  maxResults?: number; // 1–50, default 25
};
```

**Seeding when `buildId` present**:
- `classType` from build
- `lockedExoticItemHash` from build exotic armor identity when set (overridable)
- `statThresholds` from `softStatTargets` when caller omits thresholds
- `statPriorities` default: stats with targets first (descending target), then remaining EoF six
- `preferReuse` default false unless caller sets it

### Response 200

```ts
type ArmorOptimizeResponse = {
  combinations: ArmorCombination[];
  truncated: boolean;
  evaluatedCount: number;
  emptyReason?: {
    code:
      | "NO_INVENTORY"
      | "NO_CLASS_ARMOR"
      | "EXOTIC_UNAVAILABLE"
      | "SET_BONUS_UNSATISFIABLE"
      | "THRESHOLDS_UNMET"
      | "NO_VALID_KITS";
    message: string;
    details?: Record<string, unknown>;
  };
  seed?: {
    classType: string;
    lockedExoticItemHash?: number;
    statThresholds?: Partial<Record<ArmorStatName, number>>;
    statPriorities?: ArmorStatName[];
    preferReuse?: boolean;
  };
};

type ArmorCombination = {
  pieces: Array<{
    slot: "helmet" | "arms" | "chest" | "legs" | "class_item";
    itemHash: number;
    instanceId: string;
    itemName?: string;
    isExotic: boolean;
    setBonusKey?: string;
    statValues?: Partial<Record<ArmorStatName, number>>;
    /** Other Armor Sets (exclude armorSetId under search) with this instance active */
    usedInOtherSets: Array<{ id: string; name: string }>;
  }>;
  estimatedStats: Partial<Record<ArmorStatName, number>>;
  incompleteEstimate: boolean;
  setBonusSummary: Array<{
    setBonusKey: string;
    pieceCount: number;
    active2pc: boolean;
    active4pc: boolean;
  }>;
  assumedMods: Array<{
    armorSlot: "helmet" | "arms" | "chest" | "legs" | "class_item";
    itemHash: number;
    name?: string;
    energyCost: number;
    statDeltas?: Partial<Record<ArmorStatName, number>>;
  }>;
  /** 0–5 pieces that appear in ≥1 other Armor Set */
  reusePieceCount: number;
  score: number;
  meetsSoftThresholds: boolean;
};
```

### Invariants (testable)

1. Every combination has exactly five armor slots filled and ≤1 exotic armor piece.
2. If `lockedExoticItemHash` set, every combination includes that hash in the correct slot.
3. Every `setBonusGoals` entry is satisfied by piece counts in that combination.
4. Results sorted by lexicographic estimated stats in `statPriorities` order, then sum of prioritized stats; when `preferReuse` is true, higher `reusePieceCount` ranks higher only after those ties (FR-005).
5. When `preferReuse` is false, order ignores reuse (annotations still present).
6. When `includeModEstimates` is false, `assumedMods` is `[]` and estimates exclude auto mods.
7. When `includeModEstimates` is true, assumed mods respect per-piece energy capacity.
8. Soft-removed Set items never appear in `usedInOtherSets` / `reusePieceCount`.
9. `combinations.length === 0` ⇒ `emptyReason` present.

### Errors

| Status | Code | When |
|--------|------|------|
| 401 | — | Not signed in |
| 400 | `VALIDATION` | Zod failure / missing classType |
| 404 | `BUILD_NOT_FOUND` | Bad buildId |
| 400 | `UNKNOWN_SET_BONUS` | Unresolvable `setBonusKey` |

### Debug UI

- **Builds**: “Optimize armor” prefilled from build → result table (pieces, stats, set bonuses, assumed mods, reuse annotations, prefer-reuse toggle).
- **Sets**: Same form with manual class / exotic / goals (US6); prefer-reuse control.
