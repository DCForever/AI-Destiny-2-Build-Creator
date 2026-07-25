# Feature Specification: DART-019 Flutter Windows Host Skeleton

**Feature Branch**: `dart-019-flutter-windows-host-skeleton`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Minimal Flutter Windows app: open DB, show Settings stub (manifest status only). App launches; single DB connection; no OAuth yet."

**Program ID**: DART-019  
**Phase**: P1  
**Depends**: DART-012 (StorageRoot), DART-013 (Drift schema / AppDatabase)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Create a **Flutter Windows** application shell under `apps/` (first user-visible multiplatform host)
- On launch: resolve **StorageRoot** via path_provider application-support (not repo `.cache`), **ensureLayout**, open a **single** Drift `AppDatabase` at `StorageRoot.appDbPath`
- **Settings stub** screen: display **manifest status only** (`cachedVersion`, `remoteVersion`, `isStale`, entity-cache summary when present) via DART-018 `WindowsManifestRefresh` / `ManifestRefreshApi`
- Single-writer DB lifecycle: one open connection for the app lifetime; close on dispose/shutdown
- Widget/unit tests for bootstrap + Settings display with injectable storage/DB/status (no live Bungie; no OAuth)
- Wire app into monorepo docs (packages/README, workspace as appropriate)

**Out of scope (later slices):**

- Catalog facets / browse (DART-020)
- OAuth / PKCE / secure token storage (DART-022/023)
- Inventory sync UI (DART-025)
- Design tokens / FlapBoard polish (DART-029)
- Full Settings refresh download UX as product polish (optional status re-query only)
- Mobile / Jaspr shells
- Node sidecar, CLIENT_SECRET in clients
- Soft guidance auto-apply

### Assumptions

- **A1**: App package name `destiny2_windows_host` under `apps/windows_host/`. Windows platform only for this slice (`flutter create --platforms=windows`); other platform folders not required.
- **A2**: Bungie API key is optional host config (`String?` from `--dart-define=BUNGIE_API_KEY=…` or env if convenient). Null key still allows launch + local status (remote may be null per DART-018).
- **A3**: “Single DB connection” means one `AppDatabase` instance owned by app bootstrap/services — no second file open for the same path in the host process.
- **A4**: Settings stub is the **home/default** route for this thin host (no full nav shell yet).
- **A5**: Full manifest download `refresh()` is not required for exit criteria; status query is. Host may expose a non-blocking “Reload status” that re-calls `status()` only.
- **A6**: `sqlite3_flutter_libs` (or equivalent) is allowed in the Flutter host so Drift native SQLite works on Windows; pure packages remain free of Flutter.
- **A7**: Soft guidance never auto-applies; no hard DBR UI in this slice.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - App launches and opens DB (Priority: P1)

As a Windows developer/user, I can start the Flutter Windows host and it creates/opens the app-support layout and a single SQLite database without OAuth.

**Why this priority**: Roadmap exit — “App launches; single DB connection.”

**Independent Test**: Bootstrap with temp StorageRoot (or path_provider fake) + `AppDatabase.file`; assert DB opens (e.g. `listUserTableNames` non-empty / SELECT 1); dispose closes connection.

**Acceptance Scenarios**:

1. **Given** a writable application-support base path, **When** bootstrap runs, **Then** StorageRoot layout dirs exist and `app.db` is opened via one `AppDatabase` instance.
2. **Given** bootstrap completed, **When** the app UI builds, **Then** no second independent `AppDatabase.file` is opened for the same path by the host services layer.
3. **Given** bootstrap, **When** services dispose, **Then** the DB connection is closed cleanly.

---

### User Story 2 - Settings stub shows manifest status (Priority: P1)

As a user, I open the app and see a Settings-oriented screen that shows manifest status fields only (no OAuth, no inventory sync).

**Why this priority**: Roadmap exit — “show Settings stub (manifest status only).”

**Independent Test**: Inject a fake `ManifestRefreshApi` returning fixed `ManifestStatus`; pump Settings widget; assert version/stale text on screen.

**Acceptance Scenarios**:

1. **Given** status with cached `v1`, remote `v2`, `isStale: true`, **When** Settings stub loads, **Then** UI shows cached version, remote version, and stale indicator.
2. **Given** no cached version (`cachedVersion: null`), **When** Settings loads, **Then** UI indicates missing/unknown local version without crashing.
3. **Given** entity cache meta present, **When** Settings loads, **Then** a brief entity-cache summary is visible (or explicitly “none”).
4. **Given** the host, **When** user looks for sign-in / OAuth, **Then** no OAuth UI or CLIENT_SECRET is present.

---

### Edge Cases

- Application-support path unavailable → surface error UI (not silent hang).
- Manifest status throws (e.g. IO) → Settings shows error message; app remains running; DB still open.
- Concurrent multi-window second process: out of scope (single-writer assumption); no multi-tab web.
- Soft guidance never auto-applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Host MUST be a Flutter app targeting Windows desktop under `apps/windows_host`.
- **FR-002**: On launch, host MUST resolve StorageRoot via application-support path (path_provider) and call `ensureLayout`.
- **FR-003**: Host MUST open exactly one `AppDatabase` for `StorageRoot.appDbPath` for the app lifetime (test overrides allowed).
- **FR-004**: Host MUST show a Settings stub that displays manifest status from `ManifestRefreshApi` (`cachedVersion`, `remoteVersion`, `isStale`, entity cache summary when available).
- **FR-005**: Host MUST NOT implement OAuth, token storage, or inventory sync UI.
- **FR-006**: Host MUST NOT embed CLIENT_SECRET; public API key only if configured.
- **FR-007**: Pure Dart packages remain free of Flutter dependencies; host depends on `destiny2_storage`, `destiny2_db`, `destiny2_manifest` (path).
- **FR-008**: Soft guidance never auto-applies.
- **FR-009**: Automated tests MUST cover bootstrap (single DB open) and Settings status display with fakes/temp paths.

### Key Entities

- **AppServices / HostBootstrap**: Owns StorageRoot, single AppDatabase, ManifestRefreshApi; dispose closes DB.
- **ManifestStatus** (existing): cached/remote version, isStale, entityCache.
- **Settings stub**: Read-only status presentation surface.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `flutter test` (app package) passes bootstrap + Settings tests.
- **SC-002**: `flutter build windows` (or `flutter analyze` + compile smoke) succeeds on the Windows host package.
- **SC-003**: Manual/dev run launches a window showing Settings with status fields (or error state) without OAuth.
- **SC-004**: No CLIENT_SECRET and no OAuth code paths in this app package.

## Assumptions

See A1–A7 above. Defaults chosen to avoid NEEDS CLARIFICATION while matching roadmap exit criteria.
