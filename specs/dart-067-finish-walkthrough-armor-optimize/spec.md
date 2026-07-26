# Feature Specification: DART-067 Finish Walkthrough, Armor Optimize, Post-Sync Banner

**Feature Branch**: `dart-067-finish-walkthrough-armor-optimize`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Finish one-tap Create/Capture/fill; Build Finish armor improve; Settings post-sync banner. Exit: GAP-UI-BUILD-03, 04; GAP-UI-SETTINGS-04. BR-BLD-008 residual walkthrough: Finish slot-first one-tap Create/Capture/fill. Windows Build Finish Find kits → confirm apply (never silent). Windows post-sync better-kit Confirm/Dismiss only — never auto-apply. Web optimizer remains GAP-FEAT-01 deferred unless elevated. Soft never auto-applies; no CLIENT_SECRET. Does not re-open PRODUCTION_CUTOVER."

**Program ID**: DART-067  
**Phase**: P9  
**Depends**: DART-064, DART-036  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-BUILD-03, 04; GAP-UI-SETTINGS-04**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- **Finish slot-first one-tap Create / Capture / first-empty fill** on Windows + Jaspr (GAP-UI-BUILD-03; BR-BLD-008 residual)
- **Windows Build Finish Armor improve**: Find kits → top-N compare → confirm apply-in-place on live covering Armor Set (GAP-UI-BUILD-04; BR-BLD-009); never silent auto-apply
- **Windows Settings post-sync better-kit banner**: after successful inventory sync, suggest better kits for constrained Armor Sets attached to ≥1 Build; Confirm applies in place / Dismiss clears only (GAP-UI-SETTINGS-04; BR-OPT-004)
- Soft never auto-applies; no `CLIENT_SECRET`; cutover GO unchanged

**Out of scope (do not implement in this slice):**

- Web/mobile armor optimizer workspace (GAP-FEAT-01 remains deferred)
- Jaspr post-sync improvement banner (SETTINGS-04 shells = windows only)
- Presentation chrome polish (READY chips, ONLINE/Refresh, shell labels) — DART-068
- Advanced Finish link-existing / name / tags chrome (variant Sets tab retains advanced path)
- Production cutover re-gate; Next.js product worktree edits

## Assumptions

- **A1**: One-tap Create uses inherited name `{build.name} {Armor|Weapons|Mods}`, category type, empty set, live replace-by-type attach, no tags (product `createSetAndAttach`).
- **A2**: Capture uses resolved variant equipment claims for armor/weapon categories; mod capture may skip when no mod claims (product `createSetsFromBuild` skip semantics). Soft never auto-applies.
- **A3**: After Create/Capture/fill mutation, walkthrough advances via pure `resolvePostMutationStep` (domain DART-007): live covering → first empty fill; live covering armor incomplete → armor_optimize on Windows when preferArmorOptimize.
- **A4**: Armor improve reuses Windows `OptimizerController` + `OptimizerWorkspace` (DART-036) bound to covering set id; apply only via explicit confirm (`applyArmorCombinationInPlace`).
- **A5**: Post-sync suggestions: armor sets with non-null parseable `optimizerConstraints` attached to ≥1 build; top kit improves current pieces via `detectImprovement` / `compareCombinations`. Confirm-only apply.
- **A6**: Skip-for-now is session-local and does not mark category satisfied (BR-BLD-007/008).
- **A7**: Equip/export CTAs still require finish-complete ∧ equip-ready (DART-057).
- **A8**: Pure Dart I/O only; no CLIENT_SECRET.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-tap Create set & fill loop (Priority: P1)

As a builder finishing a variant, when Armor/Weapons/Mods has no covering set, I one-tap **Create … set & fill** (no name/type/tag chrome). The host creates an empty library set, live-attaches it (replace-by-type), and advances into the first empty required slot fill when applicable.

**Why this priority**: GAP-UI-BUILD-03; BR-BLD-008; primary Finish residual.

**Independent Test**: Use-case unit test createSetAndAttach; host test Create button key creates set + attachment.

**Acceptance Scenarios**:

1. **Given** default variant with no armor set attached, **When** user taps Create Armor set & fill, **Then** an empty armor set named `{build} Armor` (unique) is created, live-attached, and finish status leaves `needs_set`.
2. **Given** create succeeded and armor still has empty slots, **When** post-mutation resolves, **Then** walkthrough targets fill or armor_optimize (Windows) per pure helpers — not overview stuck on needs_set.
3. **Given** create path, **When** user never confirms name/tags, **Then** set still persists with inherited name and empty tags.

---

### User Story 2 - Capture preferred + first-empty fill (Priority: P1)

As a builder with resolved gear claims, I prefer **Capture** current gear into a library set + live attach, then fill remaining empty required slots one-by-one without advanced link chrome.

**Why this priority**: GAP-UI-BUILD-03; BR-BLD-008 capture path.

**Independent Test**: createSetsFromBuild unit test; host Capture action when canCapture.

**Acceptance Scenarios**:

1. **Given** armor claims exist and status is capture_available, **When** Capture runs, **Then** set items match claim hashes and set is live-attached.
2. **Given** live covering set with empty slots, **When** user Fill first empty, **Then** catalog/owned pick upserts that slot only; next empty advances after refresh.
3. **Given** snapshot-only covering set, **When** needs_fill, **Then** host explains live set required (no silent pin edit).

---

### User Story 3 - Windows Finish Armor improve confirm-only (Priority: P1)

As a Windows user with a live covering Armor Set on Finish, I open Armor improve (Find kits → compare → confirm apply). Find kits never writes; apply runs only after Confirm.

**Why this priority**: GAP-UI-BUILD-04; BR-BLD-009; PRODUCT-SOFT-NEVER-AUTO.

**Independent Test**: OptimizerController already proves confirm-only; Finish panel wires bindTargetSet + workspace; test asserts Find kits does not mutate set items; Confirm does.

**Acceptance Scenarios**:

1. **Given** live armor covering set with empty/incomplete slots, **When** walkthrough enters armor_optimize, **Then** Find kits control is available bound to covering set id.
2. **Given** kits listed, **When** user does not confirm, **Then** set items unchanged.
3. **Given** user confirms apply-in-place, **Then** covering set pieces update and walkthrough may re-evaluate gaps.

---

### User Story 4 - Windows post-sync better-kit banner (Priority: P2)

As a signed-in Windows user, after successful inventory sync, Settings may show a **Better armor kits** banner for constrained attached armor sets. Confirm applies that kit; Dismiss clears the suggestion only — never auto-apply.

**Why this priority**: GAP-UI-SETTINGS-04; BR-OPT-004.

**Independent Test**: improvementSuggestions pure/app tests; InventorySyncCard shows banner only after sync + suggestions; Confirm calls apply; Dismiss removes without write.

**Acceptance Scenarios**:

1. **Given** constrained armor set attached to a build and better kit available after sync, **When** sync succeeds, **Then** banner lists set name with Confirm/Dismiss.
2. **Given** banner visible, **When** Dismiss, **Then** set items unchanged and suggestion removed.
3. **Given** banner visible, **When** Confirm, **Then** apply-in-place runs and that suggestion is removed.
4. **Given** no constrained attached sets or no improvement, **When** sync succeeds, **Then** no auto-write and no false auto-apply.

---

### Edge Cases

- Create with duplicate name → unique suffix allocation (parity allocateUniqueSetName).
- Capture with no claims → NOTHING_TO_CREATE style error; no partial silent attach.
- Find kits with empty inventory → empty reason + inventory guidance; no write.
- Post-sync suggestion fetch failure → soft best-effort; sync success still shown.
- Skip for now → category not satisfied; equip still blocked until complete.
- Web Finish gets Create/Capture/fill only — no Find kits (GAP-FEAT-01).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hosts MUST expose Finish walkthrough actions for next actionable / selected category: one-tap Create (inherited name, category type, live attach) when `showFinishCreateActions`.
- **FR-002**: Hosts MUST expose Capture when gap.canCapture, creating sets from resolved claims and live-attaching.
- **FR-003**: Hosts MUST support first-empty-slot fill on live covering sets (catalog/owned pick → upsert set item).
- **FR-004**: Windows Finish MUST offer Armor improve (optimizer workspace) when pure `shouldOpenArmorOptimize` / armor_optimize step applies for live covering armor.
- **FR-005**: Find kits MUST never write sets; apply-in-place MUST require explicit Confirm.
- **FR-006**: Windows Settings MUST, after successful sync, optionally fetch soft improvement suggestions for constrained armor sets attached to ≥1 build and show Confirm/Dismiss — never silent apply.
- **FR-007**: Soft guidance / kit suggestions MUST never auto-apply.
- **FR-008**: Clients MUST NOT embed CLIENT_SECRET.
- **FR-009**: Equip/export remain gated by finish-complete ∧ equip-ready.

### Key Entities

- **FinishGap / FinishGapsResult**: pure category readiness (domain).
- **FinishPostMutationTarget**: walkthrough step after mutation (domain).
- **Created/captured Set**: library set + live attachment.
- **ImprovementSuggestion**: armorSetId, name, better combination, buildIds (soft).
- **ArmorCombination**: optimizer kit pieces for confirm apply.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: GAP-UI-BUILD-03 closed: Windows + Jaspr Finish support one-tap Create, Capture when available, and first-empty fill without name/type/tag chrome.
- **SC-002**: GAP-UI-BUILD-04 closed on Windows: Build Finish path exposes Find kits → confirm apply on live covering armor set; web residual stays GAP-FEAT-01 deferred.
- **SC-003**: GAP-UI-SETTINGS-04 closed: Windows post-sync banner Confirm/Dismiss only; tests prove no auto-apply on sync alone.
- **SC-004**: Unit/host tests cover createSetAndAttach, capture, detectImprovement/suggestions, and confirm-only apply paths.
- **SC-005**: Soft never auto-applies; secret scan remains clean.

## Assumptions (summary)

See Assumptions A1–A8 above.
