# Research: Item Filter Enrichment

**Feature**: 013-item-filter-enrichment  
**Date**: 2026-07-08  
**Updated**: 2026-07-08 (post-clarify sync)

## Clarification lock-ins (Session 2026-07-08)

| Topic | Decision |
|-------|----------|
| Verb completeness | Best-effort catalog-wide whitelist word-boundary tagging + overrides for anchors/ambiguity |
| Prismatic affinity names | Class-qualified: `Prismatic Warlock`, `Prismatic Titan`, `Prismatic Hunter` |
| Shared ability affinities | Element-matched dedicated subclasses; Prismatic only when membership proven |
| Verification surface | Search/lookup structured params **plus** minimal debug UI controls |
| Class filter vs shared | `classType=Warlock` includes Warlock exclusives **and** shared (`null`) |

## Baseline already in tree (post-merge)

`GET /api/manifest/search` already supports `category=abilities`, empty-`q` browse for abilities, and filters `kind`, `classType`, `element`. `classTypeFilter` already includes `classType == null` as shared. `SubclassStructuredForm` already passes `classType`/`element`/`kind` from subclass scope.

**Still missing for this feature**: `subclassAffinities` / `verbs` on `AbilityRecord`, `subclass` + `verb` query params, enriched response fields, extractor derivation, and minimal debug controls for subclass/verb filters.

---

## R1 — Ability record gaps

**Decision**: Extend `AbilityRecord` with `subclassAffinities: string[]` and `verbs: string[]` (canonical curated verb names). Keep existing `classType` and `element`. Do not persist raw `plugCategoryIdentifier` on the public record unless needed for debugging tests.

**Rationale**: Spec FR-001–FR-004 require four filter dimensions. Class and element already exist on abilities. Subclass affinity and effect verbs are the missing structured fields. Aspects/fragments already have partial class/element; v1 stays abilities-first per spec assumptions.

**Alternatives considered**:
- New parallel “enrichment store” — rejected; duplicates entity cache and complicates search.
- Infer subclass only at query time — rejected; filters need stable fields on records for AND semantics and response display.

---

## R2 — Subclass affinity derivation

**Decision**: Three-tier derivation at extract time:

1. **Dedicated plug category** — Parse `{class}.{element}.{kind}` from `plugCategoryIdentifier`. Resolve unique subclass via `SUBCLASS_METADATA` where `classType` + `element` match (e.g. `warlock.arc.supers` → Stormcaller).
2. **Shared plugs** — For `shared.*` (and `classType: null`), expand affinities to all **dedicated** subclasses whose `element` matches the ability’s derived element (e.g. shared Arc grenade → Striker, Arcstrider, Stormcaller). **Do not** add Prismatic affinities by element alone.
3. **Cross-subclass / Prismatic** — Prefer membership via subclass inventory item plug sets (`DestinyPlugSetDefinition` + existing `plugSetHashes` / `socketPlugHashes`). When traversal cannot prove Prismatic (or other dual) affinity, apply a **small curated affinity override** keyed by ability hash (or stable `searchName`) for known cases required by FR-006 (Phoenix Dive → Dawnblade + **Prismatic Warlock**).

**Rationale**: Matches clarify Q3. Chaos Reach is covered by tier 1. Phoenix Dive’s Dawnblade + Prismatic Warlock dual affinity cannot be inferred from Solar Warlock category alone.

**Alternatives considered**:
- Element-match all Prismatic variants for shared items — rejected (clarify Q3).
- Empty affinities for shared items — rejected (clarify Q3).
- Bare `Prismatic` label — rejected (clarify Q2).

**Subclass name convention**: Use `SUBCLASS_METADATA` keys / `name` values (e.g. `Dawnblade`, `Stormcaller`, `Prismatic Warlock`). Filters match these strings case-insensitively after normalize.

---

## R3 — Effect verb enrichment

**Decision**: Extract-time `verbs: string[]` using **best-effort catalog-wide** tagging (clarify Q1):

1. Scan ability description (and linked sandbox perk description when available) with **word-boundary** matches against `SYNERGY_VERB_NAMES` / `resolveVerbSubType()` (including aliases).
2. Store only canonical names from `synergyVerbs.ts`.
3. **hash→verbs override** for acceptance anchors (Phoenix Dive → `["Cure"]`, Chaos Reach → `["Jolt"]`) and ambiguous wording.
4. **Forbidden**: bare `includes(verb)` / unanchored `RegExp(verb)` as the sole tagging method (FR-008).
5. No confident match → empty `verbs[]` (do not invent).

**Rationale**: Clarified completeness target; whitelist + boundaries keeps SC-004 testable without a full hand map.

**Alternatives considered**:
- Anchors-only — rejected (clarify Q1).
- Full curated map for every ability — rejected (clarify Q1).
- Inherit subclass meta verbs onto every ability — rejected; too coarse.

---

## R4 — Advanced filter surface

**Decision**:

1. Extend `GET /api/manifest/search` with `subclass` and `verb` params (AND with existing `kind`/`classType`/`element`). Keep `q` optional when structured filters or browse category rules already allow empty search.
2. **Class filter**: when `classType` is set, include matching exclusives **and** shared (`null`) — already implemented; preserve and document as contract (clarify Q5).
3. Return enrichment fields on ability results: `subclassAffinities`, `verbs`, `description` (plus existing `kind`/`classType`/`element`).
4. **Minimal debug UI** (clarify Q4): add simple subclass + verb filter fields on `SubclassStructuredForm` (or adjacent debug ability search) that pass through to the same search params—not a polished multi-select panel.

**Rationale**: FR-011 after clarify requires lookup **and** minimal debug controls. Class-includes-shared already matches clarify Q5.

**Alternatives considered**:
- API-only verification — rejected (clarify Q4).
- Full debug filter panel — out of scope.
- Exclude shared from class filter — rejected (clarify Q5); would regress current route behavior.

---

## R5 — Scope boundary (aspects / fragments)

**Decision**: v1 enrichment + structured subclass/verb filters target **abilities** only. Aspects/fragments keep today’s class/element fields; reuse derivation helpers later.

**Rationale**: Spec assumptions; Phoenix Dive / Chaos Reach are abilities.

---

## R6 — Validation & cache invalidation

**Decision**: New fields are part of the derived abilities entity store schema. Rebuild abilities cache after extractor changes. Validate verbs via `resolveVerbSubType`; constrain affinities to `SUBCLASS_METADATA` names. Unknown → empty arrays (FR-009).

**Rationale**: Constitution V.

---

## Resolved unknowns

| Topic | Resolution |
|-------|------------|
| Where to store enrichment | On `AbilityRecord` in entity cache |
| Phoenix Dive Prismatic | Plug-set membership + curated override → `Prismatic Warlock` |
| Verb completeness | Best-effort whitelist + overrides |
| Shared affinities | Element-matched dedicated; Prismatic only when proven |
| Class filter | Includes shared |
| Verification UI | Search params + minimal debug controls |
| Aspects/fragments in v1 | Deferred |
