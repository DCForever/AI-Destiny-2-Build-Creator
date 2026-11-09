# Tasks: DART-018 Manifest Windows Refresh

**Input**: Design documents from `/specs/dart-018-manifest-windows-refresh/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1: Setup

- [x] T001 Confirm branch `dart-018-manifest-windows-refresh`; specs dir present
- [x] T002 Update `.specify/feature.json` → `specs/dart-018-manifest-windows-refresh`

## Phase 2: Types + HTTP surface

- [x] T003 Add ManifestStatus, downloadRawTables list, HTTP typedefs, computeIsStale to services types
- [x] T004 Implement default HttpClient-based ManifestHttpGet helper

## Phase 3: Manifest service (US1, US2)

- [x] T005 [US1/US2] Implement BungieManifestService (getStatus, ensureCurrent partial/full, loadRawTable)
- [x] T006 [US1/US2] Unit tests: status/isStale, partial skip, full redownload, missing key, loadRawTable

## Phase 4: Isolate rebuild + Settings API (US3)

- [x] T007 [US3] Implement isolate_rebuild entry (basePath + version → EntityCacheMeta)
- [x] T008 [US3] Implement WindowsManifestRefresh (status, isStale, refresh)
- [x] T009 [US3] Tests: refresh downloads + rebuild (isolate path); entity meta on status

## Phase 5: Polish & finish

- [x] T010 Export new APIs from destiny2_manifest.dart; update packages/README
- [x] T011 Mark tasks complete; `dart test packages/manifest` green (38)
- [x] T012 Commit; merge `--no-edit` into `feature/multiplatform-dart`; update roadmap pointer to DART-019; commit base
