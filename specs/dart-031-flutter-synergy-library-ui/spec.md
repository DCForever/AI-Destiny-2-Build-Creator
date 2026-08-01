# Feature Specification: DART-031 Flutter Synergy Library UI

**Feature Branch**: `dart-031-flutter-synergy-library-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Synergy library CRUD + evidence links UI. Create synergy; designation immutable after create."

**Program ID**: DART-031  
**Phase**: P3  
**Depends**: DART-027 (synergy use cases), DART-029 (design tokens / FlapBoard contracts)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter **Synergy library** screen on Windows host with **dual-pane** layout:
  - Left rail (~`kFlapLibraryRailWidth` 320): list of user synergies (name / designation / evidence count / status) using `kFlapColumnsSynergy` header labels
  - Right pane: create form + selected synergy detail (name, description, **immutable designation**, evidence links editor)
- **Create** library synergies via in-process `destiny2_app` `createUserSynergy` (name + creatable type + optional subtype + description + optional initial links)
- **Edit** mutable fields (name, description, links) via `updateUserSynergy`
- **Designation immutability**: type + subtype set only at create; detail pane shows designation as read-only; UI never offers type/subtype change on update; if update path attempts designation change, surface `DESIGNATION_IMMUTABLE` error
- **Evidence links UI**: list links; add link (kind + displayName + optional hashes/fields by kind); remove link; persist full link list on save
- NavigationRail destination for **Synergies** in Windows shell
- Widget tests with memory DB (no live Bungie)

**Out of scope (later slices):**

- Build identity / synergy type designation on builds (DART-032)
- Soft coverage chips against links (DART-034)
- Catalog/instance deep pick for every link kind (optional simple itemHash entry is enough)
- Soft guidance auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)
- Jaspr / mobile shells

### Assumptions

- **A1**: Local library user — same as DART-030: signed-in membership → `ensureUser`; signed out → stable `local-library` user row.
- **A2**: Dual-pane is list + detail on the Synergies page.
- **A3**: Creatable types only from `creatableSynergyTypeWires` (domain). Legacy types not offered on create.
- **A4**: Designation = type (+ optional subtype). Display as `type` or `type::subType` (`designationKey` parity).
- **A5**: Evidence link kinds from `SynergyLinkKind` wire names. Minimal add form: kind + displayName; optional itemHash for weapon/exotic_armor; optional fields for other kinds via display-only extras when provided.
- **A6**: Link replace-on-save: detail editor drafts a link list; Save links calls update with full list (use case validates kinds).
- **A7**: Soft suggestions never auto-apply; hard DBR blocks stay hard where domain says so — this slice is library persistence UI only.
- **A8**: Pure Dart I/O only; host calls `destiny2_app` in-process.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create synergy + list dual-pane (Priority: P1)

As a Windows user, I open **Synergies**, create a synergy (name + type + optional subtype), see it in the left rail, and select it to view designation and empty evidence list.

**Why this priority**: Exit criterion — “Create synergy.”

**Independent Test**: Widget test with memory DB; create melee synergy → appears in list → detail shows immutable type chip.

**Acceptance Scenarios**:

1. **Given** empty library, **When** I create synergy name "Melee Combo" type `melee` subtype `Base`, **Then** it appears in the list with designation `melee::Base` and detail shows those fields.
2. **Given** dual-pane layout, **When** Synergies page renders with a selected synergy, **Then** left rail (~library rail width) and detail pane are side by side.
3. **Given** empty name, **When** I create, **Then** UI surfaces validation error (no crash).
4. **Given** non-creatable type is not offered, **When** create uses only creatable wires, **Then** create succeeds for `melee`.

---

### User Story 2 - Designation immutable after create (Priority: P1)

As a Windows user viewing an existing synergy, I can edit name/description/links but **cannot** change type or subtype in the UI; designation remains as created.

**Why this priority**: Exit criterion — “designation immutable after create.”

**Independent Test**: Create synergy; detail has no type dropdown; rename works; type chip still shows original wire.

**Acceptance Scenarios**:

1. **Given** a synergy created as `melee` / `Base`, **When** I open detail, **Then** designation is read-only (chip/text; no type/subtype edit controls).
2. **Given** a selected synergy, **When** I rename and save, **Then** name updates and designation is unchanged.
3. **Given** controller/update path attempts `hasType: true` with a different type, **When** update runs, **Then** error surfaces `Synergy type cannot be changed` / designation immutable (no silent change).

---

### User Story 3 - Evidence links editor (Priority: P1)

As a Windows user, I add and remove evidence links on a synergy and persist them.

**Why this priority**: Goal — “evidence links UI.”

**Independent Test**: Create synergy; add `exotic_armor` link with displayName; save; list shows link; remove and save.

**Acceptance Scenarios**:

1. **Given** a selected synergy, **When** I add a link kind `exotic_armor` displayName "Synthoceps" itemHash 1001 and save links, **Then** detail lists that link.
2. **Given** a synergy with one link, **When** I remove it and save, **Then** evidence list is empty.
3. **Given** invalid link kind (not offered in UI), **When** valid kinds only, **Then** save succeeds without crash.

---

### User Story 4 - Navigation to Synergies (Priority: P2)

As a Windows user, I navigate to Synergies from the host NavigationRail.

**Why this priority**: Discoverability.

**Independent Test**: Pump host app; select Synergies; page key visible.

**Acceptance Scenarios**:

1. **Given** the host app, **When** I select the Synergies rail destination, **Then** the synergy library page is shown.
2. **Given** Catalog/Sets/Settings still exist, **When** I switch destinations, **Then** they remain reachable.

---

### Edge Cases

- Empty synergy name after trim → validation error, no write.
- Empty link displayName → validation error, no write.
- Catalog/manifest not required for create (links may be hash-only or name-only).
- Soft guidance never auto-applies.
- Delete synergy optional this slice (create/edit/links suffice for exit criteria).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Windows host MUST expose a **Synergies** library screen with dual-pane list + detail.
- **FR-002**: User MUST be able to **create** a synergy (name + creatable type + optional subtype + description) via `createUserSynergy`.
- **FR-003**: User MUST be able to **edit** name and description via `updateUserSynergy` without changing designation.
- **FR-004**: Detail pane MUST show designation as **immutable** after create (no type/subtype editors on edit).
- **FR-005**: User MUST be able to **add/remove evidence links** and persist via update with validated kinds.
- **FR-006**: Shell MUST add a NavigationRail destination for Synergies.
- **FR-007**: Host MUST resolve local `userId` for library ops (signed-in or local-library fallback).
- **FR-008**: Soft suggestions MUST NOT auto-apply; no CLIENT_SECRET; no Node sidecar.
- **FR-009**: Tests MUST cover create, designation immutability UX, and evidence link add path.

### Key Entities

- **Library synergy**: name, type, subType, description, links.
- **Designation**: type + optional subType (immutable after create).
- **Evidence link**: kind, displayName, optional item/perk/hash fields.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Create synergy → list shows it with designation (widget evidence).
- **SC-002**: After create, designation cannot be edited in UI; rename keeps type/subtype.
- **SC-003**: Add evidence link → persists and displays.
- **SC-004**: Synergies page reachable from nav rail.
- **SC-005**: `flutter test` synergy suite green; no CLIENT_SECRET in client code.

## Assumptions

See Scope boundary Assumptions A1–A8.
