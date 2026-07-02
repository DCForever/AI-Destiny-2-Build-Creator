# Feature Specification: Description Search for Pickers

**Feature Branch**: `009-description-search`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "I want to be able to search the descriptions. As an example, if a perk mentions melee, I want to see the list of perks that have melee in their name or description or synergy so that I can pick from them. I would need to see the description as well so that I can make an informed judgement."

## Iteration Scope

**In scope**: Keyword search across **name and description** (and synergy-related descriptive text where applicable) when discovering selectable game entities—weapon perks, origin traits, synergy link targets, and synergy sub-type options (e.g. melee abilities, grenades, verbs)—in internal picker flows; search results that always surface the entity description alongside the name so users can compare options before selecting; parity extension to catalog-style perk and origin-trait filters used in Sets and Catalog debug tools.

**Out of scope**: Semantic or AI-powered search; searching legendary weapon flavor text or item names beyond existing catalog browse; production-polished picker UI beyond current debug and build-sheet surfaces; pagination or advanced query syntax (quotes, boolean operators); searching user-inventory instance notes.

**Builds on**: [006-synergy-refinement](../006-synergy-refinement/spec.md) (catalog-backed link pickers with read-only descriptions after selection) and [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md) (perk/origin-trait filters by name for weapons and Sets).

**Verification**: Debug synergies and Sets pickers demonstrate find-by-description-keyword (e.g. "melee") with descriptions visible in the result list; automated tests cover match rules and result shape.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find Perks and Traits by Effect Keyword (Priority: P1)

A user curating synergies or sets knows the **effect** they want (e.g. anything involving melee damage) but not the exact perk or origin trait name. They type a keyword such as "melee" and receive a list of matching weapon perks and origin traits where the keyword appears in the **name or description**, each row showing enough description text to judge whether it fits their build.

**Why this priority**: This is the user's explicit example and the core gap—today pickers match names only, so effect-driven discovery fails when the user remembers mechanics, not labels.

**Independent Test**: On the synergies debug link picker, search `melee` for weapon perks; confirm results include perks whose descriptions mention melee even when the name does not, and each result displays its description before selection.

**Acceptance Scenarios**:

1. **Given** a user searching weapon perks in a link picker, **When** they enter a keyword that appears only in a perk's description (not its name), **Then** that perk appears in the results.
2. **Given** a user searching origin traits in a link picker, **When** they enter a keyword matching the trait description, **Then** matching traits are returned with descriptions visible.
3. **Given** a user searching weapon perks, **When** the keyword matches the perk name, **Then** that perk is included (existing name search behavior preserved).
4. **Given** multiple perks match the same keyword, **When** results are shown, **Then** each row shows the perk name and its description (or a clear "no description" indicator when unavailable).
5. **Given** no perks or traits match the keyword in name or description, **When** results are shown, **Then** the user sees an explicit empty state—not unrelated items.

---

### User Story 2 - Find Synergy Sub-Types and Abilities by Description (Priority: P1)

A user defining a Melee, Grenade, Super, or Verb synergy needs to pick a specific ability or effect. They search by gameplay keyword (e.g. "melee", "scorch", "suspend") and see options whose **names or descriptions** match, with descriptions shown in the list so they can distinguish similar-sounding abilities.

**Why this priority**: Synergy sub-type pickers already expose entities with rich descriptions; description search makes category-specific synergy authoring practical without memorizing ability names.

**Independent Test**: On the synergies debug page, open the Melee sub-type picker, search a keyword from an ability description, select a match, and confirm the chosen ability is the one whose description contained the keyword.

**Acceptance Scenarios**:

1. **Given** a user picking a Melee sub-type, **When** they search by a word found only in an ability's description, **Then** that ability appears in the results with its description visible.
2. **Given** a user picking a Grenade or Super sub-type, **When** they search by keyword, **Then** matching options are returned using the same name-or-description rules as perks.
3. **Given** a user picking a Verb sub-type, **When** they search by keyword, **Then** verbs matching name or descriptive text are returned with enough context to choose confidently.
4. **Given** a saved synergy record with an auto-generated name, **When** the user searches synergies by keyword, **Then** synergies whose composed name or linked entity description contains the keyword may appear (supporting "search synergy" in the user's request).

---

### User Story 3 - Description Search in Catalog and Sets Perk Filters (Priority: P2)

A user filtering weapons by perk or origin trait in Catalog or Sets debug tools types an effect keyword rather than an exact perk name. The filter resolves to perks/traits whose name **or** description matches, then shows weapons that roll or include those perks/traits—consistent with description search in synergy pickers.

**Why this priority**: Extends the same discovery model to weapon set curation; depends on shared perk/trait resolution logic from P1.

**Independent Test**: On debug Sets or Catalog, filter weapons by perk keyword that appears only in a perk description; confirm matching weapons are returned.

**Acceptance Scenarios**:

1. **Given** a user filtering weapons by perk in Catalog or Sets, **When** they enter a keyword matching a perk description but not its name, **Then** weapons associated with that perk are included in results.
2. **Given** a user filtering by origin trait, **When** they enter a keyword matching trait description text, **Then** weapons with that trait are included.
3. **Given** perk description search resolves to multiple perks, **When** the filter is applied, **Then** weapons matching **any** of those perks are included (OR semantics across matched perks).
4. **Given** the keyword matches no perk or trait name or description, **When** results are shown, **Then** the user sees a clear empty or unresolved-filter message.

---

### User Story 4 - Informed Selection with Visible Descriptions in Results (Priority: P2)

A user comparing several similar perks or abilities wants to read descriptions **in the search results list** without selecting each item one at a time. Result rows expose description text (full or sensibly truncated with expand option) so they can make an informed choice in a single pass.

**Why this priority**: The user explicitly requires descriptions "so that I can make an informed judgement"; showing description only after selection does not meet that need.

**Independent Test**: Run any description search returning at least three matches; confirm all three show description text in the result list before any selection.

**Acceptance Scenarios**:

1. **Given** search results for perks or traits, **When** the list is rendered, **Then** every result with a known description displays that description (or a readable excerpt with indication of truncation).
2. **Given** a result has no description in source data, **When** it appears in the list, **Then** the row still shows the name and an explicit indicator that description is unavailable.
3. **Given** a user selects a result from the list, **When** the selection is applied, **Then** the same description remains visible in the confirmation or detail preview (no regression from 006-synergy-refinement).

---

### Edge Cases

- What happens when the search query is empty? → Show the default unfiltered or recently-used list per picker; do not error.
- What happens when descriptions contain special characters or formatting? → Search treats them as plain text; display preserves readable formatting where already supported.
- What happens when a keyword matches hundreds of entities? → Results are capped or ranked with most relevant matches first (name match before description-only match); user can refine query.
- What happens when description text is very long? → List shows a readable excerpt with full text available on focus or expand without hiding the name.
- What happens when manifest data is stale or missing descriptions? → Entity still searchable by name; description field shows unavailable state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to search weapon perks by keyword matching **name or description** text (case-insensitive substring).
- **FR-002**: System MUST allow users to search origin traits by keyword matching **name or description** text.
- **FR-003**: System MUST allow users to search synergy sub-type options (Melee, Grenade, Super, Verb, and related ability catalogs) by keyword matching **name or description** text.
- **FR-004**: System MUST include synergy link search results when the keyword matches a synergy's display name or linked entity description (supporting discovery of perks "in synergy" context per user request).
- **FR-005**: System MUST display the entity description in search result rows for perks, traits, abilities, and link targets whenever description text is available.
- **FR-006**: System MUST preserve existing name-only search behavior—name matches continue to return results.
- **FR-007**: System MUST rank or order results so name matches appear before description-only matches when both exist.
- **FR-008**: System MUST show a clear empty state when no entities match the keyword in name or description.
- **FR-009**: Catalog and Sets weapon filters MUST resolve perk and origin-trait parameters using the same name-or-description matching rules as pickers.
- **FR-010**: System MUST indicate when description text is missing for a result rather than showing a blank area.
- **FR-011**: Description search MUST apply in synergies debug link and sub-type pickers at minimum; Sets and Catalog debug perk/trait filters MUST gain parity when FR-009 is delivered.

### Key Entities

- **Searchable entity**: A selectable game concept (weapon perk, origin trait, ability, verb, grenade, super, synergy link target, or synergy record) with a display name and optional long-form description text from curated manifest data.
- **Search query**: A user-entered keyword or phrase used to filter entities by substring match across configured text fields (name, description, synergy display name).
- **Search result**: A matching entity row containing identity (name), description text (or unavailable flag), and fields needed for selection into a synergy, set, or catalog filter.
- **Match field**: Which text field satisfied the query—name, description, or synergy context—used for ordering and optional user feedback.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can find a perk by an effect keyword that appears only in its description (not its name) in under 30 seconds using picker search alone.
- **SC-002**: 100% of search results that have source description data display that description in the result list before selection.
- **SC-003**: At least 95% of description-keyword searches return first results within 2 seconds under normal manifest load (user-perceived responsiveness).
- **SC-004**: Users can complete synergy link selection (search → read description → pick) without entering free-text hashes or undocumented perk names.
- **SC-005**: Catalog or Sets perk filter by description keyword returns the same weapon set as manually identifying the perk by name (functional equivalence for known test fixtures).

## Assumptions

- Curated manifest stores already contain description text for weapon perks, origin traits, abilities, aspects, fragments, and set-bonus perks; no new data ingestion source is required for v1.
- Search is **substring, case-insensitive** matching unless a future iteration adds advanced query syntax.
- "Synergy" in the user request includes synergy records and synergy-linked descriptive context, not only the perk entity in isolation.
- Debug synergies, Sets, and Catalog surfaces are the primary verification venues; production UI inherits behavior when those pickers are promoted.
- OR semantics apply when a keyword matches multiple perks during weapon filtering (weapons rolling any matched perk are included).
- Ranking prefers name matches over description-only matches; further relevance tuning is acceptable if documented.

## Dependencies

- Existing synergy picker and catalog filter infrastructure from specs 006 and 008.
- Manifest entity stores with `name`, `searchName`, and `description` fields for target entity types.
