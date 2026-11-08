# Research: DART-010 DIM Builders

**Date**: 2026-07-24

## TS sources of truth

| Area | Path |
| ---- | ---- |
| Dim types + sheet builder | `src/lib/dim/dimLoadout.ts` |
| Variant builder (product path) | `src/lib/dim/buildVariantDimLoadout.ts` |
| Variant builder tests | `src/lib/dim/buildVariantDimLoadout.test.ts` |
| jsonOnly route gate | `src/app/api/user/builds/[id]/variants/[variantId]/dim-export/route.ts` |
| Product contract | `specs/021-dim-export/contracts/dim-export-contract.md` |
| Equip gate (already ported) | `packages/domain/lib/src/evaluators/equip_ready.dart` |

## Decisions

### D1 — Port variant builder only for P0 exit

**Decision**: Implement `buildVariantDimLoadout` + types/constants. Defer LLM sheet `buildDimLoadout(ResolvedBuildSheet)`.

**Rationale**: Exit criterion is jsonOnly for a **fixture variant**; product dim-export uses the variant builder. Sheet path is legacy LLM surface.

### D2 — Injectable loadout id

**Decision**: `buildVariantDimLoadout(..., {String? id})` — tests pass a fixed UUID; production hosts may pass `Uuid().v4()` later without domain uuid dependency.

**Rationale**: TS `crypto.randomUUID()` is non-deterministic; goldens need stability without adding packages.

### D3 — Pure gate helper

**Decision**: `buildJsonOnlyDimExport({required EquipReadyResult readiness, required VariantDimLoadoutInput input, String? loadoutId})` calls `assertEquipReady` then returns `{ 'loadout': loadout.toJson() }`.

**Rationale**: Mirrors route steps 1–2 + jsonOnly return without network; adapters map exception → 409 later.

### D4 — No collectVariantMods in domain

**Decision**: Caller supplies `modHashes: List<int>`.

**Rationale**: Mod collection hits DB; pure domain must not.

### D5 — Fashion / artifact as thin DTOs

**Decision**: Local pure classes in dim models/builders, not full library fashion set entities.

**Rationale**: Keep domain free of incomplete library graph; matches TS resolved export shapes.

## Open items deferred

- dim.gg share client (network) — DART-039
- Socket override JSON key string vs int serialization details beyond `toJson` string keys
- Full multi-piece fashion order parity with Object.values if hosts need stable ordering beyond single-piece tests
