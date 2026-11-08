# Research: Lookup-Only Fields

## R1 — Production create controls

**Decision**: Replace free-text subclass / pinned super / exotic armor in `CreateBuildPanel` with class-scoped subclass `<select>` (or chips), `ExoticArmorLookup`, and a pick-only super lookup scoped via existing `buildSubclassSearchParams` + `/api/manifest/search` (`category=abilities`, `kind=super`).

**Rationale**: Debug already proves these patterns; create API already accepts `exoticArmorHash` + `exoticArmorName` + `pinnedSuper`.

**Alternatives considered**: Full `SubclassStructuredForm` on production create — rejected as out of scope (create only needs subclass + optional pinned super, not full kit). Typing with datalist — rejected (still free-form identity).

## R2 — SubclassStructuredForm pick-only

**Decision**: Ability slots show selected value as read-only display + Clear; commit only via search result pick. Aspects/fragments: remove comma-separated free input as the identity path; add via search pick only (list + remove chips). Keep rationale free text. Affinity filter may stay as a search filter string (not stored identity) or become a subclass-affinity select later — keep as filter input this iteration since it does not set stored kit identity.

**Rationale**: Spec requires typing alone must not change stored ability/aspect/fragment values.

**Alternatives considered**: Preload all valid names into `<select>` per slot — nicer UX but heavier; search-then-pick matches existing debug flow and scales with manifest size.

## R3 — Generator weapon types vocabulary

**Decision**: Add `src/data/weaponTypes.ts` with a curated static list of Destiny weapon `itemTypeDisplayName` values (Auto Rifle, Hand Cannon, Pulse Rifle, …) used for checkbox / multi-select include & exclude. Validate selections against that set in form submit helpers.

**Rationale**: Generator runs without requiring a live manifest table in the browser; static list matches how prompts already receive type names. Synergy subtype vocab is manifest-driven and heavier than needed for preferences.

**Alternatives considered**: Fetch from `/api/catalog/synergy-pickers/subtypes?category=weapon_archetype` and filter types — more accurate but couples generator to auth/manifest readiness; deferred.

## R4 — Preferred exotic / weapon on BuildForm

**Decision**: Reuse `ExoticArmorLookup` for preferred exotic (name stored in existing `preferredExotic` string field). For preferred weapon, reuse `ExoticWeaponLookup` or a thin name-based manifest search pick that writes the selected **name** into `preferredWeapon` (LLM prompt still expects names, not hashes).

**Rationale**: No LLM schema change this iteration; lookups ensure the name is a real catalog identity.

**Alternatives considered**: Store hashes in BuildRequest — out of scope (would change LLM schema and prompts).

## R5 — Testing strategy

**Decision**: Extract small pure helpers (e.g. `defaultSubclassForClass`, `weaponTypesFromSelection`, `assignPickedName`) and test those with Vitest; optionally smoke-test payload builders used by CreateBuildPanel / BuildForm. Avoid new RTL dependency unless already present.

**Rationale**: Matches existing co-located unit-test style (`LoadoutDiscoveryOverlay.test.tsx` pattern).

## R6 — No DB / API migration

**Decision**: No `build_synergy` / subclass hash migrations. Persist names (and exotic hash when available) exactly as today, with UI guaranteeing provenance.

**Rationale**: Spec explicitly keeps name-based storage this iteration.
