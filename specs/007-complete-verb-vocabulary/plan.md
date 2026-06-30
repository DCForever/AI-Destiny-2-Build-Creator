# Implementation Plan: Complete Verb Vocabulary

**Branch**: `feature/overhall` (or `007-complete-verb-vocabulary`) | **Date**: 2026-06-29  
**Input**: Verbs are incomplete — `Exhaust`/`Exhausts`, `Sever`, `Void Breach`, `Radiant`, etc. missing from picker  
**Related spec**: [specs/006-synergy-refinement/spec.md](../006-synergy-refinement/spec.md) (FR-007, examples: Sever, Void Breach)

## Summary

The Verb synergy sub-type picker currently exposes **12 verbs** aggregated from `subclasses.meta.ts` — a champion-stun-focused subset per subclass, not Bungie's full keyword glossary. The 006 spec already expects verbs like **Sever** and **Void Breach**; users report **Exhaust** is also missing.

**Decision**: Introduce a dedicated master vocabulary `src/data/synergyVerbs.ts` (parallel to `synergyElements.ts`). Elements remain a separate synergy category; verbs are **keyword/status effects only**, not damage types.

## Problem

| Area | Current behavior | Gap |
|------|------------------|-----|
| Picker source | `listAllVerbs()` dedupes `SUBCLASS_METADATA.verbs` only | ~12 verbs; missing ~20+ Bungie keywords |
| Spec alignment | FR-007 curated vocabularies; examples cite Sever, Void Breach | Examples not selectable |
| Validation | `validateSynergySubType` accepts any non-empty string for `verb` | Typos / stale names persist; unlike `element` and `weapon_archetype` |
| `subclasses.meta.ts` | Per-subclass champion verbs for UI labels | Correct for subclass display; wrong as sole synergy source |

## Target Verb Glossary (~32 keywords)

Authoritative display names from [Destinypedia element verb pages](https://www.destinypedia.com/Solar#Verbs) (Solar, Arc, Void, Stasis, Strand) plus [Prismatic](https://www.destinypedia.com/Prismatic#Verbs). **Exclude** damage elements (handled by Element synergies).

**Corrections (2026-06-29)**:
- **Void Overshield** — not bare "Overshield" ([Void keywords](https://www.destinypedia.com/Void#Verbs))
- **Exhaust** — subclass-agnostic debuff (e.g. applied via Jolt); not a Strand verb
- **Volatile Rounds** — same keyword as **Volatile**; do not list separately

### Solar (6) — [destinypedia.com/Solar#Verbs](https://www.destinypedia.com/Solar#Verbs)
| Verb | Notes |
|------|-------|
| Scorch | DoT; stacks lead to Ignition |
| Ignition | Large Solar explosion |
| Restoration | Health/shield regen over time |
| Cure | Instant heal |
| Radiant | Weapon damage buff |
| Firesprite | Solar pickup companion |

### Arc (5) — [destinypedia.com/Arc#Verbs](https://www.destinypedia.com/Arc#Verbs)
| Verb | Notes |
|------|-------|
| Jolt | Chain lightning; Overload stun |
| Blind | Disorient; Unstoppable stun |
| Amplified | Movement/weapon handling buff |
| Bolt Charge | Stack-based Arc lightning proc |
| Ionic Trace | Arc pickup; grants Bolt Charge stacks |

### Void (7) — [destinypedia.com/Void#Verbs](https://www.destinypedia.com/Void#Verbs)
| Verb | Notes |
|------|-------|
| Suppression | Disables abilities; Overload stun (alias: legacy `Suppress` in `subclasses.meta`) |
| Volatile | Unstable energy; explodes on further damage (includes **Volatile Rounds** on weapons) |
| Weaken | Reduced damage output |
| Void Breach | Pickup orb |
| Devour | Kill-to-heal |
| Void Overshield | Bonus shields (Void buff) |
| Invisibility | Void stealth buff |

### Stasis (6) — [destinypedia.com/Stasis#Verbs](https://www.destinypedia.com/Stasis#Verbs)
| Verb | Notes |
|------|-------|
| Slow | Movement/ability debuff; Overload stun |
| Freeze | Immobilize; leads to Shatter |
| Shatter | Burst on frozen break; Unstoppable stun |
| Frost Armor | Damage reduction buff |
| Stasis Crystal | Solidified Stasis matter; freeze aura |
| Stasis Shard | Stasis pickup; melee/grenade energy |

### Strand (6) — [destinypedia.com/Strand#Verbs](https://www.destinypedia.com/Strand#Verbs)
| Verb | Notes |
|------|-------|
| Suspend | Lift/immobilize; Unstoppable stun |
| Unravel | Damage propagation |
| Sever | Damage reduction debuff |
| Threadling | Seeking Strand creature |
| Woven Mail | Damage reduction buff |
| Tangle | Strand pickup / throwable |

### Prismatic (1) — [destinypedia.com/Prismatic#Verbs](https://www.destinypedia.com/Prismatic#Verbs)
| Verb | Notes |
|------|-------|
| Transcendence | Light + Dark harmony state |

### Subclass-agnostic (1)
| Verb | Notes |
|------|-------|
| Exhaust | Reduces enemy damage output (~10%); applied across elements (e.g. Jolt) |

**Explicit exclusions** (not verbs):
- Damage elements: Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic → `synergyElements.ts`
- Weapon-only round variants as separate entries (`Volatile Rounds` → use `Volatile`)
- Prismatic facet groupings (Light Buffs, Darkness Debuffs, etc.) → use underlying verb names
- Champion types (Barrier, Overload, Unstoppable)

**Naming rule**: Match Destinypedia / in-game keyword capitalization. Add `aliases` only for legacy rows (`Suppress` → `Suppression`).

## Technical Approach

### 1. Master vocabulary — `src/data/synergyVerbs.ts`

```ts
export type SynergyVerbEntry = {
  name: string;
  description?: string;
  source?: string; // relative path under src/data/meta/sources/
};

export const SYNERGY_VERBS: readonly SynergyVerbEntry[] = [ /* ordered list */ ];
export const SYNERGY_VERB_NAMES: readonly string[] = SYNERGY_VERBS.map(v => v.name);
```

Mirror `synergyElements.ts` pattern: const array, exported type, single source of truth.

### 2. Refactor `listAllVerbs()` in `subTypeVocabularies.ts`

- Read from `SYNERGY_VERBS` instead of aggregating `SUBCLASS_METADATA`
- Map to `SynergySubTypeOption` (`id`: slugified name, `description` from entry)
- Keep alphabetical sort via existing `sortByName` or `localeCompare`

### 3. Strict validation

**`validateSynergySubType.ts`**: For `type === "verb"`, reject unknown names (same check as `element`):

```ts
if (type === "verb" && !SYNERGY_VERB_NAMES.includes(trimmed)) {
  return { ok: false, reason: `Unknown verb subType: ${trimmed}` };
}
```

**`synergyService.ts`**: Add async vocabulary check for `verb` (mirror `weapon_archetype` block) so create/update cannot bypass sync validation.

### 4. `subclasses.meta.ts` — keep, do not replace

- Continue using per-subclass verbs for `SubclassSection` and `formatSubclassLabel`
- Optionally add a dev-only test asserting every `subclasses.meta` verb name ∈ `SYNERGY_VERB_NAMES` (subclass verbs should be subset of master list)
- Do **not** auto-expand subclass cards to full glossary — subclass UI stays champion-relevant

### 5. Contract & docs

Update:
- `specs/006-synergy-refinement/contracts/catalog-picker-contract.md` — verb source → `synergyVerbs.ts`
- `specs/006-synergy-refinement/spec.md` assumption bullet — verb vocabulary is maintained glossary, not subclass aggregation only

## Files to Touch

| File | Change |
|------|--------|
| `src/data/synergyVerbs.ts` | **New** — master glossary |
| `src/lib/synergies/subTypeVocabularies.ts` | `listAllVerbs()` reads `SYNERGY_VERBS` |
| `src/lib/synergies/validateSynergySubType.ts` | Strict verb name check |
| `src/lib/synergies/synergyService.ts` | Async verb vocabulary validation |
| `src/lib/synergies/subTypeVocabularies.test.ts` | Assert missing staples present; count ≥ 30 |
| `src/lib/synergies/validateSynergySubType.test.ts` | Reject unknown verb; accept Sever, Void Breach, Exhaust |
| `src/lib/synergies/synergyService.test.ts` | Reject invalid verb on create |
| `src/data/subclasses.test.ts` | Optional: meta verbs ⊆ master list |
| `specs/006-synergy-refinement/contracts/catalog-picker-contract.md` | Document new source |

## Test Strategy

1. **Vocabulary completeness**: `listSubTypeOptions("verb")` includes `Sever`, `Void Breach`, `Radiant`, `Weaken`, `Cure`, `Exhaust`, `Devour`, `Amplified`, `Ionic Trace`, `Stasis Shard`
2. **No Base**: verb list still excludes `Base`
3. **No elements**: verb list does not include `Solar`, `Void`, etc.
4. **Validation**: unknown verb `"Foo"` → `INVALID_SYNERGY_SUBTYPE`
5. **Regression**: existing `Scorch` synergy create/update still works
6. **Gate**: `npm run gate`

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Wrong display name (Exhaust vs Exhausts) | Low | Verify one name against in-game tooltip or Bungie glossary before shipping; add alias if DB has old rows |
| Existing synergies with non-glossary verbs | Low | Grep DB/fixtures; migration only if bad rows exist |
| `Suppress` vs `Suppression` | Low | Alias map for legacy `subclasses.meta` / existing synergies |
| Drift between `subclasses.meta` and master list | Low | Subset test in `subclasses.test.ts` |

## Implementation Tasks

1. **T001** Create `synergyVerbs.ts` with full glossary + descriptions sourced from patch notes / dev insight
2. **T002** Refactor `listAllVerbs()` to use master list
3. **T003** Add sync validation in `validateSynergySubType`
4. **T004** Add async validation in `synergyService` for `verb`
5. **T005** Extend unit tests (vocabularies, validate, service)
6. **T006** Update catalog-picker contract; run `npm run gate`

**Estimated diff**: ~250–350 lines (mostly new data file + tests).

## Out of Scope

- Manifest-driven verb extraction from perk text (curated static list is sufficient per FR-007)
- Roll-matching / `mergeSynergyContext` verb detection from inventory (separate feature)
- Changing `SUBCLASS_VERB_COUNTERS` in `championCounters.ts` (champion rules, not synergy picker)

## Success Criteria

- Curator can create `Verb: Sever — {link}` and `Verb: Void Breach — {link}` from picker without free text
- `Exhaust` (confirmed label) appears in verb picker
- Verb picker lists full Bungie keyword glossary (~30+ options), elements remain under Element category only
- Invalid verb names rejected at API layer
