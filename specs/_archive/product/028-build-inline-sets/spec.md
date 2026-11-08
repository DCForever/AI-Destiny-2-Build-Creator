# Feature Specification: Build Inline Sets

**Feature Branch**: `028-build-inline-sets`

**Created**: 2026-07-23

**Updated**: 2026-07-23

**Status**: Shipped v1 — follow-ons 029–031

**Input**: User description: "I want to make it so I can from the builds page fully create sets so that I can finish the build. I want it to be a seamless experience"

**Domain sources**: [domain-business-rules.md](../domain-business-rules.md), [domain-acceptance-criteria.md](../domain-acceptance-criteria.md), [business-rules.md](../business-rules.md)

**Prior slices**: [001-build-sets-synergies](../001-build-sets-synergies/spec.md) (sets, attachments, attach picker), [008-sets-catalog-lookup](../008-sets-catalog-lookup/spec.md) (set fill / catalog), [012-build-pipeline-consistency](../012-build-pipeline-consistency/spec.md), [026-armor-set-optimizer](../026-armor-set-optimizer/spec.md) (create-sets-from-build API + replace-by-type; production Builds UX deferred), [027-catalog-universal-search](../027-catalog-universal-search/spec.md) (catalog composition entry points)

## Clarifications

### Session 2026-07-23

- Q: How should the primary finish-the-build experience work when pieces are missing? → A: **One guided walkthrough** (Option B): detect gaps → for each gap, create or link a Set → fill empty slots → next gap until done (or user exits). Discrete one-off CTAs alone are not the primary incomplete-build path.
- Q: In what order should the guided walkthrough present missing combat pieces? → A: **Armor → Weapons → Mods** (Option B); skip categories already satisfied.
- Q: When is a category satisfied so the walkthrough can skip it? → A: **Covering Set attached and required slots filled** (Option C). Empty attached Sets still need fill steps; filled gear without a covering Set still needs create/link (or create-from-build).
- Q: Can the user skip or defer a gap and still continue the walkthrough? → A: **Yes — Skip for now** on a category or empty slot (Option B). Skipped items remain on the remaining-gaps list; the build stays incomplete until satisfied. User may exit entirely and resume later.
- Q: When the variant already has resolved gear but no covering Sets, how should the walkthrough handle that category? → A: **Prefer Capture current gear into a Set** (create-from-build for that category) when resolved gear exists (Option A); also allow create empty Set and link existing Set.

### Session 2026-07-23 (post-v1 direction — not 028 tasks)

- Post-v1 product direction (Warp plan slot-first + Armor optimizer): Armor primary path becomes create → set-bonus/stat goals → run 026 optimizer → top-3 kit compare → apply-combination; weapons/mods stay slot-first after one-tap create; Finish hides link/tags/name/type chrome; UI pairing **V2+V5** wide / **V6** phone. **Implemented under follow-on features 029–031, not by reopening 028 US/FR acceptance.**

## Iterations

### Iteration 2026-07-23: Freeze v1 and hand off to 029–031

**Change**: Mark 028 shipped v1; defer slot-first Finish chrome and Armor optimizer Finish path to three follow-on specs.
**Scope**: Feature-wide
**Artifacts updated**: spec.md, plan.md, tasks.md, data-model.md, research.md, quickstart.md, business-rules.md (light)
**Tasks added**: —
**Tasks removed**: —
**Tasks marked complete**: T001–T029 (already complete before iteration)

## Iteration Scope

**In scope (this iteration / v1 shipped)**: On the **production Builds** experience (build detail / variant edit — not debug-only), let a signed-in user **finish a combat loadout via a guided walkthrough** that stays on Builds. The walkthrough **detects missing pieces**, then **step by step** lets the user **create a new Set or link an existing Set** for each gap and **fill empty slots** until the loadout is complete or they exit. Supporting capabilities: (1) create empty/named combat Sets and live-attach; (2) attach/link existing library Sets; (3) fill/replace Set slots under existing Set rules; (4) optional create-Sets-from-current-gear (snapshot) with attach-now / replace-by-type when gear is already resolved; (5) clear incomplete-loadout entry into the walkthrough.

**Out of scope (this iteration / v1)**: Redesigning the standalone Sets library shell; Fashion Sets as a finish-build path; full armor **optimizer** search/materialize UI on Builds; Catalog Universal Build-kit attach; multi-build bulk set factory; sharing/export of newly created Sets beyond normal library privacy; changing Destiny hard constraints or attachment semantics (live/snapshot, exotic exclusivity, slot conflicts).

**Deferred to follow-on features (not 028 v1)**:
- **029** — Slot-first Finish create chrome (hide link/tags/name/type from Finish primary path; one-tap create/capture → first empty slot for weapons/mods; armor manual fill as fallback only).
- **030** — Optimizer foundation: empty-set optional `classType`, synergy set-bonus ranking helpers, constraints payload helpers + tests.
- **031** — Armor Finish optimize UI: V2+V5 wide workspace, V6 phone rail, constraints editor, top-3 compare, apply-combination from Finish.

**Builds on**: Existing Set attach picker, Set fill/catalog rules, create-sets-from-build behavior and BR-OPT-001/002 seeds, completeness rules for default variants.

**Verification**: Signed-in user can open a Build with missing gear, start the **guided finish walkthrough**, create or link Sets and fill slots step by step (or snapshot existing composition when applicable), see attachments on the variant, and reach a complete combat loadout **without** navigating away to Sets as a required step (optional deep-link to Sets for advanced edit is allowed but not required).

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

### User Story 4 - Guided finish walkthrough for all missing pieces (Priority: P1)

When a build/variant is incomplete, the user starts a **guided walkthrough** that lists missing combat pieces in order and, for each gap, lets them **create a new Set or link an existing library Set**, then **fill empty slots** for that Set, then advances to the next gap until the loadout is complete or they exit. This is the primary incomplete-build path—not only scattered CTAs.

**Why this priority**: User-stated goal is step-by-step create-or-link of all missing pieces; without a single walkthrough, finishing stays fragmented.

**Independent Test**: Open an incomplete default variant; start Finish build; complete at least two different gaps (e.g. attach/create Armor Set and fill one slot, then Weapon path); exit and resume; confirm progress persists on the variant.

**Acceptance Scenarios**:

1. **Given** the default variant lacks a full combat loadout, **When** the user views build/variant detail, **Then** they see which gear areas are missing and a primary **Finish build** (or equivalent) action that starts the guided walkthrough.
2. **Given** the walkthrough is active, **When** the user is on a gap step, **Then** they can **create a new Set** or **link an existing compatible Set** for that gap before or as part of filling slots.
3. **Given** a gap's Set is attached with empty slots, **When** the user continues the walkthrough, **Then** they are guided to fill those slots under existing Set rules before the walkthrough treats that gap as done.
4. **Given** the user completes or skips through all remaining gaps, **When** the loadout meets completeness for the variant, **Then** the walkthrough ends with clear success and incomplete guidance clears.
5. **Given** the user exits mid-walkthrough, **When** they return later, **Then** progress already saved (created/linked Sets, filled slots) remains; they can restart the walkthrough for remaining gaps without undoing prior work.
6. **Given** multiple categories are missing, **When** the walkthrough runs, **Then** it addresses **Armor before Weapons before Mods**, skipping categories already satisfied.
7. **Given** an Armor Set is attached but armor slots are still empty, **When** the walkthrough evaluates Armor, **Then** it does **not** skip Armor and continues into fill steps. **Given** armor slots appear filled without a covering Armor Set, **When** evaluated, **Then** Armor is not skipped until create/link (or create-from-build) attaches a covering Set.
8. **Given** the user chooses **Skip for now** on Mods (or an empty slot), **When** the walkthrough continues, **Then** later categories or end state are reachable, the skipped gap remains unfinished, and incomplete guidance still reflects that gap.
9. **Given** armor is resolved on the variant but no Armor Set is attached, **When** the walkthrough reaches Armor, **Then** **Capture current gear into a Set** is the preferred action and create-empty / link-existing remain available.

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
- User cancels mid-wizard / exits guided walkthrough → no orphan attach from an unconfirmed step; Sets already confirmed created/linked and slots already filled remain; empty Set create is allowed once confirmed and attached.
- Guided walkthrough mid-progress → remaining gaps still available on resume; completed gaps are not re-forced unless the user undoes attachments/fills.
- Walkthrough category order Armor → Weapons → Mods; if user fills Weapons first outside the walkthrough, resume skips Armor only when Armor is satisfied.

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
- **FR-010**: Incomplete combat loadout states on the relevant variant MUST surface **actionable** entry into the **guided finish walkthrough** (FR-018), not errors alone. Supporting entry into FR-001/005/007 outside the walkthrough remains allowed.
- **FR-011**: All create/fill/attach mutations from Builds MUST require an authenticated owner of the build.
- **FR-012**: Snapshot attachment semantics MUST be preserved: editing a live library Set updates live attachments; snapshot variants do not silently rewrite frozen configs via live Set item edits.
- **FR-013**: Fashion MUST NOT be required or promoted as a path to complete combat loadout in this feature's primary CTAs.
- **FR-014**: Existing SetAttachPicker (attach existing library Set) MUST remain available alongside create/fill so users who already have Sets are not forced to recreate them.
- **FR-015**: Detach remains available; deleting a Set still blocked when in use per existing deletion rules (detach-first).
- **FR-016**: Success feedback MUST name the created/updated Set(s) and confirm attachment when attach-now ran.
- **FR-017**: Optional deep-link to open a Set in the Sets library for advanced edit MAY exist but MUST NOT be the only way to fill slots needed to finish the build.
- **FR-018**: Production Builds MUST provide a **guided finish walkthrough** as the primary path when combat loadout pieces are missing. The walkthrough MUST detect gaps, present them **step by step**, and at each Set-level gap allow **create new Set** or **link existing Set**, then guide **slot fill** for empty slots on the attached Set until that gap is resolved or the user exits.
- **FR-019**: Discrete Set controls (attach picker, create, fill, create-from-build snapshot) MAY remain available for advanced use, but MUST NOT be the only way to discover how to finish an incomplete build.
- **FR-020**: The guided finish walkthrough MUST present missing combat categories in fixed order **Armor → Weapons → Mods**, skipping any category that is already **satisfied**: a covering Set of that type is attached **and** every combat slot required for default-variant completeness in that category is filled on the resolved loadout. An empty attached Set is **not** satisfied; filled slots without a covering Set are **not** satisfied until create/link (or create-from-build) establishes one.
- **FR-021**: A walkthrough category is **satisfied** only when both: (1) a covering Set for that category is attached to the active variant, and (2) all slots required for that category under default-variant combat completeness are filled. Neither condition alone is enough to skip the category.
- **FR-022**: The guided walkthrough MUST offer **Skip for now** on a category step and on individual empty-slot fill steps. Skipping MUST NOT mark the category satisfied; skipped gaps remain listed as remaining work and completeness guidance stays active. Exit walkthrough remains available and preserves confirmed work.
- **FR-023**: When a walkthrough category is unsatisfied and the variant already has **resolved gear** in that category without a covering Set, the category step MUST offer **Capture current gear into a Set** (create-from-build for that category, attach-now / replace-by-type per existing rules) as the **preferred** action, and MUST still offer **create empty Set** and **link existing Set**.

### Key Entities

- **Build Variant Attachment**: Live or snapshot link from a variant to a library Set; primary vehicle for build gear.
- **Inline Set Create Intent**: Name, type, optional tags, target variant, attach-now flag originating from Builds.
- **Inline Slot Fill Intent**: Target attached Set, slot, item identity, optional instance/perks — same meaning as Set fill, initiated from Builds.
- **Create-from-Build Snapshot Intent**: Build + variant + categories + attach-now + naming prefix; produces one Set per non-empty category.
- **Finish Walkthrough Session**: Ephemeral guided flow over a build variant that sequences Finish-Build Gaps; user may exit and resume remaining gaps later.
- **Finish-Build Gap**: User-visible missing combat coverage (e.g. no armor set / empty slots) driving CTAs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In acceptance testing, a user starting from a Build with **no** armor/weapon Sets can create and fill Sets to a **full combat loadout** on the default variant in under **10 minutes** without being required to use the Sets library page.
- **SC-002**: At least **90%** of first-time test users complete **Create Set + attach** from Builds without assistance.
- **SC-003**: At least **90%** of first-time test users complete **fill at least one empty slot** from Builds without assistance.
- **SC-004**: At least **90%** of users with an already-filled variant complete **Create Sets from this build** with attach-now and correctly see Sets on the variant without a second attach step.
- **SC-005**: Zero regressions in SetAttachPicker, Set hard constraints, and create-from-build replace-by-type behavior as verified by automated gates and smoke of prior Builds/Sets paths.
- **SC-006**: In a scripted incomplete-build pass, users can start the **guided finish walkthrough** and advance through at least one create-or-link gap and one fill step without assistance (checklist pass/fail), rather than only a blocking error with no next step.

## Assumptions

- "Finish the build" means achieving a **complete combat loadout** on the variant that must be complete (default variant per domain completeness), via **Set attachments** as the gear source of truth — not freeform build-only item pins as a parallel system.
- Production Builds is the home for this work; debug create-from-build may remain but is not sufficient.
- Armor, Weapon, and Mod are the primary types; Pair is supported when needed; Fashion is out of primary CTAs.
- Create-from-build already defined under 026 remains the behavioral baseline for snapshot + attach-now + constraint seeding; this feature **surfaces and completes** it in production UX and ensures empty create + fill cover the cold-start case.
- If mod snapshot from build is still incomplete in the current product, the UI must not over-promise; Weapon/Armor paths remain P1.
- Seamless means **no mandatory context switch** to Sets for create/fill; optional advanced edit in Sets is fine.
- Primary incomplete-build UX is a **single guided walkthrough** that create-or-links Sets and fills slots gap-by-gap (clarification session 2026-07-23), not only a menu of disconnected CTAs.
- Walkthrough category order is **Armor → Weapons → Mods** (skip satisfied).
- A category is **satisfied only when** a covering Set is attached **and** required slots are filled (clarification session 2026-07-23).
- Users may **Skip for now** on gaps; skip does not equal satisfied.
- When resolved gear exists without a covering Set, walkthrough **prefers Capture current gear into a Set** for that category.
- Live attach is the default for new Sets created to finish a build; snapshot remains opt-in via existing attachment controls where already offered.
- Catalog/Universal search may be reused inside fill pickers; this feature does not replace Catalog.
- Unsigned users cannot mutate personal Sets/Builds.

## Dependencies

- Set types, slots, exotic exclusivity, attach live/snapshot: [001](../001-build-sets-synergies/spec.md), BR-SET-*, BR-SLOT-*, BR-ATT-*, BR-CONF-*.
- Set fill / catalog lookup: [008](../008-sets-catalog-lookup/spec.md).
- Create-from-build API semantics, replace-by-type, optimizer constraint seed: [026](../026-armor-set-optimizer/spec.md), BR-OPT-001/002.
- Default variant completeness and identity: domain `DBR-CMPL-*`, `DBR-ID-*`, `DBR-CMP-*`.
- Concept tags on Sets: BR-TAG-*.

## Follow-on features (post-v1)

Full specs are created under new feature dirs via `/speckit.specify` (not part of 028 implement). Intent only:

- **029 (finish slot-first chrome)** — One-tap Create/Capture in Finish with inherited names; hide link/tags/name/type from Finish primary path (Sets tab retains advanced controls); weapons/mods enter slot-first fill immediately; armor manual fill remains fallback until 031.
- **030 (finish optimizer foundation)** — Optional `classType` when optimizing empty armor sets; pure helpers to rank set bonuses with synergy-linked first; constraints payload helpers from `seedConstraintsFromBuild` + user edits; unit tests only (no production Finish chrome required).
- **031 (finish armor optimize UI)** — After Armor create/capture, open optimize workspace: wide **V2+V5** (goals | top-3 compare), narrow **V6** compact rail; PATCH constraints → optimize → apply-combination; depends on 030 (and preferably 029 Finish chrome baseline).

Product source: Warp plan slot-first Finish + Armor optimizer; UI mocks `docs/ui-mocks/finish-build-slot-first.html`, `docs/ui-mocks/armor-picking-variants.html`.







