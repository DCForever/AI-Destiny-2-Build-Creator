# Quickstart: Full Inventory Plug Resolution

**Feature**: 004-full-plug-resolution  
**Branch**: `004-full-plug-resolution`

**Purpose**: Validate expanded plug name resolution on owned instance list/detail and perk search.

**Operator guide:** [DEBUG.md](../../../DEBUG.md) — prerequisites and owned catalog drill-down.

## Prerequisites

```bash
npm run dev
# NODE_ENV must NOT be production
# Settings → Refresh manifest (BUNGIE_API_KEY)
# Sign in with Bungie
# POST /api/bungie/sync — see DEBUG.md
```

**Debug entry**: `/debug/catalog` (owned scope, `includeInstancePointer=1`)

## Fixture: The Ringing Nail (weapon)

Use an owned copy of **The Ringing Nail** (`itemHash` `4206550094` or reissue hash with same `searchName`). After 004, these plug hashes should **`resolved: true`** when manifest is loaded:

| Hash | Expected name (approx.) |
|------|-------------------------|
| 1636108362 | Precision Frame |
| 4248210736 | Default Shader |
| 3634656993 | Synergy |
| 882794620 | Reload Speed (masterwork) |
| 2034764268 | Forge's Kin |
| 905869860 | Kill Tracker |

Roll perks (already resolved in 003) should remain named, e.g. Fluted Barrel, High-Caliber Rounds, Heal Clip, Burning Ambition.

## Scenario 1: Instance detail shows named non-roll plugs

```http
GET /api/user/inventory/instances?itemHash=4206550094
```

**Pass**: Each fixture hash above has `resolved: true` and readable `displayName`. Any manifest-missing hash shows hash fallback without 5xx.

## Scenario 2: List vs detail consistency

```http
GET /api/user/inventory/instances?itemHash=4206550094
GET /api/user/inventory/instances/{instanceId}
```

**Pass**: Same `plugs` array for the same `instanceId`.

## Scenario 3: Perk search on enhanced mod (SC-003)

```http
GET /api/user/inventory/instances?q=Synergy
```

**Pass**: Returns Ringing Nail copies (or any instance with Synergy mod equipped).

```http
GET /api/user/inventory/instances?q=Precision
```

**Pass**: Returns instances with Precision Frame intrinsic (may include other weapons with "Precision" in perk names).

## Scenario 4: Armor mod and masterwork

Pick any owned legendary armor piece with visible mods in game.

```http
GET /api/user/inventory/instances?kind=armor&itemHash={hash}
```

**Pass**: Mod plugs and masterwork/cosmetic sockets show names where manifest defines them.

## Scenario 5: Debug catalog panel

1. Open `/debug/catalog`, scope **owned**, enable instance pointer if needed.
2. Search for Ringing Nail, select row.
3. Inspect instance card plug list.

**Pass**: ≥99% of plugs show names (SC-001); at most rare hash-only entries for redacted/unknown content.

## Scenario 6: Manifest not loaded

With manifest stale or missing:

**Pass**: Instances still return from sync; more plugs may show hash fallback; no crash.

## Scenario 7: Gate

```bash
npm run gate
```

**Pass**: All tests green including updated `resolvePlugs` / plug map tests.

## Unit test anchors

Co-located tests in `src/lib/inventory/instances/resolvePlugs.test.ts` (and new tests for hybrid map builder) MUST cover:

- Entity store merge
- Manifest fallback merge for unresolved hashes
- Unresolved hash degradation unchanged
