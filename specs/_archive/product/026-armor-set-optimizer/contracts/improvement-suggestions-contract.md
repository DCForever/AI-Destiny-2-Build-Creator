# Contract: Armor Improvement Suggestions

**Type**: Authenticated API + debug UI  
**Stories**: US5b  
**Rules**: FR-010c–d, BR-OPT-004  
**Implements**: T051 route `GET /api/user/armor/improvement-suggestions`

## Endpoint

`GET /api/user/armor/improvement-suggestions`

**Auth**: Signed-in user.  
**Query** (optional):

| Param | Type | Notes |
|-------|------|--------|
| `afterSync` | `1` \| omit | Hint that caller just finished inventory sync (attached Sets only) |
| `armorSetId` | string | On-open check for a single Set (attached or unattached) |

### Response 200

```ts
type ImprovementSuggestionsResponse = {
  suggestions: Array<{
    armorSetId: string;
    armorSetName: string;
    buildIds: string[]; // Builds attaching this Set; [] for unattached on-open
    hasImprovement: boolean;
    /** Present when hasImprovement — top better complete kit summary */
    betterCombination?: ArmorCombination; // same shape as optimize contract
    currentSummary?: {
      estimatedStats: Partial<Record<ArmorStatName, number>>;
      reusePieceCount?: number;
    };
  }>;
};
```

### Eligibility (FR-010c)

Include an Armor Set when:

1. It has a **stored `optimizerConstraints` payload** (exotic-only or soft-stats-only qualifies; empty `setBonusGoals` OK), **and**
2. Either:
   - It is **attached to ≥1 Build** (post-sync / list check), **or**
   - Caller passes `armorSetId` for an **unattached** Set being opened.

Sets with cleared/`null` constraints are **out** until constraints are set again (FR-010d).

### Behavior

1. For each eligible Set, run constrained search against current owned inventory using stored constraints.
2. If a better complete kit exists (lexicographic rank vs current pieces), include `hasImprovement: true` + `betterCombination`.
3. **Never** mutate Set items from this endpoint — soft suggestion only (suggest-then-confirm).
4. Apply path: client confirms → `POST /api/user/sets/[id]/apply-combination` per [refresh-constrained-set-contract.md](./refresh-constrained-set-contract.md).
5. Dismissing a suggestion leaves items unchanged; may reappear on a later sync if still relevant.

### Errors

| Status | Code | When |
|--------|------|------|
| 401 | — | Not signed in |
| 404 | `SET_NOT_FOUND` | `armorSetId` unknown / not owned |
| 400 | `NO_CONSTRAINTS` | `armorSetId` given but Set has no constraints payload |

### Debug UI

- Builds debug: after sync (or on load), banner/list of soft suggestions for attached constrained Sets → Confirm apply / Dismiss.
- Sets debug: opening an unattached constrained Set triggers check via `?armorSetId=` and shows soft suggestion if improved kit exists.
