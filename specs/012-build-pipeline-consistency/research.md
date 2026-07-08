# Research: Build Pipeline Consistency

**Feature**: 012-build-pipeline-consistency  
**Date**: 2026-07-08

## R1 — Where are the gaps: API or debug UI?

**Decision**: Treat this iteration as **debug UX + shared pickers**, with **two small API/behavior fixes** (explicit synergy designation on create; abilities in manifest search). Do not redesign build/set/synergy domain rules.

**Rationale**: Routes for create/update/attach/variant/resolve/compare/suggest already match 001 contracts. `BuildsDebugPage` still uses raw `exoticArmorHash`, free-text `variantId`, subclass JSON textarea, no synergy multi-select, and unfiltered set attach. Sets/Synergies/Catalog already demonstrate catalog-backed lookup patterns.

**Alternatives considered**:
- Full production BuildEditor — out of scope per spec.
- New build APIs for “active variant” server state — unnecessary; selection is client-side.
- Rewrite attachment PATCH to merge-by-default — higher risk; document replace-all and fix UI instead.

---

## R2 — Silent synergy auto-seed on create

**Decision**: **Require explicit `synergyIds` (min 1) on `POST /api/user/builds`**. Remove the create-path behavior that calls `seedDefaultSynergies` then picks `listSynergies(...).slice(0, 1)` when the client omits synergies. Keep `seedDefaultSynergies` available for tests/fixtures only where explicitly needed; debug UI never relies on invisible seeding.

**Rationale**: Spec US1/US4 and FR-002/FR-004 forbid invisible default designation. Current `createUserBuild` hides missing synergies and makes debug “Create (seeds default synergy if needed)” unverifiable.

**Alternatives considered**:
- Keep auto-seed but show it in UI after create — still allows create without user intent.
- Soft-warn only in UI while API still seeds — fails SC-002/SC-005 for API-level clarity.

**Migration**: Update `buildService.test.ts`, integration tests, and any callers that omit `synergyIds` to create a synergy first (or call seed in the test setup and pass ids).

---

## R3 — Exotic armor lookup

**Decision**: Reuse **manifest search** `GET /api/manifest/search?category=exotic-armor&q=` and/or **catalog armor** browse with exotic-only filtering for Builds create + list filter. Persist `exoticArmorHash` + `exoticArmorName` from the selected row (same as Sets catalog attach).

**Rationale**: `exotic-armor` is already a manifest search category. Catalog armor route loads exotic + legendary stores. No new entity store required.

**Alternatives considered**:
- Free-text name with hash lookup — still drift-prone.
- Loadouts exotic filter bar only — tied to loadout DTOs; less general for builds.

---

## R4 — Structured subclass selection

**Decision**: Add a **SubclassStructuredForm** that builds the existing `GeneratedBuild.subclass` object:
1. Class from build `className`.
2. Subclass `name` from `SUBCLASSES_BY_CLASS`.
3. Ability fields (`super`, `classAbility`, `movement`, `melee`, `grenade`) via searchable options from entity cache **abilities**.
4. `aspects` / `fragments` via existing `GET /api/manifest/search?category=aspects|fragments` (filter client-side by class/element using subclass metadata when available).

**API change**: Extend `GET /api/manifest/search` `category` enum with **`abilities`**, plus optional query `kind` (`super|grenade|melee|classAbility|movement`) when present on records.

**Rationale**: Subclass remains name-based strings in DB (no schema migration). Abilities store exists but was missing from search categories. Avoids inventing a parallel subclass DTO.

**Alternatives considered**:
- Keep JSON textarea as primary — fails FR-003.
- Hash-based subclass storage — out of scope; would break resolveHelpers / LLM schema.
- New `/api/catalog/subclass-options` aggregate endpoint — nicer UX later; not required if search + static subclass lists suffice.

---

## R5 — Variant accounting

**Decision**: Load `GET /api/user/builds/:id` after build select; render **VariantSelect** from `build.variants`; store `selectedVariantId` in client state; **block** attach/suggest-sets/resolve/export when unset. Never auto-bind only `variants[0]` without showing the choice (may preselect default variant *visibly*).

**Rationale**: Server has no active-variant concept; bugs come from free-text `variantId` and silent first-variant use in `loadSetsAndSynergies`.

**Alternatives considered**:
- Persist last-selected variant on build — unnecessary for debug iteration.

---

## R6 — Set attach + replace-all semantics

**Decision**: Implement **SetAttachPicker** using `GET /api/user/sets?type=&tags=` (AND tags already in `listSetsByTags`). On attach confirm, **merge** the chosen set into the variant’s current attachments (by set id / type rules as today), then PATCH the **full** `attachments[]` list. Show live/snapshot mode. Confirm target variant name if selection changed mid-flow.

**Rationale**: `replaceAttachments` deletes all rows then inserts — sending a single attachment wipes prior sets (current debug bug risk).

**Alternatives considered**:
- Change API to merge attachments — possible follow-up; UI fix is safer for this iteration.
- Separate POST `/attachments` — new surface; not needed if merge helper is solid.

---

## R7 — Synergy designation after create

**Decision**: Wire **SynergyMultiSelect** to create payload and to **`PATCH /api/user/builds/:id`** with `{ synergyIds }` for edit-after-create. Listing fields: `id`, `name`, `type` (match Synergies debug).

**Rationale**: Update path already replaces `build_synergies` junction rows; only UI was missing.

---

## R8 — Cross-debug lookup parity

**Decision**: Define a **parity matrix** (contract) for entity kinds → required lookup capabilities → pages. Extract shared components so Builds adopts Sets/Catalog/Synergies patterns; leave optional advanced hash fields labeled, collapsed/secondary.

**Parity entities (minimum)**: exotic armor, user set, user synergy, variant (build-scoped). Item/perk/trait/set-bonus already covered on Sets/Synergies/Catalog — reuse, don’t fork.

**Rationale**: Spec SC-004; “consistency” = same discovery model + comparable identity fields, not identical layout.

**Alternatives considered**:
- Single mega-picker package — overkill; start with 4–5 focused components.

---

## R9 — Testing strategy

**Decision**:
- Unit: `createUserBuild` rejects missing synergies; abilities search category; attachment merge helper.
- Contract/route: manifest search accepts `abilities` (+ kind filter if added).
- Manual: quickstart pipeline on `/debug/builds` without typing hashes/IDs.

**Rationale**: Constitution II/III; UI-heavy work still needs service-level regression for the seeding behavior change.

---

## Resolved clarifications

| Topic | Resolution |
|-------|------------|
| New domain rules? | No — enforce existing 001+ rules |
| Schema migrations? | None |
| Production UI? | Out of scope |
| Auto-seed synergies? | Removed from create happy path |
| Attachment PATCH? | Keep replace-all; UI sends full list |
| Subclass storage? | Unchanged JSON name-based shape |
