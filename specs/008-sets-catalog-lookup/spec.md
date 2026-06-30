# Feature Specification: Sets Catalog-Style Item Lookup

**Feature Branch**: `008-sets-catalog-lookup`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Sets needs to be improved. I want the same way of lookup that the Catalog supports. I want to be able to search for perks or origin traits for weapons and for armor I want to filter for set bonus and by highest stat"

## Iteration Scope

**In scope (this iteration)**: Catalog-parity item discovery when adding or replacing items in Sets — searchable weapon lookup by perk or origin trait, searchable armor lookup by set bonus with stat-based ranking of owned copies; debug Sets UI updated to use these flows instead of manual hash entry; APIs or query parameters that support the same filters Catalog users already expect.

**Out of scope (this iteration)**: Production-polished set editor UX; pagination of large result sets; mod-set item lookup beyond existing slot rules; fashion-set cosmetic browsing; automatic roll suggestions triggered from the picker (existing suggest-rolls flow remains separate).

**Verification**: Signed-in debug Sets page exercises browse → filter → select → attach item without typing raw manifest hashes. Automated contract tests cover filter parameters and result shapes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find Weapons for a Set by Perk or Origin Trait (Priority: P1)

A user curating a Weapon Set needs to find weapons that match a desired roll characteristic — a specific perk (e.g. *Incandescent*) or origin trait (e.g. *Cast No Shadows*) — using the same discovery experience they already have in Catalog, rather than looking up manifest hashes manually.

**Why this priority**: Weapon Sets are the most common set type and perk/trait-driven search is the primary gap called out by the user. Without it, set curation is error-prone and slow.

**Independent Test**: On the debug Sets page, start adding a weapon to a Weapon Set, search by perk name and by origin trait name, select a result, and attach it to a slot. The attached item reflects the chosen weapon identity and roll metadata without manual hash entry.

**Acceptance Scenarios**:

1. **Given** a signed-in user adding an item to a Weapon Set slot, **When** they search by weapon name (as Catalog supports today), **Then** matching weapons appear with ownership counts and the user can select one to attach.
2. **Given** the user is adding a weapon to a set, **When** they filter or search by a perk name, **Then** only weapons that can roll or intrinsically include that perk are shown, with clear indication of owned vs unowned.
3. **Given** the user is adding a weapon to a set, **When** they filter or search by an origin trait name, **Then** only weapons with that origin trait are shown.
4. **Given** the user owns multiple copies of a matching weapon, **When** they select a catalog result, **Then** they can view owned instances for that weapon filtered to copies that include the searched perk or origin trait, ordered so the most relevant copy is easy to pick (highest power first, consistent with Catalog instance ordering).
5. **Given** no weapons match the perk or origin trait filter, **When** results are shown, **Then** the user sees an empty state with a clear message — not a silent failure or unrelated items.

---

### User Story 2 - Find Armor for a Set by Set Bonus (Priority: P1)

A user curating an Armor Set needs to find armor pieces belonging to a specific set bonus family (e.g. *Eutechnology*, *AION Adapter*) using a searchable picker, matching how Catalog and synergy link pickers expose set bonus names — not by typing armor hashes.

**Why this priority**: Armor Sets are organized around set bonuses; set-bonus filtering is the user's explicit requirement and is symmetric to weapon perk/trait search.

**Independent Test**: On the debug Sets page, add armor to an Armor Set slot, filter by set bonus name, select a piece, and attach it. Verifiable without weapon flows or production UI.

**Acceptance Scenarios**:

1. **Given** a user adding armor to an Armor Set slot, **When** they filter by set bonus name, **Then** only armor pieces that belong to that set bonus family are shown.
2. **Given** set bonus filter is combined with slot filter (helmet, arms, chest, legs, class item), **When** results are returned, **Then** only armor valid for the target set slot is shown.
3. **Given** the user clears the set bonus filter, **When** they search by armor name, **Then** behavior matches Catalog armor browse (name search, class filter, owned scope).
4. **Given** exotic armor in the catalog, **When** the user filters by a legendary set bonus, **Then** exotic armor not in that set is excluded.

---

### User Story 3 - Rank Owned Armor Copies by Highest Stat (Priority: P2)

A user with multiple owned copies of the same armor piece wants to pick the copy with the best stats for their build when attaching armor to a set — sorted or filtered by highest value in a chosen Armor 3.0 stat (Health, Melee, Grenade, Super, Class, Weapons) or by total stats across all six.

**Why this priority**: Stat quality distinguishes otherwise identical armor copies; the user explicitly asked for "highest stat" ranking. It depends on owned-instance visibility (already delivered) and set-bonus search (P1).

**Independent Test**: With synced inventory containing multiple copies of the same armor hash with different stat rolls, filter by set bonus, select an armor piece, and confirm owned instances are ordered by the selected stat dimension descending (or by total stats when no single stat is chosen).

**Acceptance Scenarios**:

1. **Given** a user viewing owned instances for an armor piece, **When** they choose a stat dimension (e.g. Melee), **Then** copies are ordered highest-to-lowest for that stat; ties break by total stats then power level.
2. **Given** the user does not choose a specific stat, **When** owned instances are listed, **Then** copies are ordered by total stats across all six Armor 3.0 dimensions descending; ties break by power level.
3. **Given** stat data is unavailable for a copy, **When** it appears in the list, **Then** it is listed after copies with known stats and flagged as incomplete — not hidden.
4. **Given** the user selects an owned instance from the ranked list, **When** they confirm attachment to the set slot, **Then** the set item stores the chosen item identity and roll-relevant metadata consistent with existing set item rules.

---

### User Story 4 - Unified Picker Flow in Debug Sets UI (Priority: P2)

A developer or QA tester uses the debug Sets page to add or replace set items through the same browse-and-select interaction model as the debug Catalog page — filters, search box, result list, instance drill-down — instead of free-text `itemHash` and comma-separated perk fields.

**Why this priority**: Delivers end-to-end verification of the lookup APIs and ensures Sets and Catalog stay behaviorally aligned for future production UI.

**Independent Test**: Complete add-item and replace-item flows on debug Sets using only picker interactions; JSON panel shows API requests matching Catalog-style query parameters.

**Acceptance Scenarios**:

1. **Given** the debug Sets "Add / replace item" section, **When** the user opens item lookup for a weapon set, **Then** weapon-specific filters (perk, origin trait, slot, owned scope) are available and raw hash entry is not required for the happy path.
2. **Given** the debug Sets "Add / replace item" section, **When** the user opens item lookup for an armor set, **Then** armor-specific filters (set bonus, class, slot, stat sort) are available.
3. **Given** an occupied slot, **When** the user picks a replacement via the picker and confirms, **Then** the existing two-step replace confirmation (slot occupied → confirm replace) still applies.
4. **Given** unsigned or unsynced inventory state, **When** the user switches to owned scope, **Then** they see the same sync prompt pattern Catalog uses today.

---

### Edge Cases

- What happens when perk or origin trait text matches multiple unrelated perks? Results include all valid weapons; disambiguation uses perk display name and weapon context in the result row.
- What happens when a user searches perk text on a weapon that only has that perk in curated rolls but not intrinsically? Weapons that can roll the perk in at least one column are included; ownership drill-down shows only copies that actually have the perk equipped.
- What happens when set bonus name is a substring of another set? Exact and prefix/substring search behaves like Catalog fuzzy search; longer matches are not excluded unless the user narrows the query.
- What happens when armor has no set bonus (exotic or standalone legendaries)? Such pieces appear only in unfiltered armor browse, not when a set bonus filter is active.
- What happens when multiple stat dimensions tie? Secondary sort uses total stats, then power level, then stable instance identity.
- What happens when manifest refresh marks a picked item stale? Existing soft-stale rules apply; picker blocks attaching newly invalid references but does not break the browse flow.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When adding or replacing items in a Weapon Set, the system MUST provide searchable item lookup equivalent to Catalog weapon browse (name search, slot filter, owned vs all scope, ownership counts).
- **FR-002**: Weapon set item lookup MUST support filtering or searching by perk name so results include only weapons that can include that perk.
- **FR-003**: Weapon set item lookup MUST support filtering or searching by origin trait name so results include only weapons with that origin trait.
- **FR-004**: When a user selects a weapon from lookup and owns multiple copies, the system MUST present owned instances for that weapon, filterable by the active perk or origin trait query, ordered by power descending (consistent with Catalog instance listing).
- **FR-005**: When adding or replacing items in an Armor Set, the system MUST provide searchable item lookup equivalent to Catalog armor browse (name search, slot filter, class filter, owned vs all scope).
- **FR-006**: Armor set item lookup MUST support filtering by set bonus name so results include only armor belonging to the selected set bonus family.
- **FR-007**: When a user selects armor from lookup and owns multiple copies, the system MUST list owned instances ordered by a user-selected Armor 3.0 stat dimension descending, or by total stats across all six dimensions when no single stat is selected.
- **FR-008**: Set item attachment from lookup MUST populate item identity and roll fields automatically; manual hash entry remains available in debug tools only as a fallback, not the primary path.
- **FR-009**: All lookup filters MUST respect the target set slot (weapon slot or armor slot) so users cannot attach an item to an incompatible slot through the picker.
- **FR-010**: Lookup responses MUST distinguish owned vs unowned items and indicate when inventory sync is required for owned scope (same semantics as Catalog).
- **FR-011**: Empty filter results MUST return a clear empty state message, not unrelated items or errors.
- **FR-012**: Slot replace confirmation (occupied slot → confirm replace) MUST still apply when attaching via picker.
- **FR-013**: Lookup performance MUST match Catalog expectations: filtered results return within 5 seconds for typical manifest and inventory sizes.

### Key Entities

- **Set Item Lookup Session**: Ephemeral UI/API context tying a target set, slot, and active filters (perk, origin trait, set bonus, stat sort) to a result list and optional instance drill-down.
- **Lookup Result Row**: A discoverable weapon or armor entry with display name, ownership status, slot compatibility, and pointer to owned instances when applicable — same conceptual shape Catalog users already see.
- **Owned Instance Rank**: An owned copy of an item with resolved roll plugs, stat values (six Armor 3.0 dimensions when available), power, location, and sort keys for stat-based ordering.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can find and attach a weapon to a set by perk or origin trait name in under 2 minutes without looking up manifest hashes externally.
- **SC-002**: Users can find and attach an armor piece to a set by set bonus name in under 2 minutes without manual hash entry.
- **SC-003**: When multiple owned armor copies exist, the highest-stat copy for a chosen dimension appears first in the instance list at least 95% of the time in QA test fixtures.
- **SC-004**: 90% of debug Sets add-item flows complete using only picker interactions (no manual hash fields) in acceptance testing.
- **SC-005**: Filtered lookup requests return results within 5 seconds under normal manifest cache and synced inventory conditions.
- **SC-006**: Zero regression in existing set CRUD, tag filtering, slot replace confirmation, and stale-item handling verified by automated tests.

## Assumptions

- Catalog browse APIs and owned inventory instance listing (features 001 and 003) remain the behavioral reference; this feature extends or composes them for Sets — it does not replace Catalog.
- Synergy link picker vocabulary for origin traits, weapon perks, and armor set bonuses is a valid source of display names for filter options, but set item lookup returns attachable items, not synergy link records.
- "Highest stat" refers to Armor 3.0 stats (Health, Melee, Grenade, Super, Class, Weapons). Default ordering uses total stats; users may optionally narrow to one dimension.
- Weapon instance ordering for perk/trait drill-down uses power descending as the primary tiebreaker (consistent with existing instance listing); stat ranking applies to armor instances only.
- Debug/verification UI scope matches prior iterations: signed-in, non-production surfaces — not polished production set editor.
- Set types other than `weapon` and `armor` (mod, pair, fashion) are unchanged in this iteration; pair sets may reuse weapon or armor lookup when filling exotic slots in a follow-up if needed.
- Stat values for owned armor depend on synced inventory data; if stats are not yet stored for a copy, ranking degrades gracefully per edge-case rules.

## Dependencies

- Existing Catalog filter/search behavior ([001-build-sets-synergies](../001-build-sets-synergies/spec.md) User Story 2).
- Owned inventory instance detail ([003-owned-inventory-instances](../003-owned-inventory-instances/spec.md)).
- Synergy picker link search patterns for perk, origin trait, and set bonus names ([006-synergy-refinement](../006-synergy-refinement/spec.md)).
- Set attachment and slot rules ([001-build-sets-synergies](../001-build-sets-synergies/spec.md) User Story 1).
