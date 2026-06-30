# Research: Synergy Refinement

**Feature**: 006-synergy-refinement  
**Date**: 2026-06-29

## R1: Persisting sub-type on Synergy

**Decision**: Add nullable `sub_type` TEXT column on `synergies` table. Required at validation layer when category ∈ {verb, melee, grenade, super, element}; null for primary_weapon, special_weapon, heavy_weapon, dps, healing.

**Rationale**: Sub-type is synergy metadata distinct from link targets (e.g. `Verb: Scorch` vs linked weapon). Single column avoids encoding sub-type in `type` enum explosion (`verb_scorch`, etc.) and keeps filtering by category simple.

**Alternatives considered**:
- Encode in `name` only — rejected (not queryable; breaks auto-name regeneration on edit).
- JSON `metadata` blob — rejected (weaker validation; harder to index).

---

## R2: Sub-type vocabulary sources

**Decision**:

| Category | Source | Notes |
|----------|--------|-------|
| Verb | `listAllVerbs()` from `subclasses.meta.ts` — dedupe by name | No Base option |
| Melee / Grenade / Super | Manifest `abilities` store filtered by `kind`; prepend synthetic `{ id: "base", name: "Base" }` | Full catalog per spec |
| Element | Fixed list in `src/data/synergyElements.ts`: Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic | No Base option |

**Rationale**: Verbs already curated in project metadata; abilities extractor already classifies supers/grenades/melee with descriptions (FR-014 preview for abilities N/A—only link targets). Elements are a closed game set including Kinetic per clarification.

**Alternatives considered**:
- Hard-coded melee/grenade lists in data files — rejected (manifest `abilities` store already maintained).
- Subclass-only ability lists — rejected (incomplete vs “any” ability in game).

---

## R3: Auto-name generation

**Decision**: Pure function `generateSynergyName({ type, subType, linkDisplayName })` in `src/lib/synergies/generateSynergyName.ts`. Server applies on create/update (overrides client-supplied name). Debug UI imports same function for live preview.

**Pattern** (from spec):

- With sub-type: `{CategoryLabel}: {SubType} — {Link}` (em dash)
- Without sub-type: `{CategoryLabel} — {Link}`
- Category labels title-cased (`primary_weapon` → `Primary Weapon`)
- Truncate link portion if total length &gt; 120, preserving category + sub-type prefix

**Rationale**: Single source of truth; satisfies FR-001/FR-015; testable without React.

**Alternatives considered**:
- Client-only naming — rejected (API could accept inconsistent names).
- Store name template separately — rejected (YAGNI).

---

## R4: Synergy type enum changes

**Decision**: Update `SYNERGY_TYPES`:

- Add: `element`
- Rename: `damage` → `dps` (DB stores string; migration on write)
- Remove from creatable enum: `kinetic_weapon`
- Keep read path accepting legacy values; `normalizeSynergyType()` on update maps `kinetic_weapon` → `{ type: "element", subType: "Kinetic" }`, `damage` → `{ type: "dps", subType: null }`

**Rationale**: Matches spec FR-008/FR-009; avoids destructive DB migration for existing rows.

**Alternatives considered**:
- One-shot SQL migration — rejected (out of scope per spec; soft migration on re-save only).

---

## R5: Catalog link pickers (debug UI)

**Decision**:

- **Weapons**: Reuse `GET /api/catalog/weapons?q=&limit=50` — returns `CatalogItem` with description.
- **Origin traits, weapon perks, set bonuses**: New `GET /api/catalog/synergy-pickers/links?kind=&q=&limit=` reading manifest entity stores (`origin-traits`, `weapon-perks`, `set-bonuses`).
- **Sub-types**: New `GET /api/catalog/synergy-pickers/subtypes?category=verb|melee|grenade|super|element`.

All responses include `{ hash?, name, description?, ...kindSpecific }` for description panel (FR-014).

**Rationale**: Reuses proven catalog filter for weapons; dedicated routes keep synergy picker DTOs small and auth-consistent (public catalog + manifest).

**Alternatives considered**:
- Embed full stores in debug page at load — rejected (large payload; stale without manifest refresh).
- Free-text with server validation only — rejected (spec FR-012).

---

## R6: Many-to-many associations

**Decision**: **No schema change.** Existing `synergy_links` + `findSynergiesByTarget` already return all synergies per target (verified in `synergyService.test.ts`). Work limited to debug UI multi-badge display and quickstart verification (US3).

**Rationale**: FR-010/FR-011 already implemented in 001; this feature reinforces UX only.

**Alternatives considered**:
- Junction uniqueness constraint — rejected (would block multiple synergies per target).

---

## R7: Base sub-type matching (suggestions context)

**Decision**: Persist `subType: "Base"` as literal string for melee/grenade/super. Suggestion/reverse-lookup consumers treat Base as wildcard for that ability kind (document in contract; implement in `mergeSynergyContext` if not already generic).

**Rationale**: Explicit stored value keeps auto-name and filters unambiguous (`Melee: Base — …`).

**Alternatives considered**:
- Null subType meaning “all” — rejected (conflicts with “sub-type required” validation).

---

## R8: Debug UI structure

**Decision**: Refactor `SynergiesDebugPage.tsx` incrementally—conditional sub-type select, read-only name field, link picker `<select>` fed by search input debounced to picker APIs, description `<pre>` below picker. No new design system.

**Rationale**: Matches 001 debug-service-contract; minimal scope.

**Alternatives considered**:
- Shared production `SynergyEditor` — rejected (out of scope).
