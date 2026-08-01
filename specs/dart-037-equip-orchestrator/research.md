# Research: DART-037 Equip Orchestrator

**Date**: 2026-07-25  
**Slice**: planEquipSteps + execute + partial status (write client)

## Product sources

| Concern | TypeScript source |
| ------- | ----------------- |
| Plan | `src/lib/builds/equipPlan.ts` + `equipPlan.test.ts` |
| Execute | `src/lib/builds/equipOrchestrator.ts` (tests in equipPlan.test.ts) |
| Write API | `src/lib/bungie/writeClient.ts` + `writeClient.test.ts` |
| Equip gate (caller) | `equipReady.ts` (already DART-006) |

## Decisions

### R1 — Where does pure plan live?

**Decision**: `packages/domain` (`equip_plan.dart`).  
**Why**: Planner is zero-IO and shared by Flutter (DART-038) and later Jaspr equip (DART-047). Matches DART-006/DART-010 pure placement.  
**Alt rejected**: bungie-only plan (would pull non-IO logic into network package).

### R2 — Write client package

**Decision**: `packages/bungie` write surface + dependency on `destiny2_domain` for `PlannedEquipStep`.  
**Why**: Needs `BungieHttpClient` / transport already in bungie; domain must not grow HTTP deps.

### R3 — Partial failure model

**Decision**: Best-effort sequential execute; catch per step; no rollback; continue remaining steps.  
**Why**: Exact product parity (`executeEquipPlan` comment + US3 tests). Users see which steps applied.

### R4 — Artifact apply

**Decision**: HTTP `applyArtifactConfig` throws “not fully wired” (TS parity). Mock defaults succeed for orchestrator tests.  
**Why**: Roadmap deferred “Artifact apply completeness”; do not invent seasonal socket API here.

### R5 — Fashion step instance resolution

**Decision**: Plan looks up first inventory item by `itemHash` for fashion instanceId (TS `inventoryByHash`).  
**Why**: Parity; execute fashion uses equip-by-instance when present.

### R6 — Secrets

**Decision**: Public API key + Bearer access token only. No `client_secret` fields.  
**Why**: D-WEB-AUTH / D-IO locked decisions.

## Open items deferred

- Full artifact socket insert matrix (seasonal)
- Flutter equip UI / character selection (DART-038)
- Post-equip profile sync trigger (host concern)
