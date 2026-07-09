# Research: Item Filter Enrichment

**Feature**: 013-item-filter-enrichment  
**Date**: 2026-07-08

## R1 — Ability record gaps

**Decision**: Extend `AbilityRecord` with `subclassAffinities: string[]` and `verbs: string[]` (canonical curated verb names). Keep existing `classType` and `element`. Do not persist raw `plugCategoryIdentifier` on the public record unless needed for debugging tests.

**Rationale**: Spec FR-001–FR-004 require four filter dimensions. Class and element already exist on abilities (`abilities.ts` + `AbilityRecord`). Subclass affinity and effect verbs are the missing structured fields. Aspects/fragments already have partial class/element; v1 stays abilities-first per spec assumptions.

**Alternatives considered**:
- New parallel “enrichment store” — rejected; duplicates entity cache and complicates search.
- Infer subclass only at query time — rejected; filters need stable fields on records for AND semantics and response display.

---

## R2 — Subclass affinity derivation

**Decision**: Three-tier derivation at extract time:

1. **Dedicated plug category** — Parse `{class}.{element}.{kind}` from `plugCategoryIdentifier` (existing ability matcher). Resolve unique subclass via `SUBCLASS_METADATA` where `classType` + `element` match (e.g. `warlock.arc.supers` → Stormcaller).
2. **Shared plugs** — For `shared.*` (and `classType: null`), expand affinities to all subclasses whose `element` matches the ability’s derived element (e.g. shared Arc grenade → Striker, Arcstrider, Stormcaller, plus Prismatic entries only when membership is proven in tier 3—not by element match alone).
3. **Cross-subclass / Prismatic** — Prefer membership via subclass inventory item plug sets (`DestinyPlugSetDefinition` + existing `plugSetHashes` / `socketPlugHashes` helpers). When plug-set traversal cannot prove Prismatic (or other dual) affinity, apply a **small curated affinity override** keyed by ability hash (or stable `searchName`) for known cases required by FR-006 (Phoenix Dive → Dawnblade + Prismatic Warlock).

**Rationale**: Chaos Reach is fully covered by tier 1. Phoenix Dive’s Dawnblade + Prismatic dual affinity cannot be inferred from Solar Warlock category alone. Plug-set membership is the correct long-term source; curated overrides satisfy acceptance examples without blocking the feature on incomplete traversal.

**Alternatives considered**:
- Element-match Prismatic for every Solar/Arc/etc. ability — rejected; over-includes abilities not on Prismatic trees.
- Overrides-only map for all abilities — rejected; unmaintainable at catalog scale.
- Defer Prismatic affinities — rejected; FR-006 explicitly requires Dawnblade **and** Prismatic.

**Subclass name convention**: Use `SUBCLASS_METADATA` keys / `name` values (e.g. `Dawnblade`, `Stormcaller`, `Prismatic Warlock`). Filters match these strings case-insensitively after normalize.

---

## R3 — Effect verb enrichment

**Decision**: Extract-time `verbs: string[]` using:

1. Scan ability description (and linked sandbox perk description when `item.perks` resolves via existing `perkDescription` patterns) with **word-boundary** matches against `SYNERGY_VERB_NAMES` / `resolveVerbSubType()` (including aliases such as Suppress → Suppression).
2. Store only canonical names from `synergyVerbs.ts`.
3. Optional **hash→verbs override** for acceptance anchors (Phoenix Dive → `["Cure"]`, Chaos Reach → `["Jolt"]`) when description wording is ambiguous or uses non-canonical phrasing.
4. **Forbidden**: bare `includes(verb)` / unanchored `RegExp(verb)` as the sole tagging method (FR-008; avoids championCoverage-style false positives).

**Rationale**: Spec requires curated vocabulary alignment and zero false positives from casual description mentions. Whitelist + boundaries is cheap and testable; overrides guarantee SC-001 for the two named examples.

**Alternatives considered**:
- Inherit subclass meta verbs onto every ability — rejected; too coarse (misses ability-specific Cure; over-tags).
- LLM/semantic tagging — out of scope per spec.
- Description-only substring (009 style) as structured verbs — rejected by FR-008.

---

## R4 — Advanced filter surface

**Decision**: Extend `GET /api/manifest/search` to support `category=abilities` and optional structured filters: `kind`, `classType`, `element`, `subclass`, `verb`. Make `q` optional when at least one structured filter is present (structured-only discovery for US2). Return enrichment fields on ability results (`kind`, `classType`, `element`, `subclassAffinities`, `verbs`, `description`). Post-filter with AND semantics across provided dimensions. Index abilities in the resolver with description (and optionally verbs) for text `q`, preserving FR-010.

**Rationale**: Spec FR-005/FR-011 require the same lookup surfaces curators already use. Existing route lacks `abilities` despite tests/UI expectations (`SubclassStructuredForm`, `route.test.ts`). Catalog armor/weapon routes already demonstrate field post-filters (`applyFieldFilters` / `slotFilter`).

**Alternatives considered**:
- New `/api/catalog/abilities` route — deferred; manifest search is the existing ability picker path.
- Synergy subtype picker only — insufficient for class/subclass/element/verb AND queries.

---

## R5 — Scope boundary (aspects / fragments)

**Decision**: v1 enrichment + structured filters target **abilities** only. Aspects keep `classType`/`element` as today; fragments keep `element`. Subclass/verb enrichment for aspects/fragments is a follow-up that reuses the same derivation helpers.

**Rationale**: Spec assumptions and out-of-scope language; Phoenix Dive / Chaos Reach are abilities.

---

## R6 — Validation & cache invalidation

**Decision**: Treat new fields as part of the derived entity store schema. After extractor changes, entity cache for the abilities store must be rebuilt (existing manifest extract/cache pipeline). Validate verb strings against `isKnownVerbSubType` / `resolveVerbSubType` before write. Unknown subclass affinity → empty array (FR-009), not invented names.

**Rationale**: Constitution V (validation-first external data); empty affinities exclude from positive subclass filters per edge cases.

---

## Resolved unknowns

| Topic | Resolution |
|-------|------------|
| Where to store enrichment | On `AbilityRecord` in entity cache |
| Phoenix Dive Prismatic | Plug-set membership + curated override fallback |
| Verb false positives | Whitelist + word boundaries + optional hash overrides |
| Filter API | Extend `/api/manifest/search` |
| Aspects/fragments in v1 | Deferred |
