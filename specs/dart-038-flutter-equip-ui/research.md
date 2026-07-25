# Research: DART-038 Flutter Equip UI

**Date**: 2026-07-25  
**Branch**: `dart-038-flutter-equip-ui`

## Product parity sources

| Concern | Product source | Dart equivalent |
| ------- | -------------- | --------------- |
| Character pick | `BuildActions.tsx` + `GET /api/bungie/characters` | New `getCharacters` on profile client + EquipPanel |
| Equip POST | `variants/[variantId]/equip/route.ts` | EquipController: assertEquipReady → syncIfStale → plan → execute |
| Equip-ready | `equipReady.ts` / assert | Domain `computeEquipReady` / `assertEquipReady` |
| Plan / execute | `equipPlan.ts` / `equipOrchestrator.ts` | Domain plan + bungie `executeEquipPlan` (DART-037) |
| Class match | INVALID_CHARACTER when classType ≠ build class | Controller check vs `CharacterSummary.classType` |

## Decisions

### R1 — Characters on profile client

**Decision**: Add `getCharacters` + `CharacterSummary` to `destiny2_bungie` (component 200).  
**Why**: DART-024 profile client only had memberships + full inventory; character pick requires class/light/id without inventing host-only HTTP.  
**Alt rejected**: Hard-code character ids in UI; parse characters only inside windows_host.

### R2 — Gaps confirm scope

**Decision**:  
- Non-ready pin statuses (wishlist/stale) → **hard block** (no force equip).  
- Equip-ready + empty combat slots (no claim) → **confirm dialog** before execute.  
**Why**: Matches exit “gaps confirm UX” without violating equip-ready hard gate; empty slots are intentional incomplete builds users may still equip.

### R3 — Fashion/artifact

**Decision**: Pass null artifact and empty fashion into `planEquipSteps` for this slice unless variant artifact hash is available on `VariantRecord`.  
**Why**: Host compose does not yet fully model fashion; combat pins are the equip-ready surface. Artifact step can be included when `variant.artifactHash` is non-null.

### R4 — Write client injection

**Decision**: Construct `HttpBungieWriteClient` from the same public API key path as profile HTTP, inject via `AppServices` or EquipController constructor for tests (`MockBungieWriteClient` / `createMockBungieWriteClient`).  
**Why**: Tests must assert call order without live Platform.

### R5 — Soft guidance

**Decision**: Equip path does not call soft coverage apply or mutate soft targets.  
**Why**: DBR-GUID / program rule — soft never auto-applies.

## Open items (out of slice)

- Post-equip inventory resync UX polish (may syncIfStale next equip).
- DIM export CTA (DART-039).
- Full artifact season wiring (execute may report failure).
