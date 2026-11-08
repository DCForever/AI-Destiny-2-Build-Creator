# Research: DART-003 Hard Constraints

**Date**: 2026-07-24

## 1. Source of truth

**Decision**: Port `src/lib/builds/destinyBuildConstraints.ts` (+ `destinyBuildConstraints.test.ts`) 1:1 for pure evaluation behavior.

**Rationale**: Server assert wrappers (`assertExoticLimits.ts`, etc.) add IO/entity resolution. Pure functions are the golden surface for multiplatform.

**Alternatives rejected**: Re-implement from DBR prose alone (risk of message/code drift); port only assert wrappers (IO coupling).

## 2. capacityResolved semantics (exit criterion)

**Decision** (matches TS):

```text
capacityResolved = (input.capacityResolved != false)  // default TRUE when omitted
if (capacityResolved && fragmentCount > fragmentCapacity) → ILLEGAL_SUBCLASS_KIT
if (!capacityResolved) → skip fragment-capacity hard block
aspectCount > maxAspects → always hard-block (independent of capacityResolved)
```

**Caller contract**: When aspect fragment capacities cannot be resolved from the entity store (missing names/hashes), callers MUST pass `capacityResolved: false` so fragment limits are not falsely hard-enforced. Server-side `assertSubclassKit` computes capacity and sets this flag.

**Documentation homes**: this research file, quickstart.md, dartdoc on `evaluateSubclassKit` / `SubclassKitEvalInput.capacityResolved`.

## 3. Synergy requirement inclusion

**Decision**: Include `evaluateSynergyRequirement` in this slice.

**Rationale**: Pure, same TS module, uses DART-002 `NO_SYNERGY` hard-gate code. Soft coverage (DART-004) is about coverage tiers, not designation emptiness.

## 4. Soft warning on exotic ability mismatch

**Decision**: When ≥1 ability requirement exists and ≥1 hard mismatch is emitted, also push soft warning `EXOTIC_ABILITY_PIN_PROPOSED` with the fixed TS message. Soft never appears without hard mismatches on this path; soft never blocks save alone.

## 5. Function API shape

**Decision**: Top-level pure functions returning `ConstraintEvaluation`, accepting DART-002 models (or field bags for ability match). Prefer named parameters matching TS for `evaluateSubclassKit` and `evaluateExoticAbilityMatch`.

**Alternatives rejected**: Class-based service with DI (no IO to inject); freezed sealed result hierarchy (overkill; envelope already exists).

## 6. Message parity

Copy TS message strings:

| Code | Message pattern |
| ---- | --------------- |
| TOO_MANY_EXOTICS | `At most one exotic weapon can be equipped (found N)` / armor variant |
| NO_SYNERGY | `Build must designate at least one synergy type` |
| ILLEGAL_SUBCLASS_KIT | `At most M aspects allowed (selected N)` / `Too many fragments (N/C from aspects)` |
| MOD_ENERGY_EXCEEDED | `$slot: mods use $used energy (capacity $cap)` |
| EXOTIC_ABILITY_MISMATCH | `Exotic requires $label "$needed" (kit has "$effective\|none")` |
| EXOTIC_ABILITY_PIN_PROPOSED | `Confirm ability pins to match this exotic's requirements` |
