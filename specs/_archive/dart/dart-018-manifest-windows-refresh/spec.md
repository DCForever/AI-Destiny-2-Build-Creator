# Feature Specification: DART-018 Manifest Windows Refresh

**Feature Branch**: `dart-018-manifest-windows-refresh`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Windows-only full/partial manifest refresh pipeline (download→extract→store). Settings-level API: status/isStale/refresh; rebuild off UI isolate."

**Program ID**: DART-018  
**Phase**: P1  
**Depends**: DART-017 (entity store reader + MVP extractors)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Extend **`destiny2_manifest`** with a Windows-oriented **download → extract → store** refresh pipeline under `StorageRoot` (app-support layout, not repo `.cache`)
- **BungieManifestService** (or equivalent): fetch remote manifest metadata, **partial** download (skip tables already on disk) and **full** re-download option, write `current-version.json`, load raw tables from disk
- **Settings-level API**: `status` / `isStale` / `refresh` suitable for a future Settings card (DART-019) without UI chrome in this slice
- **Rebuild off UI isolate**: after raw tables are current, run MVP entity `rebuild` via `Isolate.run` (or equivalent) so heavy extract does not block a UI isolate when a Flutter host appears
- Unit tests with **injected HTTP** (no live Bungie calls in CI) + temp `StorageRoot`

**Out of scope (later slices):**

- Flutter Windows Settings UI (DART-019)
- Catalog facets / browse UI (DART-020)
- Shared Bungie HTTP client package / OAuth (DART-021+)
- Non-MVP entity extractors as exit criteria (reuse DART-017 MVP rebuild only)
- Web / OPFS full raw rebuild (desktop-first per D-WEB-DB)
- Node sidecar, CLIENT_SECRET in clients
- Soft guidance auto-apply

### Assumptions

- **A1**: API key is injected as a `String?` by the host (env / secure config). Null key → `refresh` / `ensureCurrent` fail clearly; `status` may still report cached version with `remoteVersion: null`.
- **A2**: Default download table set matches product `RAW_TABLES` (all tables needed for full product parity later); MVP extractors only read the subset they need.
- **A3**: **Partial** = skip raw table files that already exist for the target version; **full** = re-download (overwrite) all required tables for the remote version.
- **A4**: Stale rule matches product: `isStale = true` when no cached version; `true` when cached ≠ remote; `false` when versions match; when remote check fails (`remoteVersion == null`) and cache exists → `isStale = false` (cannot prove stale); when no cache and remote fails → still `isStale = true`.
- **A5**: `refresh` = `ensureCurrent` (download) then isolate rebuild of MVP entity stores, then return fresh `ManifestStatus`.
- **A6**: Isolate rebuild reloads raw tables from disk inside the isolate (paths only passed across isolate boundary).
- **A7**: No Flutter dependency in `destiny2_manifest`; isolate uses `dart:isolate`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Settings status + isStale (Priority: P1)

As a Windows host Settings surface, I can query manifest status (cached version, remote version, isStale, entity cache meta) without downloading so the user sees whether a refresh is needed.

**Why this priority**: Roadmap exit — “Settings-level API: status/isStale/…”

**Independent Test**: Inject HTTP mock + temp StorageRoot; write/omit `current-version.json` and entity meta; assert status fields and `isStale`.

**Acceptance Scenarios**:

1. **Given** no cached version and remote version `v2`, **When** `status` / `isStale`, **Then** `cachedVersion` is null, `remoteVersion` is `v2`, `isStale` is true.
2. **Given** cached `v1` and remote `v2`, **When** status, **Then** `isStale` is true.
3. **Given** cached `v1` and remote `v1`, **When** status, **Then** `isStale` is false and entity meta is loaded when present.
4. **Given** network failure on remote check, **When** status, **Then** `remoteVersion` is null and stale rule follows A4.

---

### User Story 2 - Partial / full raw table download (Priority: P1)

As a multiplatform data layer, I can download missing raw Bungie tables for the latest version under `StorageRoot.manifestDir` (partial) or force re-download all tables (full), then persist `current-version.json`.

**Why this priority**: Roadmap goal — “full/partial manifest refresh pipeline (download→…).”

**Independent Test**: Mock manifest metadata + per-table GETs; assert partial skips existing files (fewer HTTP calls); full re-downloads; missing API key throws.

**Acceptance Scenarios**:

1. **Given** empty cache + API key, **When** `ensureCurrent` / partial refresh download, **Then** all required raw tables exist under `manifest/<versionDir>/` and version file is written.
2. **Given** all tables already on disk for remote version, **When** partial ensureCurrent, **Then** only metadata HTTP call occurs (no table re-downloads).
3. **Given** tables on disk, **When** full ensureCurrent (`forceFullDownload: true`), **Then** table files are overwritten (HTTP downloads tables again).
4. **Given** null API key, **When** ensureCurrent, **Then** clear error mentioning API key.

---

### User Story 3 - End-to-end refresh with isolate rebuild (Priority: P1)

As a Settings refresh action, I can call `refresh` to download current raw tables and rebuild MVP entity stores off the UI isolate, then get updated status with entity cache meta.

**Why this priority**: Roadmap exit — “refresh; rebuild off UI isolate.”

**Independent Test**: Mock HTTP for tables + use DART-017 raw fixtures written as table files OR mock download body with fixture JSON; `refresh` produces entity store files + meta; optional flag proves isolate path runs.

**Acceptance Scenarios**:

1. **Given** mocked download returning fixture-sized raw tables needed by MVP extractors, **When** `refresh`, **Then** entity `meta.json` and MVP store JSONs exist and status includes entityCache counts.
2. **Given** `rebuildInIsolate: true` (default for host API), **When** refresh completes, **Then** rebuild succeeded (stores readable via `FileEntityCache`) without requiring Flutter.
3. **Given** download succeeds but a required raw table is empty/invalid for extractors, **When** rebuild, **Then** error is surfaced (refresh fails) rather than silent empty success without meta (document: extractors may write empty stores; meta still written — match DART-017 rebuild semantics).

---

### Edge Cases

- Missing download path for a required table in Bungie metadata → clear error naming the table.
- HTTP non-2xx on metadata or table download → error with status code.
- Concurrent refresh: not required to serialize in this slice (single-writer host assumption); document no multi-tab web.
- Soft guidance never auto-applies; refresh only mutates manifest/entity files.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose Settings-level API with `status`, `isStale`, and `refresh`.
- **FR-002**: Package MUST implement remote version check + partial download (skip existing raw table files) and full re-download option.
- **FR-003**: Package MUST write/read `StorageRoot.currentVersionPath` (`current-version.json`).
- **FR-004**: Package MUST load raw tables from disk for a version (for rebuild and tests).
- **FR-005**: `refresh` MUST download (ensure current) then rebuild MVP entity stores via DART-017 `FileEntityCache.rebuild`.
- **FR-006**: Rebuild MUST be runnable off the UI isolate via `dart:isolate` (`Isolate.run` or equivalent top-level entry).
- **FR-007**: HTTP MUST be injectable for tests; no live network required for CI.
- **FR-008**: Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET; API key is host-injected public key only.
- **FR-009**: Soft guidance never auto-applies.
- **FR-010**: Domain package remains free of IO; manifest package may use `dart:io`, `dart:isolate`, `path`, storage, domain.

### Key Entities

- **ManifestStatus**: cachedVersion, remoteVersion, isStale, entityCache
- **BungieManifestService**: getStatus, ensureCurrent, loadRawTable
- **WindowsManifestRefresh** (Settings API): status, isStale, refresh
- **Isolate rebuild entry**: basePath + version → EntityCacheMeta

## Success Criteria *(mandatory)*

### Measurable Outcomes

- `dart test packages/manifest` green including new refresh/status/download tests
- Settings API callable without Flutter
- Partial download skips existing tables (asserted by mock call counts)
- Isolate rebuild path exercised in at least one test
- No secrets in package; no Node sidecar
