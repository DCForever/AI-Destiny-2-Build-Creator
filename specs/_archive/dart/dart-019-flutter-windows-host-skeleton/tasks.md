# Tasks: DART-019 Flutter Windows Host Skeleton

**Input**: Design documents from `/specs/dart-019-flutter-windows-host-skeleton/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1: Setup

- [x] T001 Confirm branch `dart-019-flutter-windows-host-skeleton`; specs dir present
- [x] T002 Update `.specify/feature.json` → `specs/dart-019-flutter-windows-host-skeleton`
- [x] T003 Scaffold Flutter Windows app at `apps/windows_host` (`destiny2_windows_host`)
- [x] T004 Add path deps (`destiny2_storage`, `destiny2_db`, `destiny2_manifest`) + path_provider + sqlite3_flutter_libs; add workspace member

## Phase 2: Bootstrap (US1)

- [x] T005 [US1] Implement `HostBootstrap` / `AppServices` in `apps/windows_host/lib/host_bootstrap.dart` (single DB, StorageRoot, ManifestRefreshApi; dispose closes DB)
- [x] T006 [US1] Unit tests for bootstrap open + single connection + dispose in `apps/windows_host/test/host_bootstrap_test.dart`

## Phase 3: Settings stub (US2)

- [x] T007 [US2] Implement Settings page (manifest status only) in `apps/windows_host/lib/settings/settings_page.dart`
- [x] T008 [US2] Wire `main.dart` / `app.dart` to bootstrap and show Settings as home
- [x] T009 [US2] Widget tests for status display + error/empty states in `apps/windows_host/test/settings_page_test.dart`

## Phase 4: Polish & finish

- [x] T010 Update `packages/README.md` and root docs pointers for `apps/windows_host`
- [x] T011 Mark tasks complete; `flutter test` green (5); analyze clean; `flutter build windows --debug` smoke OK
- [x] T012 Commit; merge `--no-edit` into `feature/multiplatform-dart`; update roadmap pointer to DART-020; commit base
