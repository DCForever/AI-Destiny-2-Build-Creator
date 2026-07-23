# Feature Specification: Create Build Search Pickers

**Feature Branch**: `042-create-build-pickers`

**Created**: 2026-07-23

**Status**: Draft

**Input**: User description: "The Create Build should hide the search fields when an item is selected for each area. Each search field should be scoped to the class. The super search should be scoped to the subclass as well. The exotic armor search should be grouped by slot and sorted by name. They should show any synergies in the result row."

**UI mockup**: [`docs/ui-mocks/create-build-search-pickers.html`](../../docs/ui-mocks/create-build-search-pickers.html)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Collapse Lookup Search After Pick (Priority: P1)

A user creating or editing a build optionally picks a pinned super or exotic armor. After they select a result, the search field, browse/search action, and result list disappear. Only the selected item and a Clear control remain until they clear the selection.

**Why this priority**: Residual search chrome after pick is noisy and invites accidental re-search; collapse is the primary UX ask.

**Independent Test**: Open Create Build, browse and pick a super (or exotic); confirm search UI is gone; Clear restores search UI with no selection.

**Acceptance Scenarios**:

1. **Given** a single-select lookup with no selection, **When** the user views the control, **Then** search/browse UI is available.
2. **Given** the user selects a result, **When** the selection commits, **Then** search field, browse/search action, errors, and result lists are hidden; selected identity and Clear remain.
3. **Given** a selection is shown, **When** the user clears, **Then** selection is removed and search/browse UI returns.
4. **Given** multi-select lookup mode (aspects/fragments elsewhere), **When** items are selected, **Then** search chrome behavior is unchanged by this feature (collapse applies to single-select only).

---

### User Story 2 - Class- And Subclass-Scoped Lookups (Priority: P1)

A user on Create Build (and Edit Build for the same controls) searches exotic armor only within the selected guardian class, and searches pinned supers only within supers valid for the selected class and subclass (same scoping expectations as the debug subclass path).

**Why this priority**: Wrong-class or wrong-subclass options undermine identity and waste time; scoping is required correctness.

**Independent Test**: Set class Titan + a Titan subclass; browse supers and exotic armor; confirm only Titan-valid options appear; change class and confirm exotic clears and super options follow the new class/subclass.

**Acceptance Scenarios**:

1. **Given** class is set, **When** the user browses or searches exotic armor, **Then** results are limited to that class.
2. **Given** class and subclass are set, **When** the user browses or searches pinned supers, **Then** results are limited to supers valid for that class and subclass (not other classes' supers).
3. **Given** Edit Build shows exotic armor and pinned super lookups, **When** the user searches, **Then** the same class / subclass scoping rules apply using the build's class and subclass.

---

### User Story 3 - Exotic Armor Results Grouped With Synergies (Priority: P1)

A user browsing exotic armor on Create/Edit Build sees results grouped by armor slot (helmet, gauntlets, chest, legs, class item), sorted by name within each group. Each result row shows any library synergies linked to that exotic armor item.

**Why this priority**: Slot grouping and synergy context make identity exotic choice faster and more informed.

**Independent Test**: Browse Warlock exotic armor; confirm slot group headers in fixed order, names A-Z within a group, and known linked synergies appear as chips on matching rows; pieces with no links show no chips (not an error).

**Acceptance Scenarios**:

1. **Given** exotic armor search or browse returns multiple slots, **When** results render, **Then** they are grouped by slot in order Helmet → Gauntlets → Chest → Legs → Class item.
2. **Given** multiple results in one slot, **When** results render, **Then** they are sorted by display name (case-insensitive).
3. **Given** the signed-in user has library synergies linked to an exotic armor hash, **When** that item appears in results, **Then** the row shows those synergies (designation labels).
4. **Given** an exotic has no linked library synergies, **When** it appears in results, **Then** the row still selectable with no synergy chips (or equivalent empty presentation — not a failure state).
5. **Given** synergy lookup is unavailable (e.g. temporary failure), **When** results render, **Then** items still appear without blocking pick; synergies simply omit.

---

### Edge Cases

- Optional fields may remain empty; collapse only applies when a selection exists.
- Changing class clears incompatible exotic (existing behavior); super pin resets when subclass changes require it (existing behavior).
- Empty search/browse still respects class/subclass filters.
- Unauthenticated or failed synergy reverse-lookup does not block exotic pick.
- Super/ability rows do not require synergy chips (abilities are not exotic_armor link targets).
- Multi-select pickers used elsewhere are out of collapse scope for this feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Single-select lookup controls used for Create/Edit Build optional exotic armor and pinned super MUST hide search field, search/browse action, and result lists while a selection is present; Clear MUST restore them.
- **FR-002**: Exotic armor lookup on Create/Edit Build MUST scope results to the build's guardian class.
- **FR-003**: Pinned super lookup on Create/Edit Build MUST scope results to supers valid for the build's class and subclass (parity with debug subclass ability scoping).
- **FR-004**: Exotic armor search/browse results MUST be grouped by armor slot in fixed order (Helmet, Gauntlets, Chest, Legs, Class item) and sorted by display name within each group.
- **FR-005**: Each exotic armor result row MUST surface library synergies linked to that item (exotic armor evidence), when available for the signed-in user.
- **FR-006**: Synergy presentation failure or absence MUST NOT prevent selecting an exotic armor result.
- **FR-007**: Multi-select lookup mode MUST retain existing search chrome behavior (no collapse requirement from this feature).

### Key Entities

- **Lookup selection**: Optional single catalog identity (exotic armor hash/name or super name) chosen via search-then-pick.
- **Exotic armor result**: Catalog exotic with class, slot, and display name.
- **Linked synergy summary**: Library synergy designation shown against an exotic armor item for pick-time context.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After picking exotic armor or pinned super on Create Build, a reviewer sees no search field until Clear — 100% of those single-select controls collapse.
- **SC-002**: With a fixed class/subclass, super browse returns only options valid for that pair; exotic browse returns only that class's exotic armor.
- **SC-003**: Exotic browse for a class with items in multiple slots shows those slots as separate labeled groups in the required order, names sorted within each group.
- **SC-004**: For at least one exotic known to be linked in the user's library, the matching result row shows the synergy designation without an extra navigation step.
- **SC-005**: Users can still complete Create Build save with optional exotic/super empty or filled after these UX changes (no new hard gates).

## Assumptions

- Create Build and Edit Build share the same single-select lookup component behavior for these fields.
- Class is already chosen before exotic search; subclass is already chosen before super search on the create form.
- Library reverse-lookup for exotic armor already exists conceptually; this feature surfaces it on result rows.
- Slot labels follow catalog armor slot names (Helmet, Gauntlets, Chest, Legs, Class item).
- Debug-only exotic/super widgets may keep simpler UI unless trivial to align; production Create/Edit is in scope.
- UI mockup at `docs/ui-mocks/create-build-search-pickers.html` is the visual reference for collapsed vs browse states.

## Out of Scope

- Changing build identity rules, create payload schema, or save validation
- Synergy chips on super/ability result rows
- Reworking multi-select aspect/fragment pickers
- Full catalog redesign outside Create/Edit Build lookups
