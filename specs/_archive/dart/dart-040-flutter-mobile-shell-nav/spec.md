# Feature Specification: DART-040 Flutter Mobile Shell Nav

**Feature Branch**: `dart-040-flutter-mobile-shell-nav`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Android+iOS app shell: bottom nav, Focus Swap routes, shared use cases. Installable debug builds; Settings+Build list at minimum."

**Program ID**: DART-040  
**Phase**: P4  
**Depends**: DART-034 (compose/soft guidance on Windows complete; mobile shell reuses shared packages/use cases)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- New **Flutter mobile host** app under `apps/mobile_host` targeting **Android + iOS**
- **Bottom navigation** shell (Material NavigationBar / equivalent) with at least:
  - **Builds** (list)
  - **Settings**
- **Focus Swap routes** (DESIGN.md *Focus Swap Rule*): on narrow/mobile, **library XOR detail** — tapping a build opens a detail route (list not dual-paned with detail); back returns to list
- Wire **shared in-process use cases** (`destiny2_app`) for local build list (and detail load) against single Drift `AppDatabase`
- Bootstrap: StorageRoot via path_provider application-support (not repo `.cache`), single DB connection, Matte Flap theme tokens
- Settings minimum: local storage/DB path + manifest status (or stub status when no refresh API)
- **Installable debug builds**: Android debug APK (or `flutter build apk --debug`) succeeds on CI/dev Windows host; iOS project files present for Xcode on macOS
- Widget/unit tests for shell nav + Builds list + Focus Swap with memory/temp DB (no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- Full mobile compose density (attach sets, pins, soft chips UI polish) — **DART-041**
- Mobile OAuth deep links / secure token UX (Windows loopback remains DART-023; mobile auth can stub “local library” only)
- Catalog / Sets / Synergies / Equip / DIM / Optimizer surfaces on mobile
- Jaspr web
- Node sidecar / CLIENT_SECRET
- Soft guidance auto-apply (forbidden)
- Dual-pane Windows-style library+detail on phone

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Installable mobile shell launches (Priority: P1)

As a developer/user, I can install/run a Flutter **mobile** debug build (Android at minimum on this Windows port machine) that opens StorageRoot + a single Drift DB and shows the app shell without crashing.

**Why this priority**: Roadmap exit — installable debug builds.

**Independent Test**: `flutter build apk --debug` (Android) succeeds; bootstrap unit test opens single DB and disposes cleanly. iOS folder present (`ios/`).

**Acceptance Scenarios**:

1. **Given** a writable application-support path, **When** bootstrap runs, **Then** StorageRoot layout exists and one `AppDatabase` is opened.
2. **Given** bootstrap completed, **When** the app UI builds, **Then** the bottom nav shell is visible with Builds and Settings destinations.
3. **Given** services dispose, **When** shutdown, **Then** the DB connection is closed.
4. **Given** the mobile host package, **When** Android debug APK is built, **Then** the build completes successfully (installable artifact produced).

---

### User Story 2 - Builds list via shared use cases (Priority: P1)

As a mobile user (signed-out local library), I open the **Builds** tab and see my local builds listed via `destiny2_app` list use cases (not a fake hard-coded list). Empty state is clear when no builds exist.

**Why this priority**: Roadmap exit — Build list at minimum; shared use cases.

**Independent Test**: Seed builds with `createUserBuild` / ensureUser in memory DB → pump Builds list → rows show names/class; empty DB shows empty state.

**Acceptance Scenarios**:

1. **Given** no builds for the local library user, **When** Builds tab loads, **Then** an empty state is shown (no crash).
2. **Given** one or more builds created via shared use cases, **When** Builds tab loads, **Then** each build name (and class summary) appears in the list.
3. **Given** the Builds list, **When** data is loaded, **Then** loading/error states are represented without silent hang.

---

### User Story 3 - Focus Swap: list XOR detail (Priority: P1)

As a mobile user, tapping a build navigates to a **detail route** that replaces the list focus (not a side-by-side dual pane). System/back returns to the list. Bottom nav remains available for top-level destinations.

**Why this priority**: Roadmap exit — Focus Swap routes.

**Independent Test**: Widget test: pump shell → select build row → detail route key visible, list route not co-visible dual-pane → pop → list visible again.

**Acceptance Scenarios**:

1. **Given** a builds list with at least one build, **When** I tap a row, **Then** a detail screen for that build is pushed (Focus Swap).
2. **Given** build detail is open, **When** I go back, **Then** I return to the Builds list.
3. **Given** build detail is open, **When** I switch bottom nav to Settings, **Then** Settings is shown; returning to Builds restores list (detail not silently dual-mounted as desktop pane).

---

### User Story 4 - Settings minimum surface (Priority: P1)

As a mobile user, I open **Settings** and see local storage/DB path and manifest status (or explicit unknown/stale stub) without OAuth secret fields.

**Why this priority**: Roadmap exit — Settings at minimum.

**Independent Test**: Inject fake manifest status → pump Settings → assert path + version fields; assert no CLIENT_SECRET.

**Acceptance Scenarios**:

1. **Given** bootstrap services, **When** Settings loads, **Then** DB/storage path is visible.
2. **Given** a fixed ManifestStatus, **When** Settings loads, **Then** cached/remote/stale (or equivalent) fields are shown.
3. **Given** Settings, **When** inspected, **Then** no CLIENT_SECRET or confidential OAuth secret UI exists.

---

### Edge Cases

- Bootstrap failure (unwritable path) → error app surface, not blank hang.
- Rapid tab switching while builds load → no double-open DB; no uncaught dispose races in tests.
- Empty build name → still listable (fallback label).
- Soft guidance never auto-applies; no compose soft chips required in this slice.
- iOS installable build may require macOS/Xcode; slice still ships `ios/` project and Android debug artifact proof on Windows.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Host MUST be a Flutter app under `apps/mobile_host` with **Android** and **iOS** platform folders.
- **FR-002**: Host MUST present bottom navigation with **Builds** and **Settings** destinations at minimum.
- **FR-003**: Host MUST resolve StorageRoot via application-support path (path_provider) and open a **single** `AppDatabase` for the app lifetime.
- **FR-004**: Builds list MUST load via shared `destiny2_app` use cases (`listUserBuilds` / `getBuildDetail` as needed) against the host DB.
- **FR-005**: Selecting a build MUST use **Focus Swap** navigation (list XOR detail route), not Windows dual-pane.
- **FR-006**: Settings MUST show storage/DB path and manifest status (injectable `ManifestRefreshApi` / fake).
- **FR-007**: Host MUST NOT embed CLIENT_SECRET; pure Dart I/O only (no Node sidecar).
- **FR-008**: Soft guidance MUST never auto-apply.
- **FR-009**: Automated tests MUST cover bootstrap single-DB, bottom nav destinations, Builds list (empty + seeded), and Focus Swap navigation.
- **FR-010**: Android debug build MUST succeed (`flutter build apk --debug` or equivalent) as installable-build evidence on the Windows port machine.

### Key Entities

- **MobileAppServices / MobileHostBootstrap**: Owns StorageRoot, single AppDatabase, optional ManifestRefreshApi; dispose closes DB.
- **Mobile shell**: Bottom nav + nested Navigator for Builds Focus Swap.
- **Build list controller**: Resolves local library user + lists builds via destiny2_app.
- **Settings page**: Path + manifest status only (minimum).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `flutter test` in `apps/mobile_host` passes shell/nav/list/settings tests.
- **SC-002**: Android debug APK build succeeds for `apps/mobile_host`.
- **SC-003**: `ios/` platform project exists for future macOS installable builds.
- **SC-004**: Workspace includes `apps/mobile_host` in root `pubspec.yaml` workspace members.
- **SC-005**: No CLIENT_SECRET; soft never auto-applies.

## Assumptions

- **A1**: Package name `destiny2_mobile_host` under `apps/mobile_host/`. Platforms: `android` + `ios` only (no web/desktop required for this app).
- **A2**: Local library membership id `local-library` (same convention as Windows host) when no OAuth session — mobile OAuth deferred.
- **A3**: Manifest status uses existing `ManifestRefreshApi` / `WindowsManifestRefresh` or a thin mobile-friendly status adapter; full mobile manifest download is out of scope (status-only or fake in tests).
- **A4**: Bottom nav may include only Builds + Settings for MVP; additional tabs deferred to later mobile slices.
- **A5**: Focus Swap is implemented with a nested `Navigator` (or equivalent) under the Builds tab so detail does not use dual-pane.
- **A6**: Detail screen shows **read-only identity summary** (name, class, synergy types, exotics) — not full variant compose (DART-041).
- **A7**: iOS codesigned install may be unavailable on Windows; presence of `ios/` + Android APK satisfies “installable debug builds” for this environment.
- **A8**: Theme reuses Flap tokens (`destiny2_ui_tokens`) with a mobile theme builder (may live in mobile_host, not share Windows widget trees).
- **A9**: Soft guidance never auto-applies; no hard DBR mutation beyond listing existing builds.
- **A10**: No NEEDS CLARIFICATION retained — defaults above apply.
