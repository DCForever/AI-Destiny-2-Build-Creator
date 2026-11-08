# Feature Specification: DART-030 Flutter Sets Library UI

**Feature Branch**: `dart-030-flutter-sets-library-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Sets library + slot fill → catalog pick (Windows dual-pane). Create/edit set; fill slot from catalog/owned."

**Program ID**: DART-030  
**Phase**: P3  
**Depends**: DART-027 (set use cases), DART-029 (design tokens / FlapBoard contracts), DART-026 (catalog all/owned + instance projections)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter **Sets library** screen on Windows host with **dual-pane** layout:
  - Left rail (~`kFlapLibraryRailWidth` 320): list of user sets (name / type / status) using FlapBoard column contract intent
  - Right pane: set create/edit identity (name, type) + **slot board** for that set type
- **Create** and **edit** library sets via in-process `destiny2_app` set use cases (no HTTP)
- **Fill a slot** by opening a **catalog pick** flow (All | Owned scope) and upserting a set item (definition hash + name; optional owned `instanceId` when user picks a copy)
- Clear empty vs filled slot affordance; remove/clear filled slot (soft-remove via use case)
- NavigationRail destination for **Sets** in Windows shell
- Pure **slot mapping** helpers: slots-for-set-type, catalog bucket → set slot, validity checks (parity with product `slotsForSetType` / bucket maps for weapon+armor)
- Widget + unit tests with memory DB + preloaded catalog fixtures

**Out of scope (later slices):**

- Synergy library UI (DART-031)
- Build identity / variant attach UI (DART-032/033)
- Soft coverage chips (DART-034)
- Hard exotic/mod-energy kit gates on set composition (use cases stay persistence-level as DART-027)
- Optimizer constraints editor, linked mod-set wiring UI polish
- Full fashion catalog entity coverage (fashion slots may show as empty fill targets; picker may be empty without fashion entities)
- Perk grid / plug name resolution
- Soft guidance auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)
- Jaspr / mobile shells

### Assumptions

- **A1**: Local library user — when signed in, resolve `userId` like catalog (session membership + `ensureUser` / inventory sync local id). When signed out, use a stable **local-library** user row (`bungieMembershipId: 'local-library'`) so offline create/edit still works.
- **A2**: Dual-pane is **list + detail** on the Sets page (not Catalog split). Catalog pick is a dialog / modal panel over the detail pane.
- **A3**: Slot lists: weapon = primary/special/heavy; armor = helmet/arms/chest/legs/class_item; pair = exotic_weapon/exotic_armor; fashion = fashion slots; mod = armor piece targets for fill UI (mods_only storage keys on write when needed).
- **A4**: Catalog bucket labels (Kinetic/Energy/Power, Helmet/Gauntlets/…) map to set slots when filtering/suggesting fill; if mapping unknown, picker shows broader type-relevant catalog without hard crash.
- **A5**: Instance pin: 0 owned copies → wishlist (null instanceId); 1 copy → may auto-pin that instance; many → user picks instance or definition-only. Soft guidance never auto-applies.
- **A6**: Theme tokens from DART-029; no full brand rewrite of Catalog/Settings.
- **A7**: Soft suggestions never auto-apply; hard DBR blocks stay hard where domain says so — this slice does not add kit evaluators to set fill.
- **A8**: Pure Dart I/O only; host calls `destiny2_app` in-process.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sets library dual-pane list + create/edit (Priority: P1)

As a Windows user, I open **Sets**, see my library in a left rail, create a new set (name + type), select it, and edit its name — changes persist via set use cases.

**Why this priority**: Exit criterion — “Create/edit set.”

**Independent Test**: Widget test with memory DB; create weapon set → appears in list → rename → list/detail show new name.

**Acceptance Scenarios**:

1. **Given** empty library, **When** I create a weapon set named "Kinetic Core", **Then** it appears in the list and detail shows type weapon and empty slots.
2. **Given** a selected set, **When** I rename it to "Kinetic V2" and save, **Then** list and detail show the new name.
3. **Given** duplicate name same type, **When** create fails, **Then** UI surfaces an error (no crash).
4. **Given** dual-pane layout, **When** Sets page renders, **Then** left rail is present (~library rail width contract) and detail pane is beside it.

---

### User Story 2 - Fill slot from catalog / owned pick (Priority: P1)

As a Windows user editing a set, I pick an empty (or filled) slot, open catalog pick (All or Owned), choose a definition (and optional instance), and the slot fills with that item.

**Why this priority**: Exit criterion — “fill slot from catalog/owned.”

**Independent Test**: Widget/integration test: seed preloaded catalog + optional inventory; fill primary with fixture weapon → active set items include that hash/name.

**Acceptance Scenarios**:

1. **Given** a weapon set, **When** I fill **primary** with catalog item hash H name N (wishlist), **Then** set detail active items include slot primary with itemHash H and null instanceId.
2. **Given** owned inventory for hash H with one instance, **When** I pick that definition in Owned scope (or pick the instance), **Then** set item may store that instanceId (auto or explicit pick).
3. **Given** a filled slot, **When** I clear/remove it, **Then** active items no longer include that slot.
4. **Given** catalog All vs Owned toggle in the picker, **When** Owned is selected with no inventory, **Then** empty guidance shows (no crash).

---

### User Story 3 - Navigation to Sets in shell (Priority: P2)

As a Windows user, I can navigate to Sets from the host NavigationRail alongside Catalog and Settings.

**Why this priority**: Discoverability of the library.

**Independent Test**: Pump `Destiny2WindowsApp`; select Sets destination; Sets page key is visible.

**Acceptance Scenarios**:

1. **Given** the host app, **When** I select the Sets rail destination, **Then** the Sets library page is shown.
2. **Given** Catalog/Settings still exist, **When** I switch destinations, **Then** previous destinations remain reachable (IndexedStack or equivalent).

---

### Edge Cases

- Empty set name after trim → validation error, no write.
- Set deleted while attached (set-in-use) → error message if delete is offered; delete optional this slice if only create/edit/fill required.
- Catalog empty (no entity stores) → picker shows empty guidance; set create still works.
- Soft guidance never auto-applies; picker does not auto-mutate other slots.
- Mod/fashion types: slots board still renders; picker may show empty or unfiltered catalog without hard domain kit checks.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Windows host MUST expose a **Sets** library screen with dual-pane list + detail.
- **FR-002**: User MUST be able to **create** a set (name + type) via `createUserSet`.
- **FR-003**: User MUST be able to **edit** set identity fields (at least name) via `updateUserSet`.
- **FR-004**: Detail pane MUST show **slots** for the selected set’s type (weapon/armor/pair at minimum).
- **FR-005**: User MUST be able to **fill a slot** by picking from catalog (All/Owned) and persisting via `upsertUserSetItem`.
- **FR-006**: User MUST be able to **clear** a filled slot via `removeUserSetItem` (or equivalent soft-remove).
- **FR-007**: Catalog pick MUST reuse offline catalog + owned annotate/instance projection patterns from DART-020/026 (no live Bungie on pick browse).
- **FR-008**: Host MUST resolve a local `userId` for library ops (signed-in user or stable local-library fallback).
- **FR-009**: Shell MUST add a NavigationRail destination for Sets.
- **FR-010**: Pure slot-mapping helpers MUST cover slots-for-type and catalog bucket → set slot for weapons/armor.
- **FR-011**: Soft suggestions MUST NOT auto-apply; no CLIENT_SECRET; no Node sidecar.
- **FR-012**: Tests MUST cover create/edit and slot fill paths.

### Key Entities

- **Library set**: name, type, tags (optional UI), active set items by slot.
- **Set item**: slot wire name, itemHash, itemName, optional instanceId.
- **Catalog pick result**: CatalogItem + optional CatalogInstanceProjection.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Create set → list shows it; edit name → list updates (widget/unit evidence).
- **SC-002**: Fill one slot from preloaded catalog → activeItems contains that hash/slot.
- **SC-003**: Dual-pane Sets page reachable from nav rail.
- **SC-004**: `flutter test` (host sets suite) + related pure tests green; no CLIENT_SECRET in client code.

## Assumptions

See Scope boundary Assumptions A1–A8.
