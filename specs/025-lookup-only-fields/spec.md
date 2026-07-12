# Feature Specification: Lookup-Only Fields

**Feature Branch**: `025-lookup-only-fields`

**Created**: 2026-07-12

**Status**: Draft

**Input**: User description: "Everything should be a lookup except for things like build names, or set names, or notes or the like. Subclass is never a free form text field for instance."

## Standing Rule

Destiny **game concepts** (class, subclass, abilities, aspects, fragments, exotics, weapon types, synergy types/subtypes, set types/slots, catalog link objects, and similar) MUST be chosen via lookup — select, chip, or search-then-pick — never typed as free-form identity values.

**Free text is reserved for**: build names, set names, notes, playstyle, rationale, analyzer loadout paste, and debug-only advanced escape hatches (raw hashes / JSON overrides) that are not the primary path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Build With Lookups Only (Priority: P1)

A user creates a curated build on the production create form. They pick class, subclass from a fixed list for that class, optionally pick exotic armor from a search-and-select list, optionally pin a super from abilities valid for the chosen subclass, and designate synergy types — without typing subclass, exotic, or super names as free text.

**Why this priority**: Production create currently allows free-text subclass/super/exotic; that violates the standing rule and is the most visible gap.

**Independent Test**: Open production create, change class, confirm subclass options reset to that class’s list; pick subclass and (optionally) exotic and pinned super via pickers only; save succeeds with those values.

**Acceptance Scenarios**:

1. **Given** the create-build form, **When** the user views the subclass control, **Then** they can only choose from the canonical subclasses for the selected class — not type an arbitrary string.
2. **Given** the user changes class, **When** the previous subclass is invalid for the new class, **Then** subclass resets to a valid default for the new class.
3. **Given** the user wants exotic armor, **When** they search and select a result, **Then** the build stores that exotic identity; clearing the selection leaves exotic unset.
4. **Given** a subclass is selected, **When** the user pins a super, **Then** they can only pick from supers valid for that subclass (search-then-pick); typing alone does not set the pinned super.
5. **Given** build name is empty or filled, **When** the user saves with at least one synergy type, **Then** name remains free text (optional / auto-derived) while game concepts came only from lookups.

---

### User Story 2 - Debug Subclass Kit Is Pick-Only (Priority: P1)

A developer or curator fills the debug subclass structured form. Super, class ability, movement, melee, grenade, aspects, and fragments are set only by selecting from valid options for the current subclass. Rationale stays free prose.

**Why this priority**: Debug is the full subclass editor; free-typed ability/aspect/fragment strings undermine catalog accuracy even when search assists.

**Independent Test**: On debug builds create/edit, attempt to set an ability by typing without selecting a result — stored value does not change; selecting a search result does.

**Acceptance Scenarios**:

1. **Given** a subclass is chosen, **When** the user searches abilities and selects a result for super (or other ability slot), **Then** that slot updates to the selected name.
2. **Given** an ability search box has typed text, **When** the user does not select a result, **Then** the stored ability value is unchanged.
3. **Given** aspects or fragments, **When** the user adds via search pick, **Then** only names from results are added; comma-typed free lists are not the way to set identity.
4. **Given** the rationale field, **When** the user types prose, **Then** free text is accepted.

---

### User Story 3 - Generator Preferences Use Lookups (Priority: P2)

A user configuring the LLM build generator picks preferred exotic and preferred weapon via search-and-select, and chooses weapon types to include/exclude from a known list — not comma-separated free text. Playstyle and notes remain free text. Subclass remains a class-scoped select.

**Why this priority**: Generator preferences feed prompts; free-text weapon types and exotics reduce reliability but are secondary to production create and debug subclass.

**Independent Test**: On the generator form, select preferred exotic/weapon from lookups and toggle weapon types from the known list; submit payload reflects picks only.

**Acceptance Scenarios**:

1. **Given** preferred exotic (or weapon), **When** the user selects from search results, **Then** the preference stores that identity; clear removes it.
2. **Given** weapon type include/exclude, **When** the user chooses types, **Then** only known weapon types can be selected — not arbitrary typed strings.
3. **Given** playstyle and notes, **When** the user types freely, **Then** those fields remain free text.

---

### Edge Cases

- Changing class or subclass clears or resets incompatible pinned super / ability / aspect / fragment selections.
- Empty exotic / pinned super remains allowed (optional fields).
- Search with no matches shows an empty state; user cannot invent a value.
- Debug advanced hash/JSON overrides may still exist as escape hatches but are not the primary path for game concepts.
- Analyzer loadout paste remains free text (out of scope for conversion).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All in-scope forms MUST treat Destiny game concepts as lookups (select, chip, or search-then-pick). Free text MUST NOT set subclass, abilities, aspects, fragments, exotic identity, weapon type preferences, synergy type/subtype, or set type/slot.
- **FR-002**: Free text MUST remain allowed for build names, set names, notes, playstyle, rationale, analyzer loadout paste, and labeled debug advanced overrides.
- **FR-003**: Production create MUST constrain subclass to the canonical list for the selected class and reset invalid subclass on class change.
- **FR-004**: Production create MUST set optional exotic armor and optional pinned super only via lookup (search-then-pick or equivalent); name-only free typing MUST NOT be the control.
- **FR-005**: Debug subclass structured form MUST set ability, aspect, and fragment identity only from valid options for the current subclass.
- **FR-006**: LLM generator form MUST use lookups for preferred exotic, preferred weapon, and weapon type include/exclude lists.
- **FR-007**: Changing class or subclass MUST clear or replace incompatible previously selected game-concept values so the form never holds an invalid combination from free typing.

### Key Entities

- **Game concept value**: A Destiny identity (subclass name, ability name, exotic item, weapon type, etc.) chosen from a known or searchable catalog — never authored as free text on the primary path.
- **Prose field**: Human label or commentary (name, notes, playstyle, rationale) that may be free text.
- **Lookup control**: UI that presents a fixed list or search results and commits a value only when the user selects an option.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On production create, 100% of subclass, exotic armor, and pinned super values submitted come from lookup selections (or remain empty for optional fields) — zero free-typed identity strings.
- **SC-002**: On debug subclass form, ability/aspect/fragment slots cannot be changed by typing alone; selection updates them in under one pick action after search.
- **SC-003**: On generator form, weapon type preferences contain only known types; preferred exotic/weapon are either unset or a selected catalog identity.
- **SC-004**: A reviewer can walk the three in-scope forms and find no free-text control whose stored value is a Destiny game concept (except labeled debug escape hatches).

## Assumptions

- Canonical subclass lists per class already exist and remain the source of truth for subclass options.
- Manifest/catalog search already supports exotic armor/weapon and subclass-scoped ability/aspect/fragment discovery; this feature reuses those capabilities rather than inventing new catalogs.
- Stored subclass kit fields may continue to use display names (not necessarily hashes) this iteration, as long as values originate from lookups.
- Analyzer loadout paste and debug raw hash/JSON overrides stay as-is.
- Synergy type + subtype and set type/slot pickers already follow the lookup rule and need no redesign beyond the standing rule documentation.
- Production visual polish of debug-origin pickers is best-effort; behavior (pick-only) is the requirement.

## Out of Scope

- Converting analyzer loadout paste to structured entry
- Migrating all stored subclass/ability fields from names to manifest hashes
- Constitution text amendment (standing rule lives in this feature spec; optional later)
- Reworking set item advanced hash fallback beyond keeping it secondary
