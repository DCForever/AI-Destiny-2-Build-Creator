# Feature Specification: Finish Slot-First Chrome

**Feature Branch**: `029-finish-slot-first`

**Created**: 2026-07-23

**Status**: Draft

**Input**: User description: "029 — Finish slot-first chrome (from 028 handoff): one-tap Create/Capture in Finish with inherited names; hide link/tags/name/type from Finish primary path; weapons/mods enter slot-first fill immediately; armor manual fill remains fallback until 031"

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [business-rules.md](../business-rules.md)

**Prior slices**: [028-build-inline-sets](../028-build-inline-sets/spec.md) (guided Finish walkthrough v1 — shipped), [026-armor-set-optimizer](../026-armor-set-optimizer/spec.md) (create-from-build capture), [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md) (slot fill)

## Iteration Scope

**In scope**: Simplify the **primary Finish build walkthrough** so creating or capturing a combat Set does not present name, type chips, concept tags, attach mode, or a link-existing picker as required chrome. After one-tap **Create** or preferred **Capture**, the user lands on the **first empty required slot** for that category and continues a **slot-first fill loop** until the category is satisfied or they skip. **Weapons** and **Mods** use this path as the primary finish path. **Armor** uses the same simplified create/capture chrome and slot-first fill as the **manual fallback** until the Armor optimizer Finish path ships (031). Link existing Set, name/type editing, and concept tags remain available on the variant **Sets** tab (and any non-Finish advanced controls), not as Finish primary steps.

**Out of scope**: Armor optimizer goals/results UI (031); optimizer API/`classType`/synergy bonus ranking helpers (030); redesign of the standalone Sets library; Fashion as a finish path; changing Destiny hard constraints, live/snapshot semantics, or replace-by-type attach rules; removing the guided walkthrough shell or category order Armor → Weapons → Mods; multi-build bulk set factory.

**Builds on**: 028 Finish walkthrough, gap evaluation, create-and-attach, capture-from-build, slot fill from Builds, Skip for now, BR-BLD-007 v1.

**Verification**: From an incomplete default variant, start Finish build; for Weapons (and Mods if applicable), create or capture with a single primary action (no name/type/tags/link form), immediately fill empty slots in order, and complete or skip the category without opening the Sets library. Variant Sets tab still supports link/create with full controls.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-tap create then fill (Priority: P1)

A Guardian finishing a build needs a Weapons (or Mods) Set that does not exist yet. In Finish they confirm a single **Create … set** action; the system creates a live-attached Set with an inherited name and type for the current category, then immediately opens the first empty required slot so they can pick gear—without entering a name, choosing type chips, picking tags, or linking a library Set first.

**Why this priority**: 028 Finish still surfaces create/link chrome that feels like a form before any slot is filled; the user asked for slot-first finishing with values inherited from the build.

**Independent Test**: Incomplete default variant with no Weapons Set; Finish → Weapons → Create; confirm a Weapons Set is live-attached with a name derived from the build; first empty weapon slot fill UI appears without a prior name/type/tags step.

**Acceptance Scenarios**:

1. **Given** Finish is on an unsatisfied category that needs a covering Set and Capture is not preferred, **When** the user chooses the primary Create action, **Then** a new Set of that category type is created and live-attached (replace-by-type for same-type live) without collecting name, type, or concept tags in Finish.
2. **Given** create succeeds, **When** the walkthrough continues, **Then** the next step is filling the first empty required slot for that category (not a link picker and not a multi-field create form).
3. **Given** the build has a display name, **When** the Set is created from Finish, **Then** the Set name is derived from the build name and category (with uniqueness auto-suffix on collision) and is shown only as confirmation copy, not as an editable Finish field.
4. **Given** the user is signed out, **When** they attempt Create from Finish, **Then** they are prompted to sign in and no Set is created.

---

### User Story 2 - Slot-first fill loop (Priority: P1)

After a covering Set exists for the current Finish category (just created, captured, or already attached), the walkthrough guides the user through **empty required slots only**, one after another, using the same fill legality as Sets fill elsewhere, until the category is satisfied or the user skips a slot/category.

**Why this priority**: Filling slots is the actual finish work; the walkthrough should not re-present attach/create chrome between slots when a covering Set already exists.

**Independent Test**: Empty live-attached Weapons Set on the variant; Finish → Weapons shows primary → special → heavy empty slots in sequence; filling primary advances to the next empty required slot without returning to create/link.

**Acceptance Scenarios**:

1. **Given** a covering Set is attached with multiple empty required slots, **When** the user is in Finish for that category, **Then** they are guided to fill empty required slots in a stable order for that category (e.g. weapons: primary, then special, then heavy).
2. **Given** the user fills one empty slot successfully, **When** other required slots remain empty, **Then** Finish advances to the next empty required slot without asking create/link again.
3. **Given** all required slots for the category are filled and a covering Set is attached, **When** gaps are re-evaluated, **Then** the category is satisfied and Finish proceeds to the next unsatisfied category (or done).
4. **Given** fill would violate hard constraints (exotic exclusivity, slot legality, etc.), **When** the user attempts the pick, **Then** the action is blocked with a clear reason (same class as Set fill).

---

### User Story 3 - Capture still preferred without form chrome (Priority: P1)

When the category has resolved gear but no covering Set, Finish still prefers **Capture current gear into a Set**, as one primary action that attaches and then either satisfies the category or continues into remaining empty required slots—without a multi-field create form.

**Why this priority**: 028 established Capture-preferred; this slice must not regress that while removing clunky create chrome.

**Independent Test**: Variant with resolved weapon claims and no Weapons Set; Finish → Weapons shows Capture as preferred; after Capture, covering Set is live-attached and any remaining empty required slots enter the fill loop (or category completes if all filled).

**Acceptance Scenarios**:

1. **Given** `capture` is available for the category, **When** Finish shows category actions, **Then** Capture is the preferred primary action and one-tap Create empty remains secondary (not buried behind a full form).
2. **Given** Capture succeeds with attach-now, **When** required slots are already filled via claims, **Then** the category can become satisfied without a mandatory empty-slot tour.
3. **Given** Capture succeeds but some required slots remain empty, **When** Finish continues, **Then** the user enters the slot-first fill loop for remaining empties.

---

### User Story 4 - Finish hides advanced attach chrome; Sets tab keeps it (Priority: P2)

Power users can still **link an existing library Set**, set concept tags, and use fuller create controls from the variant **Sets** tab (or equivalent non-Finish Sets experience). Finish itself does not require those controls to progress.

**Why this priority**: 028 FR-014 and advanced workflows must not disappear; they move out of the primary Finish path.

**Independent Test**: From variant Sets tab, link an existing Armor or Weapons Set and optionally create with name/tags; Finish walkthrough, when opened afterward, treats the category per satisfaction rules without forcing a second link step.

**Acceptance Scenarios**:

1. **Given** the user is in Finish on a category that needs a Set, **When** they view primary actions, **Then** they do not see concept tag pickers, attach-mode toggles, or a mandatory library Set list as the default path.
2. **Given** the user opens the variant Sets tab, **When** they link an existing compatible Set or create with explicit name/tags, **Then** those capabilities still work and Finish gap evaluation reflects the new attachment on refresh/resume.
3. **Given** a covering Set was linked from the Sets tab with empty slots, **When** the user starts or resumes Finish for that category, **Then** they enter the slot-first fill loop (not create chrome).

---

### User Story 5 - Armor uses simplified chrome; optimizer deferred (Priority: P2)

Armor in Finish uses the same one-tap Create/Capture and slot-first manual fill as the interim primary Armor path. Goals → Find kits → compare → apply remains out of this feature (031). Users may still Skip Armor for now.

**Why this priority**: Keeps Finish consistent across categories now without waiting on 030/031; documents the temporary Armor path so 031 can replace the post-create destination later.

**Independent Test**: Finish → Armor → Create one-tap → first empty armor slot fill; no optimizer results UI required for 029 acceptance.

**Acceptance Scenarios**:

1. **Given** Armor is unsatisfied and Capture is not preferred, **When** the user Creates from Finish, **Then** behavior matches one-tap create + first empty armor slot (same chrome rules as Weapons).
2. **Given** this feature only, **When** the user completes Armor via manual slot fill, **Then** Armor can become satisfied without an optimizer kit picker.
3. **Given** future Armor optimizer Finish (031), **When** that ships, **Then** it may replace the post-create destination for Armor without invalidating Weapons/Mods slot-first behavior defined here.

---

### Edge Cases

- Category already has a covering Set with some slots filled → Finish goes to remaining empty required slots only; does not force recreate.
- User Skip for now on a slot or category → gap stays unsatisfied; walkthrough can continue; same as 028.
- Exit mid-fill → confirmed creates/fills persist; resume does not undo work.
- Name collision on inherited name → auto-suffix; user is not blocked.
- Capture nothing-to-create / skipped categories → clear message; no junk empty Sets.
- Snapshot-only covering path → do not silently mutate library Set via live fill; same snapshot guard as 028.
- Non-default variant → optional/softer Finish entry remains; do not force full completeness beyond domain rules.
- Mods category with limited capture support → UI must not claim mods were captured when skipped.
- Link-from-Finish intentionally removed from primary path → users who only use Finish still complete via Create/Capture + fill; linking remains on Sets tab.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Finish walkthrough MUST offer a **one-tap Create** action for an unsatisfied category that needs a covering Set, without requiring name, type selection, concept tags, or attach-mode controls in Finish.
- **FR-002**: One-tap Create from Finish MUST create a Set of the **current category type**, **live-attach** it to the active variant (replace-by-type for same-type live attachments), and use a **name inherited** from the build and category with uniqueness auto-suffix on collision.
- **FR-003**: After successful Create from Finish, when required slots are empty, the walkthrough MUST proceed to the **first empty required slot** for that category (slot-first), not to a link-existing or multi-field create form.
- **FR-004**: When a covering Set is already attached and the category is not satisfied, Finish MUST enter the **slot-first fill loop** for remaining empty required slots without re-prompting Create as the only path.
- **FR-005**: Slot fill from Finish MUST enforce the same hard constraints and instance/pin rules as Set fill elsewhere (FR parity with 028 fill).
- **FR-006**: When Capture is available for the category, Finish MUST present **Capture current gear** as the **preferred** primary action and MUST still offer one-tap Create empty as an alternative without a multi-field form.
- **FR-007**: After Capture with attach-now, Finish MUST re-evaluate gaps and either mark the category satisfied or continue slot-first fill for remaining empty required slots.
- **FR-008**: Finish primary category steps MUST **not** require concept tag collection, library Set browsing/link-as-default, or attach live/snapshot mode toggles.
- **FR-009**: Variant Sets experience MUST retain the ability to **link an existing Set** and to create/edit Sets with explicit name and optional tags (advanced path).
- **FR-010**: Category order, satisfaction definition (covering Set **and** required fills), Skip for now, and Exit/resume semantics from 028 MUST remain in force unless a requirement here explicitly narrows Finish chrome only.
- **FR-011**: Weapons and Mods MUST use slot-first fill as the primary post-create/capture Finish path in this feature.
- **FR-012**: Armor MUST use the same simplified Create/Capture chrome and MAY use slot-first manual fill as the Finish path until a later feature replaces Armor’s post-create destination with optimizer kit selection; this feature MUST NOT require optimizer kit UI.
- **FR-013**: Success feedback MUST identify the created or captured Set name when Create/Capture runs from Finish.
- **FR-014**: All Finish mutations MUST require an authenticated owner of the build.
- **FR-015**: After create/capture/fill mutations, Builds MUST refresh attachments and resolved loadout presentation without a full manual page reload.

### Key Entities

- **Finish Category Step (simplified)**: Ephemeral Finish UI state for one combat category showing preferred Capture (when available), one-tap Create, Skip, and—once a covering Set exists—slot-first fill progression.
- **Inherited Set Create Intent**: Category type + target variant + attach-now + system-derived name (no user name/tags in Finish).
- **Slot-First Fill Cursor**: Current empty required slot within a category’s required slot order for the active covering Set.
- **Finish-Build Gap / Satisfaction**: Unchanged meaning from 028 (covering Set + required fills).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a scripted cold-start Finish pass for Weapons, testers reach the first empty weapon slot fill step in **one primary Create confirmation** after opening the Weapons category (no intermediate name/type/tags/link form).
- **SC-002**: At least **90%** of first-time test users complete Create → fill at least one Weapons slot from Finish without assistance and without opening the Sets library page.
- **SC-003**: Capture-preferred path still completes attach-now for a category with resolved gear in under **2 minutes** in acceptance testing when inventory/claims are already present.
- **SC-004**: Zero regressions in gap order (Armor → Weapons → Mods), Skip-for-now semantics, and Sets-tab link/create advanced path as verified by automated gates and a short smoke checklist.
- **SC-005**: In usability review, Finish category steps do not present concept tags or attach-mode controls as required fields (pass/fail checklist).

## Assumptions

- 028 guided Finish walkthrough remains the shell; this feature reshapes **create/capture/fill chrome inside Finish**, not a greenfield walkthrough.
- Inherited names follow the product pattern already used for create-from-build style naming (build name + category label) with auto-suffix.
- Required slot orders match existing completeness rules (armor five slots; weapons primary/special/heavy; mods per existing 028 mod satisfaction rules).
- Link-existing is intentionally secondary (Sets tab), not deleted from the product.
- Armor optimizer Finish (031) will later change Armor’s happy path after create; 029 deliberately keeps Armor manually fillable so Finish stays usable.
- Discrete Create Set on Sets tab may keep richer fields; Finish does not.
- Unsigned users cannot mutate Sets/Builds.
- Domain completeness and Sets-as-gear-source-of-truth rules (DBR-CMP-*, DBR-CMPL-*) are unchanged.

## Dependencies

- [028-build-inline-sets](../028-build-inline-sets/spec.md) shipped walkthrough, gaps, create-and-attach, capture, fill-from-Builds, BR-BLD-007.
- Set fill legality: [008](../008-sets-catalog-lookup/spec.md).
- Capture/replace-by-type: [026](../026-armor-set-optimizer/spec.md).
- Follow-ons (not blocking 029): [030 foundation and 031 Armor optimize UI](../028-build-inline-sets/spec.md#follow-on-features-post-v1) per 028 handoff.
