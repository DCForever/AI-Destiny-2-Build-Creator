# Feature Specification: Instance Disambiguation Picker

**Feature Branch**: `010-instance-disambiguation`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "I want to disambiguate between weapons or armor when I choose them in searches. I need to be able to see all of the perks on a weapon and all of the armor stats. I need to be able to pick a single instance of a weapon so that I can add it to a set or a build. I need the Debug UI to show all of the matching items in a carousel. I need to in the UI be able to remove ones that I do not want to choose from. Example: I have 5 First Ascent Hood helmets. I need to see the Tier, Armor Stats, and the overall Set Bonus (2 & 4 pc) so that I can choose the correct one for the set. Similarly, for weapons, I have 4 Gunburn submachine guns. I need to see all the perks for each so that I can properly add the one I want and to select which perks I want to set when I use when adding to this set."

## Clarifications

### Session 2026-07-03

- Q: When the disambiguation carousel opens, what does it contain? → A: The **owned copies of one item the user selected** from search results (user picks the item first, then disambiguates its copies)—not a mixed carousel of different items.
- Q: When selecting which weapon perks to record on the attachment, which perks can be chosen? → A: **All plug options available in each socket on that copy** (the currently-equipped perk plus the swappable alternatives that copy can hold), defaulting to the equipped perks—not equipped-only, and not the full manifest curated roll pool.
- Q: Is attaching a chosen instance to a build (or build variant) in scope this iteration? → A: **Sets only this iteration**; build/variant attachment reuses the same picker later when a build item attachment surface exists.
- Q: How should the carousel handle owning many copies (e.g. 20+)? → A: **Show all owned copies** ordered by relevance (power/stat descending); **no cap** and no pagination—candidate removal is how the user narrows the field.

## Iteration Scope

**In scope**: A disambiguation experience for choosing among multiple **owned copies of a single item** the user has selected from search results (the user picks the item first, then disambiguates its copies) when adding that item to a **set**. Matching copies are presented in a **carousel** where each card shows the kind-appropriate detail needed to decide: for weapons, **all perks** on that copy (every socket/column, resolved to names); for armor, its **Tier**, all **Armor 3.0 stats**, and its **Set Bonus (2-piece and 4-piece effects)**. Users can **remove candidates** they do not want to consider (ephemeral to the session, never altering inventory), **pick a single instance** to attach, and—for weapons—**select which perks** to record on the attachment (choosing among all plug options each socket on that copy can hold, defaulting to the equipped perks). Debug UI is the delivery and verification surface.

**Out of scope**: Attaching to a **build or build variant** (sets only this iteration; builds reuse this picker in a follow-on when a build item attachment surface exists); a **mixed carousel of different items** (the carousel shows copies of one selected item only); production-polished picker UI; semantic/AI search; keyword description search (delivered by [009-description-search](../009-description-search/spec.md)); changing inventory sync or manifest ingestion; **capping or paginating** the candidate list (all owned copies are shown); virtualization of very large candidate lists; multi-select attachment (attaching more than one instance at once); persisting a user's removed-candidate list across sessions; roll-hunting suggestions; **per-column grouping of weapon perks** — this iteration lists a copy's equipped socket plugs in socket order (FR-003, resolved to names, unresolved shown by identifier), but grouping perks under labeled columns (barrel / magazine / trait columns / origin / intrinsic) requires capturing per-socket column indices during inventory sync and is deferred to a follow-on (see research.md R2 "Follow-on").

**Builds on**: [003-owned-inventory-instances](../003-owned-inventory-instances/spec.md) (per-copy instance listing with resolved plugs, power, location, and a stable per-copy identifier), [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md) (catalog-style set item lookup, armor set-bonus filter, owned-instance stat ranking, and set item attachment), and [001-build-sets-synergies](../001-build-sets-synergies/spec.md) (set item slot rules and replace confirmation).

**Verification**: On the signed-in debug Sets (and Catalog) surfaces, a user searches for a weapon or armor piece they own in multiple copies, steps through matching instances in a carousel, reads full weapon perks or full armor Tier/stats/set-bonus per card, removes copies they do not want, selects one copy (and for weapons, selects its perks), and attaches that specific copy to a set slot. Automated tests cover the candidate-carousel shape, kind-aware detail projection, candidate removal, single-instance selection, and perk selection on attachment.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compare Matching Instances in a Carousel (Priority: P1)

A user adding an item to a set searches for and **selects a single weapon or armor piece** they own; the picker then shows **all owned copies of that one selected item**. Instead of a flat text list, the matching copies appear in a **carousel**—one card per owned instance—so the user can step through and compare candidates side-by-side to decide which specific copy to use. The carousel contains only copies of the one selected item (not a mix of different items). Each card carries enough identity (copy identifier, power, location) to tell the copies apart even before reading full detail.

**Why this priority**: Disambiguation among near-identical copies is the core problem. Today the debug instance list is a flat list keyed by opaque instance IDs; the user cannot comfortably compare "5 First Ascent Hoods" or "4 Gunburns" to choose the right one.

**Independent Test**: On debug Sets/Catalog with synced inventory, select an item owned in three or more copies; confirm the matching copies render as a carousel of distinct cards, each showing a distinguishable identity, and the user can move between cards.

**Acceptance Scenarios**:

1. **Given** a signed-in user with synced inventory who owns five copies of one armor piece, **When** they open the picker for that item, **Then** they see a carousel with five cards, one per owned copy, each visually distinct.
2. **Given** a user viewing the candidate carousel, **When** they move forward and backward through the cards, **Then** each card shows a different owned copy with its own identity (copy identifier, power, location).
3. **Given** an item the user owns exactly one copy of, **When** they open the picker, **Then** the carousel shows a single card and the user can still select it.
4. **Given** an item with no owned copies (or unsynced/unsigned state), **When** the user opens the picker, **Then** they see the existing empty state or sync prompt—not an empty carousel with no explanation.

---

### User Story 2 - See Full Weapon Perks and Full Armor Detail per Copy (Priority: P1)

Each carousel card shows the **kind-appropriate detail** the user needs to judge a copy. For a **weapon**, the card shows **all perks** on that copy—every socket/column (barrel, magazine, both trait columns, origin trait, and any intrinsic/frame)—resolved to readable names. For **armor**, the card shows the piece's **Tier**, all six **Armor 3.0 stats** (Health, Melee, Grenade, Super, Class, Weapons) with values, and the item's **Set Bonus** including both the **2-piece** and **4-piece** effects.

**Why this priority**: The user cannot pick the "correct" copy without seeing what differentiates copies. This is the explicit requirement ("see all of the perks on a weapon and all of the armor stats," "Tier, Armor Stats, and the overall Set Bonus (2 & 4 pc)").

**Independent Test**: For a weapon owned in multiple copies, confirm each card lists every perk on that copy; for an armor piece owned in multiple copies, confirm each card shows Tier, all six stat values, and the 2-piece and 4-piece set-bonus effects.

**Acceptance Scenarios**:

1. **Given** a weapon instance card, **When** it renders, **Then** it lists all perks on that copy grouped by socket/column, each shown as a readable name.
2. **Given** a weapon copy whose plug cannot be resolved to a name, **When** the card renders, **Then** the unresolved perk is still shown (by identifier) so no perk is hidden.
3. **Given** an armor instance card, **When** it renders, **Then** it shows the piece's Tier, all six Armor 3.0 stat values, and the total of those stats.
4. **Given** an armor instance card, **When** it renders, **Then** it shows the item's Set Bonus name with both the 2-piece and 4-piece effect descriptions.
5. **Given** an armor copy whose stat values are missing or partial from sync, **When** the card renders, **Then** it clearly flags stats as incomplete rather than showing blanks or zeros as if final.
6. **Given** an armor piece that has no set bonus (e.g. exotic or standalone legendary), **When** the card renders, **Then** it shows an explicit "no set bonus" indicator rather than an empty area.

---

### User Story 3 - Pick a Single Instance and Attach It (Priority: P1)

From the carousel the user selects **exactly one** copy and attaches it to the target **set** slot (build attachment is a follow-on, out of scope this iteration). The attachment records the **specific instance identity** of the chosen copy—not just the manifest item—so the exact copy the user compared is the one saved.

**Why this priority**: Comparing copies has no value unless the chosen copy can be captured. Recording the specific instance is what makes "pick the correct one for the set" meaningful.

**Independent Test**: Select one copy from a multi-copy carousel and attach it to a set slot; confirm the saved set item references that copy's specific instance identity and roll metadata, and that a different copy would have produced a different saved reference.

**Acceptance Scenarios**:

1. **Given** a candidate carousel with multiple copies, **When** the user selects one card and confirms attachment, **Then** the set item stores that copy's specific instance identity plus roll-relevant metadata.
2. **Given** two copies of the same manifest item with different rolls, **When** the user attaches each in turn, **Then** the resulting set items are distinguishable by their stored instance identity/roll.
3. **Given** a target slot that is already occupied, **When** the user selects a copy to attach, **Then** the existing slot replace confirmation still applies (no regression from set slot rules).
4. **Given** the user attaches a copy to an incompatible slot, **When** they attempt it, **Then** the system prevents attachment consistent with existing slot compatibility rules.

---

### User Story 4 - Select Which Weapon Perks to Record on Attachment (Priority: P2)

When adding a **weapon** copy to a set, the user chooses **which perks** to record on the attachment (e.g. the barrel, magazine, and the two trait-column perks they intend to use). For each socket, the choices offered are **all plug options that socket on that copy can hold**—the currently-equipped perk plus the swappable alternatives available on that copy—so the user can record a non-equipped perk the copy can accept. When the user makes no explicit choice, the copy's currently-equipped perks are recorded by default. Options are scoped to a single copy—not the weapon's full manifest curated roll pool.

**Why this priority**: The user explicitly wants to "select which perks I want to set when adding to this set." It builds on selecting a single weapon instance (US3) and refines what is stored with it.

**Independent Test**: Select a weapon copy whose sockets have multiple available plug options, choose a non-equipped alternative in at least one socket, confirm attachment, and verify the set item records the chosen perks (offering only options that copy can hold).

**Acceptance Scenarios**:

1. **Given** a selected weapon copy, **When** the user opens perk selection, **Then** each socket offers all plug options that copy can hold (equipped perk plus its swappable alternatives), not just the equipped perk and not the full manifest roll pool.
2. **Given** the user selects specific perks (including a non-equipped alternative available on the copy) and confirms, **When** the attachment is saved, **Then** the set item records the selected perks as the roll for that copy.
3. **Given** the user makes no explicit perk selection, **When** they confirm attachment, **Then** the copy's currently-equipped perks are recorded by default.
4. **Given** a socket on the copy exposes only its equipped plug (no alternatives), **When** perk selection renders, **Then** that socket shows the single equipped perk with no alternate choices.
5. **Given** an armor copy (not a weapon), **When** the user attaches it, **Then** no weapon-perk selection step is shown (kind-appropriate flow).

---

### User Story 5 - Remove Unwanted Candidates from the Carousel (Priority: P2)

While comparing copies, the user **removes** candidates they do not want to choose from, narrowing the carousel to the copies they are actually deciding between. Removal affects only the current picking session—it never deletes, moves, or otherwise changes the user's inventory.

**Why this priority**: With many near-identical copies, narrowing the field is what makes the final choice manageable. It depends on the carousel (US1) and does not block attachment (US3).

**Independent Test**: Open a carousel with several copies, remove two of them, confirm they no longer appear as candidates, confirm the removals did not change inventory, and confirm the remaining copies can still be selected.

**Acceptance Scenarios**:

1. **Given** a candidate carousel with several copies, **When** the user removes one card, **Then** that copy no longer appears among the candidates for the current session.
2. **Given** the user has removed one or more candidates, **When** they inspect their inventory afterward, **Then** the removed copies are unchanged and still owned (removal is a UI/session action only).
3. **Given** the user removes candidates down to zero, **When** the carousel is empty, **Then** the user sees a clear empty state with a way to restore/reset the candidate list or re-run the search.
4. **Given** the user removed a candidate, **When** they reset the candidate list or re-run the search, **Then** previously removed copies are eligible to appear again.

---

### Edge Cases

- What happens when the user owns only one matching copy? The carousel shows a single card and selection still works; no forced multi-card layout.
- What happens when the user is signed in but has never synced? Show the existing sync prompt; do not render an empty carousel with no guidance.
- What happens when the user is not signed in? Return the existing authentication requirement; no inventory data is exposed.
- What happens when a weapon plug cannot be resolved to a name? The perk is still displayed by identifier so the roll is not hidden.
- What happens when an armor copy's stat values are missing or partial? The card flags stats as incomplete and does not present placeholder values as final.
- What happens when an armor copy has no set bonus (exotic/standalone)? The card shows an explicit "no set bonus" indicator.
- What happens when armor Tier is not resolvable for a copy? The card shows an explicit unknown/unavailable Tier indicator rather than omitting it silently.
- What happens when the user removes every candidate? An empty state offers restore/reset or re-search; no dead end.
- What happens when the target slot is occupied? Existing replace confirmation applies before the chosen copy is attached.
- What happens when the chosen copy becomes stale (e.g. after a manifest/inventory refresh)? Existing stale-item handling applies; the picker blocks attaching an invalid reference without breaking the compare flow.
- What happens when the candidate list is very large (many copies)? **All** owned copies are shown—no cap and no pagination—ordered with the most relevant first; candidate removal is how the user narrows the field.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a user selects a single item to add to a set and owns multiple copies of it, the system MUST present those copies as a **carousel of individual cards**, one card per owned instance. The carousel MUST contain only copies of the one selected item (not a mix of different items), and MUST show **all** owned copies with **no cap and no pagination**.
- **FR-002**: Each candidate card MUST show a **distinguishable identity** for its copy (stable per-copy identifier plus at least power and location) so users can tell near-identical copies apart.
- **FR-003**: For **weapon** copies, each card MUST display **all perks** on that copy across every socket/column, resolved to readable names.
- **FR-004**: The system MUST display an unresolved weapon perk by its identifier rather than hiding it when a name cannot be resolved.
- **FR-005**: For **armor** copies, each card MUST display the piece's **Tier**.
- **FR-006**: For **armor** copies, each card MUST display all six **Armor 3.0 stat** values (Health, Melee, Grenade, Super, Class, Weapons) and their total.
- **FR-007**: For **armor** copies, each card MUST display the item's **Set Bonus**, including both the **2-piece** and **4-piece** effects (name plus effect text for each tier).
- **FR-008**: The system MUST flag armor stat values as **incomplete** when sync data is missing or partial, rather than presenting placeholder values as final.
- **FR-009**: The system MUST show explicit **unavailable** indicators for armor pieces with no set bonus and for copies whose Tier cannot be resolved.
- **FR-010**: The carousel MUST render the **kind-appropriate** detail automatically—weapon perks for weapons, Tier/stats/set-bonus for armor—based on the item kind, without the user choosing a display mode.
- **FR-011**: Users MUST be able to **select exactly one** candidate copy from the carousel to attach.
- **FR-012**: On attachment, the system MUST record the **specific instance identity** of the selected copy (not only the manifest item identity) along with roll-relevant metadata.
- **FR-013**: When adding a **weapon** copy, users MUST be able to **select which perks** to record on the attachment. For each socket, the offered choices MUST be **all plug options that socket on the copy can hold** (the equipped perk plus its swappable alternatives), scoped to that copy and NOT the weapon's full manifest curated roll pool; when no explicit selection is made, the copy's currently-equipped perks are recorded by default.
- **FR-014**: The system MUST NOT present a weapon-perk selection step when attaching an **armor** copy (kind-appropriate flow).
- **FR-015**: Users MUST be able to **remove** one or more candidate copies from the current picking session so they no longer appear among the candidates.
- **FR-016**: Candidate removal MUST be **session-only** and MUST NOT delete, move, equip, or otherwise modify the user's inventory.
- **FR-017**: The system MUST allow the user to **restore/reset** the candidate list (or re-run the search) so previously removed copies become eligible again.
- **FR-018**: The system MUST show a clear **empty state** when there are no candidates to display (never synced, no owned copies, or all candidates removed), including guidance to sync, re-search, or reset.
- **FR-019**: Attachment via this picker MUST honor existing **slot compatibility** and **occupied-slot replace confirmation** rules with no regression.
- **FR-020**: The disambiguation picker MUST be available on the signed-in **debug** Sets/Catalog surfaces (verification venue), subject to existing debug access rules (authentication required; unavailable in production).
- **FR-021**: When multiple armor copies are shown, the carousel MUST order candidates so the most relevant copy is easy to find (consistent with existing owned-instance stat ordering; power/stat descending), while still showing and allowing the user to browse **all** copies (no cap).
- **FR-022**: Attaching a chosen copy to a **build or build variant** is out of scope this iteration; the picker targets **sets** only. The design MUST NOT preclude reusing the same picker for build attachment in a follow-on.

### Key Entities

- **Candidate set (disambiguation session)**: The ephemeral collection of **all owned copies of the single item the user selected** for the current picking session, including which copies remain after removals. Session-scoped; not capped or paginated; not persisted across sessions and never altering inventory.
- **Candidate card**: One owned copy presented in the carousel, carrying its stable per-copy identity, power, location, and the kind-appropriate detail (weapon perks, or armor Tier + six stats + set bonus).
- **Weapon perk detail**: The perks on a weapon copy, grouped by socket/column, each resolved to a name (or shown by identifier when unresolved); for attachment, each socket also exposes the **available plug options that copy can hold** (equipped perk plus swappable alternatives), from which the user records a selection.
- **Armor detail**: A copy's Tier, six Armor 3.0 stat values (with total and an incomplete flag), and its Set Bonus with 2-piece and 4-piece effects (or an explicit "no set bonus").
- **Selected attachment**: The single chosen copy plus the perks selected to record (for weapons), mapped to a **set** item that stores the specific instance identity and roll metadata for the target slot.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Given several owned copies of the same item (e.g. five copies), a user can identify and select the correct copy for a set in under 60 seconds without an external inventory tool.
- **SC-002**: 100% of weapon candidate cards display every perk present on that copy (all sockets/columns), with unresolved perks shown by identifier rather than omitted.
- **SC-003**: 100% of armor candidate cards display the copy's Tier, all six Armor 3.0 stat values, and both the 2-piece and 4-piece set-bonus effects—or an explicit unavailable indicator when a value cannot be resolved.
- **SC-004**: When a user selects a specific copy and attaches it, the saved set item references that exact copy's instance identity in 100% of attachments (a different copy yields a different saved reference).
- **SC-005**: A user can remove unwanted candidates and reach a final choice, with 0% of removals altering owned inventory in verification tests.
- **SC-006**: For weapon attachments, the perks recorded on the set item match the user's selected perks (or the equipped perks by default) in 100% of verification cases.
- **SC-007**: Zero regression in existing set item attachment, slot compatibility, occupied-slot replace confirmation, and stale-item handling, verified by automated tests.

## Assumptions

- The picker composes existing owned-instance data (from 003) and set item lookup/attachment (from 008); it requires no new inventory sync or manifest ingestion **except** the ability to resolve each copy's **available socket plug options** for weapon perk selection (see next assumption).
- "Armor stats" means the six Armor 3.0 dimensions (Health, Melee, Grenade, Super, Class, Weapons); "Tier" means the Armor 3.0 armor tier; "Set Bonus (2 & 4 pc)" means the set's 2-piece and 4-piece bonus effects—all resolvable from synced instance data and manifest definitions.
- Armor Tier and set-bonus 2/4-piece effects are derivable from existing manifest/instance data; if a value is not currently available it is surfaced with an explicit unavailable indicator rather than blocking the card.
- Weapon perk selection offers, per socket, **all plug options that copy can hold** (equipped plus swappable alternatives). Existing instance data (003) stores only *equipped* plugs, so available socket options are resolved from the copy's socket state and/or manifest socket definitions; when only equipped plugs are resolvable for a copy, perk selection degrades to the equipped perks (which are still recorded by default). The chosen perks are stored as roll metadata on the set item; they do not modify the in-game item and do not define a roll-to-hunt suggestion.
- Candidate removal is a UI/session action only; there is no requirement to persist a removed-candidate list beyond the current session.
- "Add to a set or a build" is delivered against the existing **set** item attachment surface for this iteration; build/variant attachment is a follow-on that reuses the same picker once a build item attachment surface exists.
- Debug Sets/Catalog are the verification venues consistent with prior iterations (signed-in, non-production); production UI inherits behavior when these pickers are promoted.
- Candidate ordering reuses the existing owned-instance ordering (power/stat descending) so the most relevant copy surfaces first; **all** copies are shown (no cap or pagination) and the user can browse and remove any copy.
- Only one instance is attached per selection (single-select); attaching multiple copies at once is out of scope.

## Dependencies

- Owned inventory instance detail and stable per-copy identity ([003-owned-inventory-instances](../003-owned-inventory-instances/spec.md)).
- Catalog-style set item lookup, armor set-bonus filter, owned-instance stat ranking, and set item attachment ([008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md)).
- Set item slot rules and occupied-slot replace confirmation ([001-build-sets-synergies](../001-build-sets-synergies/spec.md)).
- Manifest definitions for resolving weapon perk names, armor set-bonus tier effects, and armor tier.
- Resolution of each copy's **available socket plug options** (beyond the equipped-only plug data provided by 003) to power weapon perk selection; where unavailable, selection degrades to equipped perks.
