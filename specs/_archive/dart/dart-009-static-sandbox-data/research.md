# Research: DART-009 Static Sandbox Data

**Date**: 2026-07-24

## Source modules (TypeScript product)

| Area | Path | Notes |
| ---- | ---- | ----- |
| Stat benefits | `src/data/rules/statBenefits.ts` | 0–200 linear curves; `computeBenefitsAt` |
| Armor archetypes | `src/data/rules/armorArchetypes.ts` | 12 archetypes |
| Champion counters | `src/data/rules/championCounters.ts` | Anti-Champion 2.0 |
| Activity rules | `src/data/rules/activityRules.ts` | Artifact disabled activities |
| Ability timings | `src/data/rules/abilityTimings.ts` | Fallback map + parse |
| Synergy elements | `src/data/synergyElements.ts` | Element enum strings |
| Synergy verbs | `src/data/synergyVerbs.ts` | Curated verbs + resolve |
| Exotic ability reqs | `src/data/exoticAbilityRequirements.ts` | DBR-SUB-005 curated table |
| Weapon types | `src/data/weaponTypes.ts` | Known types vocabulary |
| Concept tags | `src/data/conceptTags.ts` | Faceted tags (no Zod in Dart) |
| Subclasses | `src/data/subclasses.ts` | Per-class name lists |

## Decisions

### R1 — Separate constants package

**Decision**: New `packages/sandbox_data` rather than only `packages/domain/src/sandbox`.  
**Rationale**: Roadmap exit criteria say “Constants package”; keeps evaluators and curated tables independently versionable for sandbox patches.  
**Alternatives**: Domain submodule only — rejected for exit-criteria wording.

### R2 — No dependency on destiny2_domain

**Decision**: sandbox_data is SDK-only; defines its own `ArmorStatName` with identical wire names.  
**Rationale**: Depends on DART-001 only; avoids coupling constants to evaluators. DART-011 may unify types.  
**Alternatives**: Depend on domain — rejected for this slice independence.

### R3 — Soft-only package APIs

**Decision**: No hard-block / save-gate functions in sandbox_data.  
**Rationale**: Soft guidance never auto-applies; hard evaluators remain in domain (DART-003). Exotic ability *table* is data; `evaluateExoticAbilityMatch` stays domain.

### R4 — Subclasses meta deferred

**Decision**: Port `SUBCLASSES_BY_CLASS` only; skip full `subclasses.meta.ts` source citations.  
**Rationale**: Large curated meta with source paths; vocabulary list is enough for P0 constants.

### R5 — Concept tags without Zod

**Decision**: Pure list + `isConceptTagId` / getters; no schema package.  
**Rationale**: Zod is TS-only; Dart validation is simple Set membership.

## Interpolation parity

TS:

```ts
clamped = min(max(value - rangeStart, 0), 100)
return (clamped / 100) * max
// render: amount.toFixed(precision ?? 0)
```

Dart: same math with `toStringAsFixed`.

## Workspace wiring

Root `pubspec.yaml` `workspace:` must include `packages/sandbox_data`. Melos discovers via workspace members + `dirExists: test`.
