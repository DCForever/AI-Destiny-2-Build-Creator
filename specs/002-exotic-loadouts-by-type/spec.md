# Feature Specification: Exotic Loadouts by Type

**Feature Branch**: `002-exotic-loadouts-by-type`

**Created**: 2026-06-21

**Status**: Draft

**Input**: User description: "I also want to easily see what loadouts have this Exotic Weapon or this Exotic armor piece. I want it to be by type and not limited to that specific Armor piece or weapon."

## Clarifications

### Session 2026-06-29

- Q: When both an armor filter and a weapon filter are active, which loadouts should appear? → A: AND — loadout must match both the armor criterion and the weapon criterion.
- Q: For exact exotic matching, which identity should determine a match when both requested name and resolved hash/name exist? → A: Hash first — match on resolved manifest hash when present; otherwise normalized requested or resolved name.
- Q: For armor slot-type filters, should results require the loadout class to match the exotic armor class? → A: Yes — armor slot filter only includes loadouts where the loadout's class matches the exotic armor's class.
- Q: When contextual discovery is triggered from an opened loadout sheet, what should happen to the UI? → A: Keep sheet open; show matching loadouts in a panel or modal overlay on top.
- Q: When a loadout has no exotic armor or no exotic weapon, how should it behave under the corresponding filter? → A: Exclude — loadouts missing the filtered exotic type are omitted from results for that filter.

### Session 2026-06-21

- Q: What is the desired matching behavior when a user wants to "see all loadouts/builds with this specific exotic" (e.g. Crown of Tempests)? → A: C (both supported: exact specific and slot/type)

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Demonstrated to users independently
  (Per constitution: user stories are the primary vehicle for small testable increments.)
-->

### User Story 1 - Filter Loadouts by Specific Exotic or Exotic Armor Slot Type (Priority: P1)

A user viewing their saved loadouts can filter to see only those using an exact specific exotic armor (e.g. "Crown of Tempests") or those using any exotic armor of a chosen slot type (such as any exotic helmet). Results always show the actual exotic(s) used in each matching loadout.

**Why this priority**: This delivers the core requested capability: users can target a specific named exotic (as in the Crown of Tempests example) or browse broader slot-based patterns like "all my exotic helmet loadouts". Provides immediate standalone value on the loadouts list.

**Independent Test**: A signed-in user with loadouts using Crown of Tempests and other helmets applies an exact "Crown of Tempests" filter and sees only matching loadouts; separately applies a "Helmet" slot filter and sees all helmet exotics (including Crown of Tempests and others). Verifiable using only the loadouts list/filter UI.

**Acceptance Scenarios**:

1. **Given** a signed-in user has loadouts using Crown of Tempests and other exotic helmets/gauntlets, **When** they filter for the specific exotic "Crown of Tempests", **Then** only loadouts using exactly that exotic are shown, each clearly labeled with "Crown of Tempests".
2. **Given** loadouts using various exotic armor slots, **When** they select a slot-type filter (e.g. "Helmet"), **Then** all loadouts with any exotic helmet (including Crown of Tempests and others) are displayed with their actual exotic name.
3. **Given** loadouts filtered by exact exotic or by slot type, **When** the user clears the filter or selects "All", **Then** the full list of their loadouts is restored.
4. **Given** no loadouts match a chosen specific exotic or slot, **When** filtering, **Then** an empty or informative state is shown.

---

### User Story 2 - Filter Loadouts by Specific Exotic Weapon or Weapon Slot Type (Priority: P2)

A user can filter their saved loadouts to those using an exact specific exotic weapon by name or any exotic weapon of a chosen slot/type (such as any exotic in the Kinetic slot). Results identify the specific exotic weapon used.

**Why this priority**: Completes the "Exotic Weapon" part of the request symmetrically to armor. Supports both exact named weapon and slot-type modes for weapons.

**Independent Test**: User filters for a specific exotic weapon name (exact) and sees only those; separately filters for a weapon slot type ("Power"); sees matching. Testable independently of armor filters.

**Acceptance Scenarios**:

1. **Given** loadouts with and without exotic weapons in various slots, **When** filtering by a weapon slot type, **Then** matching loadouts (those with an exotic weapon equipped in that slot) are shown with the specific exotic weapon identified.
2. **Given** a loadout that uses a specific exotic weapon, **When** filtering for that exact weapon name, **Then** only loadouts using precisely that exotic weapon appear.
3. **Given** a loadout that uses an exotic weapon, **When** viewing the filtered results for its weapon slot type, **Then** the loadout appears in the results.

---

### User Story 3 - Discover Loadouts Using the Same Specific Exotic or Slot Type from Context (Priority: P3)

When viewing a saved loadout (in its sheet), the user can easily trigger discovery of other loadouts that use the exact same specific exotic (e.g. Crown of Tempests) or any exotic of the same slot type. The user has access to both exact and broader type-based views.

**Why this priority**: Directly supports the "see what loadouts have this Exotic" goal for a named piece (exact) while also enabling the broader "by type" exploration. Provides contextual navigation value.

**Independent Test**: From a loadout using Crown of Tempests, invoke the exact "this exotic" discovery and confirm only Crown of Tempests loadouts appear; separately invoke the slot-type view and see all exotic-helmet loadouts. Testable with multiple loadouts containing the same specific exotic and different ones in the slot.

**Acceptance Scenarios**:

1. **Given** the user is viewing a loadout using Crown of Tempests, **When** they request loadouts using this exact exotic, **Then** a panel or modal overlay lists only loadouts using precisely Crown of Tempests while the current loadout sheet remains open.
2. **Given** the user is viewing a loadout's exotic armor (specific piece), **When** they request loadouts using the same exotic slot type, **Then** an overlay shows loadouts using any exotic in that slot (Crown of Tempests plus others) without closing the sheet.
3. **Given** the current loadout uses an exotic weapon, **When** requesting the exact weapon or its slot type, **Then** the overlay results match the chosen mode (exact name or any exotic in the weapon slot).
4. **Given** no other loadouts match the chosen exact or type criteria, **When** requesting, **Then** the overlay indicates only the current one (or none others).

---

### Edge Cases

- What happens when a loadout has no exotic armor equipped (if supported by the build model)? **Excluded** from armor exact and armor slot filter results.
- What happens when a loadout has no exotic weapon? **Excluded** from weapon exact and weapon slot filter results.
- How does filtering behave after manifest updates that may change exotic names or add/remove exotics?
- A user has many (50+) saved loadouts: does filtering (exact or slot) remain responsive?
- Does slot-type grouping respect class (e.g. Titan exotic helmets only shown for Titan loadouts)? **Yes** — armor slot filters enforce class match between loadout and exotic armor.
- If a loadout stores both requested name and resolved hash/name, exact matching uses resolved manifest hash when present; otherwise normalized name (requested or resolved).
- Actions from context should not mutate the loadout; they are read-only discovery supporting exact or slot choice.
- Users must be able to choose or switch between exact-specific and slot-type modes for the same "this exotic" context.
- When armor and weapon filters are both active, only loadouts matching both are shown (AND).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to filter their list of saved loadouts by a specific exotic armor piece by name (e.g., exactly "Crown of Tempests").
- **FR-002**: System MUST allow users to filter their list of saved loadouts by the slot/type of the equipped exotic armor (any exotic helmet, etc.). Armor slot filters MUST only include loadouts whose class matches the exotic armor's class (e.g. Titan helmet exotics on Titan loadouts only).
- **FR-003**: System MUST allow users to filter their list of saved loadouts by a specific exotic weapon by name (exact match) and by the slot/type of the equipped exotic weapon.
- **FR-004**: When a user requests to "see loadouts using this exotic" (or equivalent action/context on a specific exotic piece or loadout), the system MUST support both exact match on the specific named item and the option to broaden to any exotic of the matching slot/type.
- **FR-005**: Filter results and discovery views MUST clearly indicate for each loadout the actual specific exotic armor and/or weapon it uses.
- **FR-006**: The system MUST support applying and clearing exact-specific and slot-type filters independently for armor and for weapons. When both armor and weapon filters are active, a loadout MUST match **both** criteria (AND semantics) to appear in results.
- **FR-007**: Users MUST be able to access exact-specific and slot-type based discovery both from a global loadouts list/filter UI and contextually from within an opened loadout's display of its exotic(s). Contextual discovery MUST keep the loadout sheet open and present matching loadouts in a panel or modal overlay.
- **FR-008**: Classification for filtering MUST support both exact exotic name identity and equipment slot (armor slot for armor exotics; weapon slot for weapon exotics); the classification must be stable using manifest data. For exact mode, match resolved manifest hash when available; if hash is unavailable, match normalized exotic name.
- **FR-009**: Filtering and discovery features for loadouts MUST only affect the authenticated user's own saved loadouts.
- **FR-010**: If a loadout does not equip an exotic matching the queried specific name or slot category, it MUST be excluded from the corresponding filter results. Loadouts with no exotic armor MUST be excluded from armor filters; loadouts with no exotic weapon MUST be excluded from weapon filters.

### Key Entities *(include if feature involves data)*

- **SavedLoadout**: Existing persisted user loadout that records the chosen exotic armor (by name) and equipped weapons (with indicators for which are exotic). Used as the source data for exact-name and slot-type queries.
- **ExoticFilter**: A filter criterion that can target either a specific exotic by its exact name (e.g. "Crown of Tempests") or a slot/type category (ArmorSlot or WeaponSlot). Supports both exact and generalized matching.
- **LoadoutFilterCriteria**: Combination of exact exotic name and/or slot-type selections for armor and/or weapons used to select subsets of loadouts for display. When armor and weapon criteria are both set, matching loadouts must satisfy both (AND).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with at least 15 saved loadouts using a mix of exotic types can apply an exact-specific filter (e.g. "Crown of Tempests") or a slot-type filter and view the matching subset in under 5 seconds.
- **SC-002**: From within a displayed loadout sheet, a user can invoke either the exact "this exotic" or the "same slot type" discovery action and see matching loadouts in an overlay panel within 10 seconds.
- **SC-003**: When using the slot-type view for an exotic slot that has 3 or more distinct exotics represented across the user's loadouts, at least 2 different specific exotics appear in the results list. When using exact-specific filter for a popular exotic, only matching loadouts appear.
- **SC-004**: 90% of users who have loadouts using a specific exotic (such as Crown of Tempests) can successfully isolate exactly those loadouts using the specific filter on their first attempt; separately, users can discover broader slot-type alternatives.
- **SC-005**: Applying and removing exact or slot-type filters does not cause loss of loadout data or require page reloads for basic usage.

## Assumptions

- The feature supports two complementary modes for "this exotic" / filtering: (1) exact match on a specific named exotic (e.g. only loadouts with "Crown of Tempests"), and (2) slot/type generalization (any exotic in the same armor slot or weapon slot). "By type" refers to the slot-based mode and UI organization.
- All relevant information for exact name or slot can be resolved from the exotic name stored within the loadout data using the existing manifest (exotic-armor / exotic-weapons stores).
- The feature is scoped to the user's personal saved loadouts (the ones accessible via the /loadouts page and API). It does not include DIM-shared loadouts, generated (unsaved) builds, or community loadouts unless explicitly added later.
- Loadouts may or may not have an exotic weapon (one is optional); armor exotic is typically present but the system should handle absence gracefully.
- Existing loadout data is sufficient for name-based and slot-based filtering; any such queries can use the persisted loadout records without requiring storage schema changes for the initial version.
- Contextual actions support both exact and slot-type discovery; they are read-only and do not alter saved loadouts.
- Users are signed in to access and filter their loadouts (consistent with current loadouts functionality).
- No new data entry or editing of loadouts is introduced by this feature; it augments visibility and navigation among existing ones.
- Finer-grained weapon typing (e.g. "exotic sniper rifles" vs any exotic kinetic) is out of scope for this increment; slot provides the generalization requested for the type mode.
