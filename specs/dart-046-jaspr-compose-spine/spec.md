# Feature Specification: DART-046 Jaspr Compose Spine

**Feature Branch**: `dart-046-jaspr-compose-spine`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port compose spine UI to Jaspr (build/sets/synergy/catalog). Intent→compose with hard/soft parity."

**Program ID**: DART-046  
**Phase**: P5  
**Depends**: DART-043–045 (Jaspr OPFS, entity bundles, OAuth), DART-027–028 (app use cases library + build)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (D-PATH, D-IO, D-WEB-DB; soft never auto-applies)

## Scope boundary

**In scope:**

- Jaspr **web host** compose spine routes and UI:
  - **Builds**: list, create (class + ≥1 synergy type), detail compose surface
  - **Variants**: select default / create named non-default; attach/detach library sets (live)
  - **Slot pins**: wishlist vs instance labels; pin/clear instance on live attachments
  - **Soft guidance**: coverage chips + soft stat targets (explicit save only) + advisory caption
  - **Sets library**: list/create/select; upsert set item (slot + hash + name) for attachable kits
  - **Synergies library**: list/create/select; optional evidence link; designation immutable after create
  - **Catalog**: existing offline catalog remains navigable (DART-044); no redesign required beyond nav
- In-process `destiny2_app` use cases against writer-tab `AppDatabase` (same hard/soft semantics as Flutter)
- Pure display helpers for list titles, pin labels, soft chips
- Unit/controller + component tests with **memory DB** (no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- Equip-ready / DIM / equip CTA on web (DART-047)
- Inventory sync UI / owned catalog filter on web
- Optimizer on web
- Soft auto-apply (forbidden)
- Confidential OAuth / Node sidecar / CLIENT_SECRET
- Flutter Windows/mobile changes
- Full dual-pane Windows density parity (web uses linear sections)

### Assumptions

- **A1**: Local library membership id `local-library` when signed out (same as Flutter shells). Signed-in membership may own library later; this slice defaults to local-library for offline compose.
- **A2**: Compose requires **writer-tab** DB (`WebDatabaseBootstrap.database` non-null). Blocked second tab shows read-only message for compose routes.
- **A3**: Create build requires guardian class + ≥1 synergy type (hard identity gate). Name optional with use-case default.
- **A4**: Attach tests prefer **non-default** variants to avoid default completeness hard-gate (parity with DART-033/041).
- **A5**: Soft coverage via `queryVariantCoverage`; never auto-applies attachments/pins/targets; never hard-blocks legal compose.
- **A6**: Soft stat targets edit is explicit save only (`updateUserBuild`).
- **A7**: Pure Dart I/O only; no Next runtime dependency; no CLIENT_SECRET.
- **A8**: Catalog page already ships (DART-044); spine nav adds Builds/Sets/Synergies.
- **A9**: Set item fill on web may use manual hash/name/slot form (catalog pick wire-up is optional nicety if timeboxed; attach uses library sets).
- **A10**: No NEEDS CLARIFICATION retained — defaults above apply.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Intent: create build on web (Priority: P1)

As a web user with writer DB, from **Builds** I create a build with guardian class and at least one synergy type, see it in the list, and open its compose detail with a default variant selected.

**Why this priority**: Exit criterion — Intent→compose starts with build identity.

**Independent Test**: Memory DB controller: create Hunter + melee → list length 1; open → default variant selected.

**Acceptance Scenarios**:

1. **Given** empty builds list, **When** I create "Web Hunter" with class Hunter and synergy type `melee`, **Then** the build appears and compose opens with that identity.
2. **Given** create with no synergy types, **When** I submit, **Then** validation error; no write.
3. **Given** successful create, **When** compose loads, **Then** default variant is selected.

---

### User Story 2 - Sets + synergies libraries (Priority: P1)

As a web user, I can create library **sets** (with at least one slot item) and **synergies** (with designation) so compose can attach and soft-cover against them.

**Why this priority**: Compose spine requires sets/synergy libraries, not only builds.

**Independent Test**: Memory DB: create weapon set + item; create synergy with weapon link; list non-empty.

**Acceptance Scenarios**:

1. **Given** Sets page, **When** I create a weapon set "Kinetic Core" and upsert Kinetic/primary item, **Then** set detail shows the item.
2. **Given** Synergies page, **When** I create synergy "Melee Loop" type `melee` with optional link, **Then** it appears with immutable designation after create.
3. **Given** blocked writer (no DB), **When** libraries render, **Then** UX explains writer required (no crash).

---

### User Story 3 - Compose: attach + pins + hard gates (Priority: P1)

As a web user on build compose, I create a non-default variant, attach a library set, see wishlist/instance pin labels, and pin/clear instance. Hard slot conflicts surface as errors without half-apply.

**Why this priority**: Exit criterion — compose path with **hard** parity.

**Independent Test**: Seed set + build + non-default variant → attach → pins; conflict path retains prior attachments.

**Acceptance Scenarios**:

1. **Given** non-default variant and set "Kinetic Core", **When** I attach live, **Then** attachments list shows the set and pin label is wishlist when no instance.
2. **Given** attach succeeds, **When** I pin instance `inst-1`, **Then** pin label becomes instance; clear → wishlist.
3. **Given** two sets claiming the same slot in one replace, **When** attach fails hard, **Then** error mentions conflict/slot and prior attachments remain.

---

### User Story 4 - Soft guidance display-only (Priority: P1)

As a web user composing a variant, I see soft coverage chips and can explicitly save soft stat targets. Soft never auto-applies and does not hard-block legal attach.

**Why this priority**: Exit criterion — **soft** parity; soft never auto-applies.

**Independent Test**: Designated unmatched synergy → missing chip + advisory; save Health:100; coverage refresh does not mutate attachments.

**Acceptance Scenarios**:

1. **Given** designated melee unmatched by kit, **When** coverage runs, **Then** a soft chip shows `missing` (or weak) under Soft guidance with advisory caption.
2. **Given** soft targets, **When** I save Health:100, **Then** build persists target; coverage does not rewrite targets.
3. **Given** soft miss, **When** I attach a legal set on non-default, **Then** attach still succeeds.

---

### User Story 5 - Spine navigation (Priority: P2)

As a web user, shell nav includes Catalog, Builds, Sets, Synergies, Settings so Intent→compose is reachable without Next.js.

**Why this priority**: Spine discoverability.

**Independent Test**: Shell header routes include all five; component smoke on Builds/Sets/Synergies titles.

**Acceptance Scenarios**:

1. **Given** shell header, **When** rendered, **Then** nav links include Catalog, Builds, Sets, Synergies, Settings.
2. **Given** route `/builds`, **When** opened with injected memory services, **Then** Builds page title renders.

---

### Edge Cases

- Second tab blocked (no writer DB) → compose pages show blocked message; no silent writes.
- Double-submit create while busy → ignore or single-flight; no duplicate corruption.
- Soft coverage query failure → soft section empty/error text; kit unchanged.
- Hard attach failure → error message; prior attachments reloaded.
- Soft guidance never auto-applies.
- No CLIENT_SECRET in sources.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Web host MUST expose Builds, Sets, Synergies routes wired to in-process use cases when writer DB is available.
- **FR-002**: Create build MUST require class + ≥1 synergy type; hard identity validation via `createUserBuild`.
- **FR-003**: Variant attach/detach MUST use `updateUserVariant` / hard gates; soft misses MUST NOT block.
- **FR-004**: Soft coverage MUST use `queryVariantCoverage` and display chips; MUST NOT auto-attach/auto-pin.
- **FR-005**: Soft stat targets MUST save only via explicit user action (`updateUserBuild`).
- **FR-006**: Sets library MUST support create + upsert set item for attachable kits.
- **FR-007**: Synergies library MUST support create with designation; type/subType immutable after create.
- **FR-008**: Catalog route MUST remain available (existing DART-044 page).
- **FR-009**: Blocked writer MUST surface non-destructive UX on compose routes.
- **FR-010**: Soft advisory caption MUST state soft does not block save / does not auto-apply.
- **FR-011**: CI tests MUST pass with memory DB + mocks only (no live Bungie, no CLIENT_SECRET).
- **FR-012**: Pure Dart I/O only; no Node sidecar.

### Key Entities

- **ComposeServices**: Writer `AppDatabase` + Builds/Sets/Synergies controllers for the web host.
- **BuildsController**: List/create/open, variants, attach, pins, soft coverage/targets.
- **SetsController**: List/create/select, upsert set item.
- **SynergiesController**: List/create/select, optional links.
- **Display helpers**: build list titles, pin labels, soft chip labels (pure).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test` in `apps/web_host` passes including new compose tests.
- **SC-002**: Tests prove create build → non-default attach → pin wishlist/instance with hard conflict path.
- **SC-003**: Tests prove soft chip display + soft targets save without auto-apply.
- **SC-004**: Tests prove sets + synergies create paths.
- **SC-005**: Shell nav includes compose spine destinations.
- **SC-006**: Grep/scan shows no CLIENT_SECRET in new compose modules.
- **SC-007**: Workspace packages resolve (`destiny2_app` path dep on web_host).

## Assumptions

See A1–A10 above. Defaults match D-IO (pure Dart), DBR-GUID soft path, and Flutter compose parity from DART-027–034 / DART-041.
