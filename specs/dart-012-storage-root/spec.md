# Feature Specification: DART-012 Storage Root

**Feature Branch**: `dart-012-storage-root`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "StorageRoot abstraction + Windows path_provider layout (app support, not repo `.cache`). Paths documented; unit tests with fake FS."

**Program ID**: DART-012  
**Phase**: P1  
**Depends**: DART-011 (P0 gate done)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- **StorageRoot** abstraction: single logical root for multiplatform app on-disk layout (SQLite DB, manifest raw tables, entity stores, user prefs, current-version pointer)
- **Windows path_provider layout**: document and implement path composition for Flutter Windows **application support** directory (not process CWD / repo `.cache`)
- Pure path-joining helpers mirroring product `src/lib/manifest/cachePaths.ts` logical segments without the legacy `.cache` CWD root
- **Unit tests with fake FS** (injected base path / temp dir / in-memory path composition — no real Windows profile required)
- Package + layout documentation for later Drift (DART-013) and Flutter host (DART-019)

**Out of scope (later slices):**

- Drift schema / open DB (DART-013+)
- Manifest download/extract/refresh (DART-017–018)
- Flutter Windows app shell (DART-019)
- Legacy import from Next `.cache/app.db` (DART-048)
- OAuth token secure storage (DART-023 — not SQLite plaintext; not this package’s concern)
- Android/iOS/Jaspr path_provider wiring (same abstraction; platform factories later)
- Node sidecar or CLIENT_SECRET in clients (forbidden program-wide)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Resolve app paths under a StorageRoot (Priority: P1)

As a multiplatform data engineer, I can construct a `StorageRoot` from a base directory and resolve canonical paths for `app.db`, manifest tables, entity stores, users, and current-version so Drift and manifest adapters never invent divergent layouts.

**Why this priority**: Roadmap exit — “StorageRoot abstraction”; unblocks DART-013/017.

**Independent Test**: Unit tests inject a fake base path and assert joined paths for DB, manifest, entities, users, current-version (and version-sanitized subdirs).

**Acceptance Scenarios**:

1. **Given** a `StorageRoot` with base `C:\fake\app-support`, **When** I request the app DB path, **Then** it is `C:\fake\app-support\app.db` (platform separators via `package:path`).
2. **Given** a version string with unsafe path characters, **When** I request a raw table or entity store path, **Then** the version segment is sanitized consistently (same rules as product `versionToDirName`).
3. **Given** a membership id, **When** I request user preferences path, **Then** it lives under `users/<id>/preferences.json` beneath the root.

---

### User Story 2 - Windows app-support layout (not repo `.cache`) (Priority: P1)

As a Flutter Windows host author, I can obtain a `StorageRoot` from a `path_provider` application-support directory path so production data never writes into the git repo `.cache` tree used by Next.js.

**Why this priority**: Roadmap exit — “Windows path_provider layout (app support, not repo `.cache`)”; locked by D-PATH Phase 1 note.

**Independent Test**: Factory/helper accepts an application-support path (as returned by `getApplicationSupportDirectory()` on Windows) and produces the documented layout; docs state explicitly that CWD/`.cache` is legacy-only.

**Acceptance Scenarios**:

1. **Given** an application-support path string from path_provider (injected in tests), **When** I build the Windows app-support `StorageRoot`, **Then** the root equals that support directory (or a single documented app subfolder under it) and **not** `<cwd>/.cache`.
2. **Given** the slice quickstart/layout docs, **When** I read the Windows section, **Then** I see path_provider `getApplicationSupportDirectory` as the host resolution step and a note that Next.js `.cache` is not the Dart shell root.
3. **Given** pure packages (`destiny2_domain`, `destiny2_sandbox_data`), **When** I inspect their pubspecs, **Then** they still have zero `path_provider` / storage runtime deps (storage is a separate package).

---

### User Story 3 - Fake FS unit tests (Priority: P1)

As a CI job without a Windows user profile, I can run `dart test` on the storage package using a fake or temporary base path so layout correctness is proven offline.

**Why this priority**: Roadmap exit — “unit tests with fake FS.”

**Independent Test**: `dart test packages/storage` (or workspace entry) passes using only injected paths / temp directories; no network, no Flutter UI.

**Acceptance Scenarios**:

1. **Given** a fixed fake base path string, **When** path composition tests run, **Then** all documented relative segments match without creating real user AppData folders.
2. **Given** an optional ensure-directories helper, **When** tests use a system temp directory, **Then** required layout directories can be created and cleaned up without touching production app-support paths.

---

### Edge Cases

- Version strings with `../`, spaces, or URL-like characters: sanitized before joining.
- Empty base path: rejected or treated as invalid (documented).
- Concurrent hosts: single-writer SQLite semantics remain a later Drift concern; this slice only defines paths.
- Soft guidance never auto-applies; this slice has no product domain evaluators.
- Path separators: always via `package:path` so tests are stable across platforms when using POSIX-style fake bases where needed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST add a workspace package (e.g. `packages/storage`, pub name `destiny2_storage`) that exposes a **StorageRoot** type (or equivalent) for on-disk layout resolution.
- **FR-002**: StorageRoot MUST expose paths for at least: `app.db`, raw manifest table files under `manifest/<versionDir>/`, entity stores under `entities/<versionDir>/`, entity meta, current-version file, and user preferences under `users/<membershipId>/`.
- **FR-003**: Version directory names MUST sanitize unsafe filesystem characters consistently (parity intent with product `versionToDirName`).
- **FR-004**: Repository MUST provide a documented Windows app-support construction path: host obtains directory via path_provider `getApplicationSupportDirectory`, then builds StorageRoot from that path (package may keep path_provider out of pure unit-test surface by accepting a path string).
- **FR-005**: StorageRoot MUST NOT default to `Directory.current` / process CWD `.cache` as the production root.
- **FR-006**: Unit tests MUST cover path composition with a fake/injected base path (fake FS) and MUST pass via `dart test` without a Flutter device.
- **FR-007**: Paths MUST be documented (package README and/or slice quickstart) including Windows resolution and explicit non-use of repo `.cache` for Dart shells.
- **FR-008**: Pure packages listed in the P0 graph guard MUST remain free of storage/path_provider runtime dependencies; storage is not a pure domain package.
- **FR-009**: This slice MUST NOT open SQLite, download manifests, or create Flutter/Jaspr applications.

### Key Entities

- **StorageRoot**: Logical app data root + path factory methods for DB, manifest, entities, users.
- **Version directory name**: Sanitized form of a Bungie manifest version string used as a single path segment.
- **Windows app-support root**: Directory from path_provider application support used as StorageRoot base on Flutter Windows.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test` for the storage package passes on CI/dev machines with path composition + fake/temp base coverage.
- **SC-002**: Documented layout lists every top-level segment and Windows path_provider resolution step.
- **SC-003**: No production default path uses repo-relative `.cache`.
- **SC-004**: Workspace resolves the new package (`dart pub get`); pure graph guard still passes for domain/sandbox_data.

## Assumptions

- App-support base path is injected by the host; this slice does not require a running Flutter Windows app binary.
- Using the path_provider application-support directory **itself** as StorageRoot base (no extra nested product folder) is acceptable when the Flutter Windows runner already scopes company/product names; if a subfolder is added later, it must be a single documented constant.
- Layout segment names (`manifest`, `entities`, `users`, `app.db`, `current-version.json`) mirror product logical layout without the `.cache` parent name.
- `package:path` is allowed; `path_provider` need not be a runtime dependency of `destiny2_storage` if hosts pass the resolved path string (preferred for unit-test purity). If a thin optional helper is added later that imports path_provider, it must not break `dart test` of pure composition.
- Soft/hard DBR rules are unchanged; no domain package edits required for behavior.
- No NEEDS CLARIFICATION markers retained; defaults above are locked for implement.
