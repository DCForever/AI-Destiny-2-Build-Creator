# Feature Specification: DART-041 Flutter Mobile Compose

**Feature Branch**: `dart-041-flutter-mobile-compose`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Reduced-density compose on phone (sheets, linear finish). Create build → attach → soft guidance on device; P4 phase gate."

**Program ID**: DART-041  
**Phase**: P4  
**Depends**: DART-040 (mobile shell nav), DART-033–034 (Windows compose + soft guidance use cases)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- On Flutter **mobile host** (`apps/mobile_host`), reduced-density **compose path**:
  - **Create build** (name, guardian class, ≥1 synergy type) via modal **sheet** / form from Builds list
  - **Build detail** Focus Swap route becomes a **linear finish** compose surface (scroll, not dual-pane):
    - Identity summary (read)
    - Variant select / create named non-default variant
    - **Attach** library set (sheet picker) + detach; hard conflicts surfaced
    - Expanded **slot pins** with wishlist vs instance labels; pin/clear instance on live attachments
    - **Soft guidance** section: coverage chips + soft stat targets (explicit save only) + advisory caption
  - Reuse shared `destiny2_app` use cases (create/update build, variant attach, coverage query) — same hard/soft semantics as Windows
  - Pure display helpers for pin labels / soft chips (mobile-local or shared patterns from DART-033/034)
  - Widget/unit tests with memory DB (no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- Catalog browse / Sets / Synergies full library UIs on mobile (attach uses existing library sets only)
- Mobile OAuth / inventory sync UX (local-library remains default)
- Equip / DIM / Optimizer on mobile
- Windows dual-pane or Jaspr
- Soft guidance auto-apply (forbidden)
- Snapshot attach mode polish (default live)
- Node sidecar / CLIENT_SECRET

### Assumptions

- **A1**: Local library membership id `local-library` (same as DART-040) when signed out.
- **A2**: Create form requires class + at least one synergy type (hard identity gate); name optional with use-case default.
- **A3**: Linear finish = single scrolling detail with ordered sections (Identity → Variants → Attachments/Pins → Soft guidance); attach uses bottom sheet, not a new bottom-nav tab.
- **A4**: Default variant selected after create/open; attach to non-default preferred in tests to avoid default completeness hard-gate (same as Windows DART-033 tests).
- **A5**: Soft coverage via `queryVariantCoverage`; never auto-applies attachments/pins/targets; never hard-blocks compose.
- **A6**: Soft stat targets edit is explicit save only (`updateUserBuild`).
- **A7**: Pure Dart I/O; in-process use cases only.
- **A8**: Focus Swap list XOR detail retained from DART-040.
- **A9**: No NEEDS CLARIFICATION retained — defaults above apply.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create build on phone (Priority: P1)

As a mobile user, from the Builds list I open **Create build**, enter class + synergy type (and optional name), save, and land on the new build’s compose detail (Focus Swap) with a default variant ready.

**Why this priority**: Exit criterion — “Create build … on device.”

**Independent Test**: Memory DB: empty list → create via controller/UI → list has build; detail shows identity + default variant.

**Acceptance Scenarios**:

1. **Given** Builds list (empty or not), **When** I create a Hunter build with synergy type `melee`, **Then** the build appears in the list and detail opens with that name/class.
2. **Given** create with no synergy types, **When** I submit, **Then** validation error; no write.
3. **Given** successful create, **When** compose loads, **Then** default variant is selected for attach/soft sections.

---

### User Story 2 - Attach set (linear + sheet) (Priority: P1)

As a mobile user on build detail, I open an **attach set** sheet, pick a library set, attach it to the selected (non-default) variant, and see attachments + wishlist/instance slot pins. Hard `SLOT_CONFLICT` surfaces as error text without half-applying.

**Why this priority**: Exit criterion — “attach … on device.”

**Independent Test**: Seed set + create build + non-default variant → attach → attachments non-empty; conflict path shows error.

**Acceptance Scenarios**:

1. **Given** a non-default variant and a weapon set "Kinetic Core", **When** I attach live, **Then** attachments list shows the set and slot pin label is wishlist when no instance.
2. **Given** attach succeeds, **When** I pin instance `inst-1` on the slot, **Then** pin label becomes instance; clear → wishlist.
3. **Given** two sets claiming the same slot in one replace, **When** attach fails hard, **Then** error mentions conflict/slot and prior attachments remain.

---

### User Story 3 - Soft guidance on device (Priority: P1)

As a mobile user composing a variant, I see **soft coverage chips** and can **explicitly save** soft stat targets. Soft never auto-applies and does not hard-block legal attach.

**Why this priority**: Exit criterion — “soft guidance on device”; **P4 phase gate**.

**Independent Test**: Designated synergy unmatched → missing chip + advisory; soft targets save reloads; coverage refresh does not mutate attachments.

**Acceptance Scenarios**:

1. **Given** designated melee synergy unmatched by kit, **When** coverage runs, **Then** a soft chip shows `missing` (or weak) under Soft guidance with advisory caption.
2. **Given** soft targets, **When** I save Health:100, **Then** build persists target; coverage does not rewrite targets.
3. **Given** soft miss, **When** I attach a legal set on non-default, **Then** attach still succeeds.

---

### User Story 4 - Linear finish / Focus Swap density (Priority: P2)

As a mobile user, compose is a **single linear scroll** on detail (not dual-pane). Back returns to list. Bottom sheets for create/attach do not add permanent nav destinations.

**Why this priority**: Goal — “sheets, linear finish” reduced density.

**Independent Test**: Widget: detail has compose section keys in document order; list not co-visible; sheet open/close.

**Acceptance Scenarios**:

1. **Given** build detail, **When** rendered, **Then** sections appear in linear order without side-by-side library pane.
2. **Given** attach sheet open, **When** I dismiss without selecting, **Then** attachments unchanged.

---

### Edge Cases

- Empty attachable sets → sheet empty state; no crash.
- Detach last set → empty attachments OK on non-default.
- Soft query failure → soft section idle; compose still usable.
- Snapshot attachments display-only for pin edit.
- Soft never auto-applies; hard DBR blocks stay hard.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: User MUST be able to **create a build** from mobile Builds list via create form/sheet using `createUserBuild`.
- **FR-002**: Create MUST require guardian class and ≥1 synergy type; hard identity failures MUST surface as errors.
- **FR-003**: Build detail MUST present a **linear** compose flow: identity → variants → attachments/pins → soft guidance.
- **FR-004**: User MUST be able to select variant and create named non-default variants via `createUserVariant`.
- **FR-005**: User MUST be able to **attach** / **detach** library sets on the selected variant via `updateUserVariant` (live default); attach picker uses a **sheet**.
- **FR-006**: UI MUST show slot pins with **wishlist** vs **instance** labels; pin/clear on live set items via set item upsert.
- **FR-007**: Hard gate failures (e.g. `SLOT_CONFLICT`) MUST surface as user-visible error text; use-case rollback leaves prior state.
- **FR-008**: Soft coverage MUST display via `queryVariantCoverage` chips (supported/weak/missing); soft stat targets MUST save only on explicit user action.
- **FR-009**: Soft guidance MUST NEVER auto-apply attachments, pins, or targets; MUST NOT hard-block compose.
- **FR-010**: Soft section MUST include advisory copy that soft guidance never auto-applies / does not block save.
- **FR-011**: No CLIENT_SECRET; pure Dart I/O; Focus Swap list XOR detail retained.
- **FR-012**: Tests MUST cover create → attach → soft chips path and non-auto-apply.

### Key Entities

- **Build / Variant / Attachment / Slot pin**: same domain as DART-033.
- **CoverageResult / SoftStatTargets**: same as DART-034.
- **Mobile compose controller**: extends DART-040 BuildsController with create/compose/soft ops.
- **Sheets**: create-build sheet; attach-set sheet.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Create build from mobile controller/UI succeeds and appears in list/detail (test green).
- **SC-002**: Attach set + wishlist/instance pin path green on mobile tests.
- **SC-003**: Soft coverage chips + advisory visible; soft targets explicit save; coverage does not mutate kit.
- **SC-004**: `flutter test` in `apps/mobile_host` passes all shell + compose tests.
- **SC-005**: **P4 phase gate** — create → attach → soft guidance works on mobile reduced-density path (with DART-035–040 already done for equip/optimizer/shell).

## Assumptions

See Scope boundary **A1–A9**.
