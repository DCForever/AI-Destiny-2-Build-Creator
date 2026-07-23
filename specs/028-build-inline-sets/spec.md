# Feature Specification: Build Inline Sets

**Feature Branch**: `028-build-inline-sets`

**Created**: 2026-07-23

**Status**: Draft

**Input**: User description: "I want to make it so I can from the builds page fully create sets so that I can finish the build. I want it to be a seamless experience"

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [business-rules.md](../business-rules.md)

**Prior slices**: [001-build-sets-synergies](../001-build-sets-synergies/spec.md) (sets, attachments, attach picker), [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md) (set fill / catalog), [012-build-pipeline-consistency](../012-build-pipeline-consistency/spec.md), [026-armor-set-optimizer](../026-armor-set-optimizer/spec.md) (create-sets-from-build API + replace-by-type; production Builds UX deferred), [027-catalog-universal-search](../027-catalog-universal-search/spec.md) (catalog composition entry points)

## Iteration Scope

**In scope (this iteration)**: On the **production Builds** experience (build detail / variant edit — not debug-only), let a signed-in user **fully author Sets without leaving the build journey** so they can finish a combat loadout. That includes: (1) **create empty or named Sets** of combat types needed by the build and **attach them live** in one flow; (2) **fill Set slots** (pick catalog/owned pieces, pins, rolls as already required by Set rules) from the Builds context; (3) **create Sets from the build’s current resolved gear** (snapshot armor/weapons/mods when present) with attach-now and replace-by-type, promoting the existing create-from-build capability into the main UI; (4) clear empty-slot / incomplete-loadout guidance that routes into these set-create/fill actions so finishing the build feels continuous.

**Out of scope (this iteration)**: Redesigning the standalone Sets library shell; Fashion Sets as a finish-build path; full armor **optimizer** search/materialize UI on Builds (remains 026 / later polish); Catalog Universal Build-kit attach; multi-build bulk set factory; sharing/export of newly created Sets beyond normal library privacy; changing Destiny hard constraints or attachment semantics (live/snapshot, exotic exclusivity, slot conflicts).

**Builds on**: Existing Set attach picker, Set fill/catalog rules, create-sets-from-build behavior and BR-OPT-001/002 seeds, completeness rules for default variants.

**Verification**: Signed-in user can open a Build with missing gear, create and fill the Sets they need (or snapshot existing composition into Sets), see them attached on the variant, and reach a complete combat loadout **without** navigating away to Sets as a required step (optional deep-link to Sets for advanced edit is allowed but not required).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create and attach a Set without leaving Builds (Priority: P1)

A Guardian composing a Build needs an Armor, Weapon, or Mod Set that does not exist yet. From the Builds page they create that Set (name + type, optional tags), it is **live-attached** to the active variant, and they stay in the build editor ready to fill slots.

**Why this priority**: Today production Builds can only attach **existing** library Sets. Without create-from-Builds, finishing a new build forces a Sets-library detour and breaks the "finish the build" loop.

**Independent Test**: On a Build with no armor attachment, start create-Set from the Sets section, choose Armor + name, confirm; verify a new Armor Set exists in the library and is live-attached on the variant without opening the Sets page.

**Acceptance Scenarios**:

1. **Given** a signed-in user editing a Build variant, **When** they choose **Create Set** from the build/variant Sets area, **Then** they can set name, combat set type (at least Armor, Weapon, Mod), and optional concept tags, then confirm.
2. **Given** create succeeds with attach-now (default), **When** the flow completes, **Then** the new Set is live-attached to the active variant and appears in the attached list immediately.
3. **Given** the intended name collides for that type, **When** create runs, **Then** the system auto-suffixes a unique name (same class of behavior as create-from-build) and does not fail solely for name collision.
4. **Given** the user is signed out, **When** they attempt create Set from Builds, **Then** they are prompted to sign in and no Set is created.
5. **Given** create completes, **When** the user remains on Builds, **Then** they can continue editing the same build/variant without a forced navigation to the Sets library.

---

### User Story 2 - Fill Set slots from the Builds journey (Priority: P1)

After a Set is attached (new or existing), the user fills empty armor/weapon/mod slots from the Builds context using the same legality rules as Set fill elsewhere (slot fitness, exotic exclusivity, replace confirm, instance pin when owned copies require it), so the build's resolved loadout becomes complete without a Sets-page detour.

**Why this priority**: Creating an empty attached Set does not finish the build; slot fill is required for completeness and equip readiness.

**Independent Test**: Attach or create an empty Armor Set on a variant; from Builds, fill helmet through class item with legal pieces; verify resolved build equipment shows those pieces and Set detail (if opened) matches.

**Acceptance Scenarios**:

1. **Given** a live-attached Armor or Weapon Set with an empty slot, **When** the user chooses **Fill** (or equivalent) for that slot from Builds, **Then** they can pick a legal item (catalog and/or owned, consistent with existing Set fill patterns) and save it to that Set slot.
2. **Given** the slot is occupied, **When** the user replaces the piece, **Then** the same occupied-slot confirmation behavior as Sets apply.
3. **Given** a pick would violate set-wide exotic exclusivity or slot legality, **When** the user attempts it, **Then** the action is blocked with a clear reason (same class as Set fill / BR-UI-001).
4. **Given** the user owns multiple copies of an item and pin rules require a choice, **When** filling from Builds, **Then** instance selection follows existing product pin rules (not a weaker Builds-only path).
5. **Given** fill succeeds on a **live** attachment, **When** the user views the build's resolved loadout, **Then** the new piece appears without a separate "refresh attach" step.
6. **Given** the attachment is **snapshot**, **When** the user needs different gear on the variant, **Then** Builds either guides them to edit snapshot configs where that already exists, or to switch/create a live Set — without silently mutating the library Set in a way that contradicts snapshot semantics.

---

### User Story 3 - Create Sets from current build gear (Priority: P1)

A user who already has gear resolved on a variant (from pins, prior attachments, or composition) captures that gear into library Sets and attaches them in one action from Builds — the production surface for the existing create-from-build capability.

**Why this priority**: Closes the compose to library loop when the build already "looks right" but is not yet backed by reusable Sets; 026 shipped this mainly as API/debug.

**Independent Test**: Build with filled armor (and optionally weapons); run **Create Sets from this build** with attach-now; confirm new Sets contain the expected pieces/instances and replace same-type live attachments per existing rules.

**Acceptance Scenarios**:

1. **Given** a variant with armor filled across one or more slots, **When** the user runs create-from-build including Armor with attach-now, **Then** an Armor Set is created from current claims and live-attached, replacing any prior live Armor attachment on that variant.
2. **Given** weapons and/or mods are filled and included, **When** create-from-build runs, **Then** corresponding Weapon/Mod Sets are created and attached the same way; empty categories are skipped with visible feedback.
3. **Given** the build has exotic armor identity and/or soft stat targets, **When** an Armor Set is created from the build, **Then** optimizer constraint seeding matches existing create-from-build rules (exotic + soft stats; empty set-bonus goals).
4. **Given** nothing filled in selected categories, **When** the user runs create-from-build, **Then** they see a clear nothing-to-create message and no empty junk Sets.
5. **Given** the user chooses create without attach-now, **When** create completes, **Then** Sets are in the library and variant attachments are unchanged.

---

### User Story 4 - Seamless finish-the-build guidance (Priority: P2)

When a build/variant is incomplete (missing combat slots on the default path, or no Sets covering gear), the Builds UI surfaces short, actionable prompts — Create Armor Set, Fill empty slots, Capture current gear into Sets — that start the flows above in context, rather than only showing abstract validation errors.

**Why this priority**: Makes the experience feel seamless; secondary to the actual create/fill capabilities but required for the stated product goal.

**Independent Test**: Open an incomplete default variant; confirm at least one prompt leads into create or fill; after completing gear, prompts clear or switch to ready state.

**Acceptance Scenarios**:

1. **Given** the default variant lacks a full combat loadout, **When** the user views build/variant detail, **Then** they see which gear areas are missing (e.g. armor/weapons) in plain language.
2. **Given** missing armor (or weapons), **When** the user follows the primary CTA, **Then** they enter create-Set, fill-slot, or create-from-build as appropriate — not a dead-end error only.
3. **Given** the loadout becomes complete after set create/fill, **When** the view refreshes, **Then** incomplete guidance for those slots is cleared and success is obvious (attached sets and resolved pieces visible).

---

### User Story 5 - Pair only when needed (Priority: P3)

If the build's exotic story needs a Pair Set, the user can create/attach a Pair from Builds using existing pair/exotic match rules. Fashion remains out of the finish-build path.

**Why this priority**: Pair is less common than Armor/Weapon/Mod for finish-the-build; include lightly so exotic pair workflows are not blocked, without expanding Fashion.

**Independent Test**: Create Pair from Builds with legal exotic weapon/armor identities; attach live; illegal pair armor mismatch blocked.

**Acceptance Scenarios**:

1. **Given** create Set type includes Pair, **When** the user creates and fills within pair slot rules, **Then** attach and validation match existing Pair rules (including armor match to build exotic when required).
2. **Given** Fashion type, **When** viewing finish-build create options, **Then** Fashion is not offered as a primary path to complete combat loadout (may remain available only via normal attach of existing Fashion sets if already supported elsewhere).

---

### Edge Cases

- Variant has mixed live and snapshot attachments → create/fill paths must not corrupt snapshot semantics; replace-by-type only affects live same-type attachments as today.
- Create-from-build while another same-type live Set is attached → detach old, attach new; old Set remains in library.
- Concurrent delete of a Set from another tab → attach/fill fails with clear recovery (pick/create another).
- Name collision storms → auto-suffix continues; user can rename later in Sets.
- Inventory not synced → catalog/wishlist fill still allowed where product already allows; owned-only filters behave as elsewhere.
- Incomplete mod category in create-from-build → skip with message rather than half-written Mod Sets (align with current capability; if mod snapshot is still limited, UI must not claim mods were created).
- Slot conflicts after attaching multiple Sets → existing SLOT_CONFLICT / hard-block messaging still applies before save/equip.
- Non-default variant may remain gapped per domain completeness rules; guidance should not force false "must complete" on optional variants beyond product rules.
- User cancels mid-wizard → no orphan attach; no partial Set unless explicitly saved as empty Set by design (empty Set create is allowed and attached).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Production Builds MUST provide a **Create Set** entry point on the build/variant Sets experience (not debug-only).
- **FR-002**: Create Set from Builds MUST collect at least **name** and **type** (Armor, Weapon, Mod required; Pair allowed) and MAY collect concept tags using the shared vocabulary.
- **FR-003**: Successful Create Set from Builds MUST **live-attach** the new Set to the **active variant** by default (attach-now). Users MAY opt out only if the product exposes create-without-attach; default favors finishing the build.
- **FR-004**: Name uniqueness MUST follow per-user per-type rules with **auto-suffix** on collision for create-from-Builds and create-from-build snapshot flows (never fail solely for name collision).
- **FR-005**: Production Builds MUST allow **filling empty slots** and **replacing occupied slots** on attached Sets that the user is allowed to edit, without requiring navigation to the Sets library as a mandatory step.
- **FR-006**: Slot fill from Builds MUST enforce the same Destiny/product hard constraints as Set fill (slot legality, exotic exclusivity, energy where applicable, replace confirmation, instance pin rules).
- **FR-007**: Production Builds MUST expose **Create Sets from this build** (or equivalent) that snapshots current resolved gear into Sets and supports attach-now with **replace-by-type** for live attachments, consistent with existing create-from-build rules (BR-OPT-001/002).
- **FR-008**: Create-from-build MUST skip empty categories with user-visible feedback and MUST refuse with a clear nothing-to-create outcome when no categories produce Sets.
- **FR-009**: After create/attach/fill mutations, Builds MUST refresh attached-set and resolved-loadout presentation so the user sees the finished state without a manual full page reload.
- **FR-010**: Incomplete combat loadout states on the relevant variant MUST surface **actionable** guidance into FR-001/005/007 flows (not errors alone).
- **FR-011**: All create/fill/attach mutations from Builds MUST require an authenticated owner of the build.
- **FR-012**: Snapshot attachment semantics MUST be preserved: editing a live library Set updates live attachments; snapshot variants do not silently rewrite frozen configs via live Set item edits.
- **FR-013**: Fashion MUST NOT be required or promoted as a path to complete combat loadout in this feature's primary CTAs.
- **FR-014**: Existing SetAttachPicker (attach existing library Set) MUST remain available alongside create/fill so users who already have Sets are not forced to recreate them.
- **FR-015**: Detach remains available; deleting a Set still blocked when in use per existing deletion rules (detach-first).
- **FR-016**: Success feedback MUST name the created/updated Set(s) and confirm attachment when attach-now ran.
- **FR-017**: Optional deep-link to open a Set in the Sets library for advanced edit MAY exist but MUST NOT be the only way to fill slots needed to finish the build.

### Key Entities

- **Build Variant Attachment**: Live or snapshot link from a variant to a library Set; primary vehicle for build gear.
- **Inline Set Create Intent**: Name, type, optional tags, target variant, attach-now flag originating from Builds.
- **Inline Slot Fill Intent**: Target attached Set, slot, item identity, optional instance/perks — same meaning as Set fill, initiated from Builds.
- **Create-from-Build Snapshot Intent**: Build + variant + categories + attach-now + naming prefix; produces one Set per non-empty category.
- **Finish-Build Gap**: User-visible missing combat coverage (e.g. no armor set / empty slots) driving CTAs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In acceptance testing, a user starting from a Build with **no** armor/weapon Sets can create and fill Sets to a **full combat loadout** on the default variant in under **10 minutes** without being required to use the Sets library page.
- **SC-002**: At least **90%** of first-time test users complete **Create Set + attach** from Builds without assistance.
- **SC-003**: At least **90%** of first-time test users complete **fill at least one empty slot** from Builds without assistance.
- **SC-004**: At least **90%** of users with an already-filled variant complete **Create Sets from this build** with attach-now and correctly see Sets on the variant without a second attach step.
- **SC-005**: Zero regressions in SetAttachPicker, Set hard constraints, and create-from-build replace-by-type behavior as verified by automated gates and smoke of prior Builds/Sets paths.
- **SC-006**: In a scripted incomplete-build pass, users always receive at least one actionable CTA toward create or fill (checklist pass/fail) rather than only a blocking error with no next step.

## Assumptions

- "Finish the build" means achieving a **complete combat loadout** on the variant that must be complete (default variant per domain completeness), via **Set attachments** as the gear source of truth — not freeform build-only item pins as a parallel system.
- Production Builds is the home for this work; debug create-from-build may remain but is not sufficient.
- Armor, Weapon, and Mod are the primary types; Pair is supported when needed; Fashion is out of primary CTAs.
- Create-from-build already defined under 026 remains the behavioral baseline for snapshot + attach-now + constraint seeding; this feature **surfaces and completes** it in production UX and ensures empty create + fill cover the cold-start case.
- If mod snapshot from build is still incomplete in the current product, the UI must not over-promise; Weapon/Armor paths remain P1.
- Seamless means **no mandatory context switch** to Sets for create/fill; optional advanced edit in Sets is fine.
- Live attach is the default for new Sets created to finish a build; snapshot remains opt-in via existing attachment controls where already offered.
- Catalog/Universal search may be reused inside fill pickers; this feature does not replace Catalog.
- Unsigned users cannot mutate personal Sets/Builds.

## Dependencies

- Set types, slots, exotic exclusivity, attach live/snapshot: [001](../001-build-sets-synergies/spec.md), BR-SET-*, BR-SLOT-*, BR-ATT-*, BR-CONF-*.
- Set fill / catalog lookup: [008](../008-sets-catalog-lookup/spec.md).
- Create-from-build API semantics, replace-by-type, optimizer constraint seed: [026](../026-armor-set-optimizer/spec.md), BR-OPT-001/002.
- Default variant completeness and identity: domain `DBR-CMPL-*`, `DBR-ID-*`, `DBR-CMP-*`.
- Concept tags on Sets: BR-TAG-*.
