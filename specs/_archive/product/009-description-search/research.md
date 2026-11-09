# Research: Description Search for Pickers

**Feature**: 009-description-search  
**Date**: 2026-06-29

## R1: Shared matching module vs inline filters

**Decision**: Add **`src/lib/search/descriptionMatch.ts`** with `matchDescriptionQuery(query, fields)` returning `{ matched: boolean; matchField: 'name' | 'description' | 'other' }` and `compareMatchRank(a, b)` for name-before-description ordering.

**Rationale**: Six+ call sites today duplicate `searchName.includes(q) || name.includes(q)`; spec requires consistent rules (FR-006, FR-007, FR-018) and tier-perk / intrinsic multi-field matching.

**Alternatives considered**:
- Inline one-line `description.includes(q)` per file — rejected (drift risk, untestable ranking).
- Full-text search engine (SQLite FTS, Elasticsearch) — rejected (overkill, constitution scope).

---

## R2: Match algorithm

**Decision**: **Case-insensitive substring** on normalized lowercase text; empty query matches all (existing behavior). Numeric hash param bypasses text match (existing `parseNumericHash` paths in filter resolvers).

**Rationale**: Spec assumptions; aligns with synergy picker and catalog filter behavior today.

**Alternatives considered**:
- Fuse.js for pickers — rejected for small filtered lists (linear scan + limit 50 is faster/simpler).
- Token/word-boundary match — deferred (spec excludes advanced syntax).

---

## R3: Ranking

**Decision**: Sort matches by: (1) `matchField` priority `name` < `description` < `other`, (2) existing `sortByName` tie-break.

**Rationale**: FR-007; "other" covers tier perk description on set rows, intrinsic description on catalog rows.

**Alternatives considered**:
- Fuse score for pickers — rejected (inconsistent with substring spec).

---

## R4: Synergy link picker (`synergyPickerLinks.ts`)

**Decision**: Extend filters:
- `weapon_perk` / `origin_trait`: add `description.toLowerCase().includes(q)` via shared matcher.
- `armor_set_bonus`: add `perk.description` to match; keep flattened row shape; `description` field already returned.

**Rationale**: FR-001, FR-002, FR-012; minimal DTO change.

**Alternatives considered**:
- Search set name only — rejected (clarification requires tier text).

---

## R5: Subtype picker (`subTypeVocabularies.ts`)

**Decision**: `filterSubTypeOptions` matches `option.description` in addition to `option.name`.

**Rationale**: FR-003; abilities/verbs already carry descriptions in options DTO.

---

## R6: Catalog filter resolvers (`perkTraitFilters`, `setBonusFilter`)

**Decision**: Replace `matchByName` with `matchByNameOrDescription` using shared module:
- Perk/trait: OR across all matching hashes (existing `resolvePerkFilter` union).
- Set bonus: match set name OR any tier perk name/description; union `itemHashes`.

**Rationale**: FR-009, FR-015; extends 008 without new query params.

---

## R7: Catalog browse `q` (`filterItems.ts`)

**Decision**: Extend `SearchableCatalogRow` with optional searchable text fields projected at map time:
- Exotic weapons: `intrinsicName`, `intrinsicDescription` (from `ExoticWeaponRecord.intrinsic`)
- Exotic armor: `intrinsicName`, `intrinsicDescription`
- Add keys to `FUSE_OPTIONS` for Fuse search on `q`

**Rationale**: FR-017, FR-013; FR-019 excludes rollable perk descriptions from weapon `q` (use `perk` param).

**Alternatives considered**:
- Join perk descriptions into weapon row at index time — rejected (cross-entity, FR-019).

---

## R8: Manifest search (`itemResolver.ts`)

**Decision**: Per-store Fuse index keys:
- Default stores with `description`: `searchName`, `description`
- `exotic-weapons` / `exotic-armor`: add `intrinsic.description` (project onto searchable wrapper at index build)

**Rationale**: FR-013, FR-014; `WeaponPicker` uses manifest search for weapons.

**Alternatives considered**:
- Single global description index — rejected (entity scope, memory).

---

## R9: UI — descriptions in result lists

**Decision**: Debug synergies page: render `<option>` or list row with secondary description line (truncate ~120 chars + title tooltip). Catalog debug: add optional description column for rows where catalog projection includes intrinsic text (exotics).

**Rationale**: FR-005, US4; API already returns `description` on picker items.

**Alternatives considered**:
- Post-select-only description — rejected (spec US4).

---

## R10: Mods / aspects / fragments / artifacts

**Decision**: Extend `/api/manifest/search` allowed categories (if not already) and `itemResolver` description keys for those stores when users search via manifest route or future pickers.

**Rationale**: FR-014, FR-016; no dedicated picker today—manifest search is the surface.

**Alternatives considered**:
- New picker endpoints — deferred until UI needs them.

---

## R11: Performance caps

**Decision**: Retain existing limits: picker `limit` 50 when `q` non-empty; catalog `limit` param; linear scan acceptable for perk store (~few thousand rows).

**Rationale**: SC-003; gate smoke test optional in tasks.

**Alternatives considered**:
- Precomputed inverted index — deferred unless gate perf fails.
