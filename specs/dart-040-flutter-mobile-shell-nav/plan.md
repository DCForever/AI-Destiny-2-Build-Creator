# Implementation Plan: DART-040 Flutter Mobile Shell Nav

**Branch**: `dart-040-flutter-mobile-shell-nav` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-040-flutter-mobile-shell-nav/spec.md`

## Summary

Ship a **Flutter Android+iOS** host shell (`apps/mobile_host`) with **bottom navigation** (Builds + Settings), **Focus Swap** routes (list XOR detail), and **shared** `destiny2_app` use cases for the build list. Exit: installable Android debug APK + iOS project present; Settings + Build list minimum. Soft never auto-applies; no CLIENT_SECRET.

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter 3.41+  
**Primary Dependencies**: Flutter Material 3, `destiny2_app`, `destiny2_db`, `destiny2_storage`, `destiny2_manifest` (status API), `destiny2_ui_tokens`, `path_provider`, `sqlite3_flutter_libs`  
**Storage**: StorageRoot application-support + single Drift `AppDatabase`  
**Testing**: `flutter test` in `apps/mobile_host`  
**Target Platform**: Android + iOS (Flutter mobile host)  
**Project Type**: UI shell slice (P4)  
**Performance Goals**: Cold start opens local DB; list is local query only  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; Focus Swap not dual-pane; soft never auto-applies  
**Scale/Scope**: Shell nav + Settings + Builds list/detail summary only

## Constitution Check

- I. Small Testable Increments: US1 bootstrap/build, US2 list, US3 Focus Swap, US4 Settings.
- II. Test-First: widget/unit tests co-landed with shell.
- III. Green Commit Checkpoints: mobile_host tests green; Android debug APK green.
- IV-V. Co-located tests under `apps/mobile_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-040-flutter-mobile-shell-nav/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/mobile_host/
  android/                 # Flutter Android
  ios/                     # Flutter iOS (project only on Windows)
  lib/
    main.dart
    app.dart               # bottom nav shell
    host_bootstrap.dart    # StorageRoot + single DB + status
    theme/flap_theme.dart
    builds/
      builds_controller.dart
      builds_list_page.dart
      build_detail_page.dart
      build_format.dart
    settings/settings_page.dart
    shell/focus_swap.dart  # optional route helpers / keys
  test/
    host_bootstrap_test.dart
    shell_nav_test.dart
    builds_list_test.dart
    settings_page_test.dart
  pubspec.yaml
  README.md
```

Root `pubspec.yaml` workspace: add `apps/mobile_host`.

## Implementation approach

1. `flutter create --platforms=android,ios --org com.destiny2buildcreator --project-name destiny2_mobile_host apps/mobile_host`
2. Wire workspace deps + HostBootstrap (mirror Windows minimal path: StorageRoot, single DB, ManifestRefreshApi injectable).
3. Theme from ui_tokens.
4. App shell: NavigationBar Builds | Settings; Builds tab nested Navigator (list → detail).
5. BuildsController: ensureUser(local-library) → listUserBuilds; select → getBuildDetail.
6. Settings: path + status card.
7. Tests + `flutter build apk --debug`.
8. Docs/README/roadmap finish-spec.

## Structure Decision

New mobile host app only. Reuse packages (`app`, `db`, `storage`, `manifest`, `ui_tokens`). Do not port Windows dual-pane widgets. OAuth deferred.
