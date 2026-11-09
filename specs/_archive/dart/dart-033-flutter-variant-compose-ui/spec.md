# Feature Specification: DART-033 Flutter Variant Compose UI

**Feature Branch**: `dart-033-flutter-variant-compose-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Variants, set attachments, slot pins (wishlist vs instance). Attach set; pin slot; resolve conflicts surfaced."

**Program ID**: DART-033  
**Phase**: P3  
**Depends**: DART-032 (build identity UI), DART-030 (sets library + slot fill / wishlist vs instance)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- On the Flutter **Builds** library detail pane (Windows host), **variant compose** for the selected build:
  - List variants (including the default created with the build)
  - Create an additional named variant
  - Select a variant to compose
  - **Attach** library sets to the selected variant (live mode by default; full attachment replace via `updateUserVariant`)
  - Detach a set from the selected variant
  - Show **slot pins** from expanded attachments: **wishlist** (no `instanceId`) vs **instance** (has `instanceId`)
  - **Pin / clear pin** on a slot that comes from a live-attached set (update underlying set item `instanceId` via set use case; definition hash/name retained)
  - **Surface hard conflicts** (e.g. `SLOT_CONFLICT`) when attach/save is rejected — clear error text; use-case rollback leaves prior attachments intact
- Pure display helpers for pin labels / attachment summary
- Widget + unit tests with memory DB (no live Bungie)

**Out of scope (later slices):**

- Soft coverage chips / soft stat targets UI (DART-034)
- Optimizer / equip / DIM (DART-035+)
- Snapshot attach mode UX polish (API may accept mode; default UI is live)
- Full inventory-backed equip-ready evaluation UI (optional index; display pin from claim `instanceId` is enough for exit)
- Identity confirm/fork dialog
- Jaspr / mobile shells
- Node sidecar / CLIENT_SECRET

### Assumptions

- **A1**: Local library user — same as DART-030/031/032 (`local-library` when signed out).
- **A2**: Compose lives on the existing Builds detail pane under identity (not a separate nav destination).
- **A3**: Default variant exists after build create (DART-028); UI lists it and allows create of additional non-default variants.
- **A4**: Attach uses **live** mode unless tests pass snapshot; fashion multi-attach still hard-blocks via use cases.
- **A5**: Slot pin edit only applies to **live** attachments (edit set items); snapshot pins are display-only this slice.
- **A6**: Pin status label from claim/`SetItemRecord.instanceId`: null → `wishlist`, non-null → `instance` (equip-ready stale checks optional).
- **A7**: Soft suggestions never auto-apply; hard DBR blocks stay hard and are shown as errors.
- **A8**: Pure Dart I/O only; host calls `destiny2_app` in-process.
- **A9**: Set catalog for attach is the user's library list (`listUserSets`); no cross-user sets.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Attach set to variant (Priority: P1)

As a Windows user with a build and at least one library set, I select the build, select a variant (default or new), attach a set, and see the attachment listed with expanded slot pins.

**Why this priority**: Exit criterion — “Attach set.”

**Independent Test**: Widget/controller test with memory DB; create build + weapon set with primary item → attach to default variant → attachments list non-empty; slot pin shows wishlist or instance.

**Acceptance Scenarios**:

1. **Given** a build with default variant and a weapon set "Kinetic Core", **When** I attach that set live, **Then** the variant attachments show "Kinetic Core" and expanded slots include its filled slots.
2. **Given** a selected variant with no attachments, **When** attach succeeds, **Then** status is success (no hard error) and list reloads.
3. **Given** attach of missing/unowned set id, **When** prepare skips it, **Then** no crash; attachments unchanged or empty as use case dictates.

---

### User Story 2 - Pin slot wishlist vs instance (Priority: P1)

As a Windows user composing a variant with a live-attached set, I can set or clear an instance pin on a slot and see **wishlist** vs **instance** labels.

**Why this priority**: Exit criterion — “pin slot” + goal “wishlist vs instance.”

**Independent Test**: Attach set with wishlist primary (null instance) → pin instance id on that slot → label becomes instance; clear pin → wishlist again.

**Acceptance Scenarios**:

1. **Given** attached set item with null `instanceId`, **When** slot pins render, **Then** pin label is wishlist.
2. **Given** that slot, **When** I pin instance id `inst-1`, **Then** pin label is instance and set item persists `instanceId`.
3. **Given** pinned instance, **When** I clear the pin, **Then** label returns to wishlist.

---

### User Story 3 - Slot conflict surfaced (Priority: P1)

As a Windows user, when I attach two sets that claim the same equipment slot, the hard conflict is **surfaced** and prior attachments are not left half-applied (use-case rollback).

**Why this priority**: Exit criterion — “resolve conflicts surfaced.”

**Independent Test**: Two weapon sets both filling primary → second attach via full list with both → `SLOT_CONFLICT` error message in UI/status; attachments remain previous successful state.

**Acceptance Scenarios**:

1. **Given** variant already has set A (primary), **When** I try to also attach set B (primary) in one save, **Then** error text mentions conflict / slot and attachments do not keep both.
2. **Given** conflict error, **When** UI shows status, **Then** no crash and user can retry with a different set.

---

### User Story 4 - Create / select variants (Priority: P2)

As a Windows user, I can create a named non-default variant and switch selection among variants for compose.

**Why this priority**: Supports multi-variant compose; default alone is enough for attach tests but create is part of the goal “Variants.”

**Independent Test**: Create build → create variant "Raid" → select it → compose targets that variant id.

**Acceptance Scenarios**:

1. **Given** a build, **When** I create variant "Raid", **Then** it appears in the variant list (not default).
2. **Given** two variants, **When** I select each, **Then** attachments/pins shown are for the selected variant only.

---

### Edge Cases

- Empty variant name on create → validation error, no write.
- Detach last set → empty attachments OK for non-default; default completeness is hard only when equipment-affecting save requires full combat (existing use-case rules).
- Soft guidance never auto-applies.
- Snapshot pins display-only; pin edit on snapshot → clear message or no-op with reason.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Selected build detail MUST list variants and allow selecting one for compose.
- **FR-002**: User MUST be able to create an additional named variant via `createUserVariant`.
- **FR-003**: User MUST be able to **attach** a library set to the selected variant via `updateUserVariant` / attachment replace (hard gates applied).
- **FR-004**: User MUST be able to **detach** a set from the selected variant.
- **FR-005**: UI MUST show expanded **slot pins** with wishlist vs instance labels for the selected variant.
- **FR-006**: User MUST be able to **pin** or **clear** instance on a live-attached set slot via set item upsert.
- **FR-007**: Hard gate failures (including `SLOT_CONFLICT`) MUST surface as user-visible error text; soft suggestions MUST NOT auto-apply.
- **FR-008**: No CLIENT_SECRET; pure Dart I/O; in-process use cases only.
- **FR-009**: Tests MUST cover attach, pin wishlist/instance, and conflict surface.

### Key Entities

- **Variant**: named equipment configuration under a build; may be default.
- **Set attachment**: live or snapshot link from variant → library set.
- **Slot pin**: per equipment slot claim with optional `instanceId` (wishlist when absent).
- **Hard conflict**: e.g. two claims for the same slot (`SLOT_CONFLICT`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Attach set → attachment listed (widget/controller evidence).
- **SC-002**: Pin slot toggles wishlist ↔ instance labels and persists.
- **SC-003**: Conflicting dual-primary attach surfaces error; no silent dual attach.
- **SC-004**: Create/select non-default variant works for compose target.
- **SC-005**: `flutter test` variant-compose suite green; no CLIENT_SECRET in client code.

## Assumptions

See Scope boundary Assumptions A1–A9.
