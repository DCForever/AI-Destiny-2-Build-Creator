# Feature Specification: DART-032 Flutter Build Identity UI

**Feature Branch**: `dart-032-flutter-build-identity-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Build list + identity (class, synergy types, exotic/super pins). Create build with synergy types."

**Program ID**: DART-032  
**Phase**: P3  
**Depends**: DART-028 (build use cases + hard identity gates), DART-029 (design tokens / FlapBoard contracts)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter **Builds library** screen on Windows host with **dual-pane** layout:
  - Left rail (~`kFlapLibraryRailWidth` 320): list of user builds using `kFlapColumnsBuilds` header labels (Name · Identity · Exotics · Synergy · Status)
  - Right pane: create form + selected build **identity** detail (class, synergy type designations, optional exotic armor/weapon pins, optional pinned Super, name)
- **Create** builds via in-process `destiny2_app` `createUserBuild` with:
  - required guardian **class**
  - ≥1 **synergy type designation** (type + optional subtype)
  - optional name (default name from class when empty)
  - optional exotic armor hash/name, exotic weapon hash/name, pinned Super
- **Hard gate UX**: zero synergy types blocked with clear message (`NO_SYNERGY` / use-case error); UI does not auto-apply soft guidance
- **Edit** identity-safe mutable fields on selected build: name; synergy types replace; exotic/super pin set/clear via `updateUserBuild` (confirm/fork deferred — in-place update only this slice)
- NavigationRail destination for **Builds** in Windows shell
- Widget tests with memory DB (no live Bungie)

**Out of scope (later slices):**

- Variant compose, set attachments, slot pins (DART-033)
- Soft coverage chips / soft stat targets UI (DART-034)
- Identity confirm-in-place vs fork dialog (product 015 US3) — in-place only here
- Catalog deep pick for exotic hashes (manual hash + display name text is enough)
- Equip / DIM / optimizer / Node sidecar / CLIENT_SECRET
- Jaspr / mobile shells

### Assumptions

- **A1**: Local library user — same as DART-030/031: signed-in membership → `ensureUser`; signed out → stable `local-library` user row.
- **A2**: Dual-pane is list + detail on the Builds page.
- **A3**: Synergy types on create use creatable type wires from domain (`creatableSynergyTypeWires`); multi-select / add-chip UX drafts a list of designations before create.
- **A4**: ≥1 synergy type is required (DBR / `evaluateSynergyRequirement`); empty list fails create with surfaced error.
- **A5**: Exotic armor/weapon pins are optional hash+name text fields (no catalog picker required for exit).
- **A6**: Pinned Super is optional free-text (build-level identity pin); subclass kit may remain empty/default on create (full kit completeness is later).
- **A7**: Soft suggestions never auto-apply; hard DBR blocks stay hard.
- **A8**: Pure Dart I/O only; host calls `destiny2_app` in-process.
- **A9**: Nav order: Catalog → Sets → Synergies → **Builds** → Settings.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create build with synergy types (Priority: P1)

As a Windows user, I open **Builds**, choose class and add ≥1 synergy type, create the build, see it in the left rail, and select it to view identity (class + synergy designations).

**Why this priority**: Exit criterion — “Create build with synergy types.”

**Independent Test**: Widget test with memory DB; create Hunter + melee::Base → appears in list → detail shows class and synergy chip.

**Acceptance Scenarios**:

1. **Given** empty library, **When** I create build name "Arc Hunter", class Hunter, synergy type `melee` subtype `Base`, **Then** it appears in the list and detail shows identity class Hunter and designation `melee::Base`.
2. **Given** dual-pane layout, **When** Builds page renders with a selected build, **Then** left rail (~library rail width) and detail pane are side by side.
3. **Given** no synergy types drafted, **When** I create, **Then** UI surfaces validation / hard-gate error (no crash; no row written).
4. **Given** empty name, **When** I create with class + synergy, **Then** a default name is applied (e.g. includes class) and create succeeds.

---

### User Story 2 - Identity fields: class, exotic/super pins (Priority: P1)

As a Windows user creating or viewing a build, I can set optional exotic armor, exotic weapon, and pinned Super as identity fields and see them on the detail pane.

**Why this priority**: Goal — “identity (class, synergy types, exotic/super pins).”

**Independent Test**: Create with exotic armor hash + pinned Super; detail shows those pins; list “Exotics” column non-empty.

**Acceptance Scenarios**:

1. **Given** create form, **When** I set exotic armor hash/name and pinned Super and create with ≥1 synergy, **Then** detail shows those pin values.
2. **Given** a selected build without exotic weapon, **When** I update exotic weapon hash/name and save identity, **Then** detail reflects the new pin.
3. **Given** class selector, **When** I create as Titan vs Warlock, **Then** list/detail show the chosen class wire name.

---

### User Story 3 - List + navigation (Priority: P2)

As a Windows user, I navigate to Builds from the host NavigationRail and browse my builds list.

**Why this priority**: Discoverability and list contract.

**Independent Test**: Pump host app; select Builds; page key visible; other destinations remain.

**Acceptance Scenarios**:

1. **Given** the host app, **When** I select the Builds rail destination, **Then** the builds library page is shown.
2. **Given** Catalog/Sets/Synergies/Settings still exist, **When** I switch destinations, **Then** they remain reachable.
3. **Given** one or more builds, **When** list renders, **Then** headers align with `kFlapColumnsBuilds` labels.

---

### Edge Cases

- Create with zero synergy types → hard block, no write.
- Empty build name after trim → default name from class (use case), not a hard error.
- Update name to empty → use case rejects empty rename.
- Soft guidance never auto-applies.
- Variant/set attach UI deferred to DART-033.
- Confirm/fork on identity edit deferred; updates apply in-place.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Windows host MUST expose a **Builds** library screen with dual-pane list + detail.
- **FR-002**: User MUST be able to **create** a build (class + ≥1 synergy type + optional name/exotic/super pins) via `createUserBuild`.
- **FR-003**: Create with zero synergy types MUST surface hard error and write nothing.
- **FR-004**: Detail pane MUST show identity: class, synergy type designations, exotic armor/weapon, pinned Super.
- **FR-005**: User MUST be able to update name and identity pins / synergy types via `updateUserBuild` (in-place).
- **FR-006**: Shell MUST add a NavigationRail destination for Builds.
- **FR-007**: Host MUST resolve local `userId` for library ops (signed-in or local-library fallback).
- **FR-008**: Soft suggestions MUST NOT auto-apply; no CLIENT_SECRET; no Node sidecar.
- **FR-009**: Tests MUST cover create with synergy types, zero-synergy block, and nav reachability.

### Key Entities

- **Build identity**: class, synergy type designations (≥1), optional exotic armor item, optional build-shared exotic weapon, optional pinned Super.
- **Synergy type designation**: type wire + optional subtype (`type` or `type::subType`).
- **Build list row**: name, identity summary (class), exotics summary, synergy designations summary, status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Create build with ≥1 synergy type → list and detail show it (widget evidence).
- **SC-002**: Create with zero synergy types fails with clear error; library stays empty.
- **SC-003**: Identity pins (class, exotic/super when set) visible on detail.
- **SC-004**: Builds page reachable from nav rail.
- **SC-005**: `flutter test` builds suite green; no CLIENT_SECRET in client code.

## Assumptions

See Scope boundary Assumptions A1–A9.
