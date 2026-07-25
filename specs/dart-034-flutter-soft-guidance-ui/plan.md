# Implementation Plan: DART-034 Flutter Soft Guidance UI

**Branch**: `dart-034-flutter-soft-guidance-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-034-flutter-soft-guidance-ui/spec.md`

## Summary

Extend the Flutter Windows **Builds** detail pane (after variant compose) with **soft guidance display**: coverage chips from `queryVariantCoverage`, optional set-bonus/element rows, and soft stat targets view/edit with **explicit** save. Soft results never auto-apply kit changes and never hard-block compose. Completes **P3 phase gate** (compose without equip).

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: `destiny2_app` (`queryVariantCoverage`, `updateUserBuild`), `destiny2_domain` (CoverageResult, SoftStatTargets), `destiny2_ui_tokens`, Flutter Windows host  
**Storage**: Drift via existing single `AppServices.db`  
**Testing**: `flutter test` apps/windows_host (format helpers + soft guidance page tests)  
**Target Platform**: Flutter Windows host  
**Project Type**: Flutter UI + thin pure helpers  
**Constraints**: Soft never auto-applies; pure Dart I/O; no Node sidecar; no CLIENT_SECRET; hard DBR blocks stay hard  
**Scale/Scope**: One Soft guidance section on Builds detail; fixture-scale

## Constitution Check

- I. Small Testable Increments: pure helpers → controller coverage/targets → UI → tests.
- II. Test-First: co-land widget tests with implementation.
- III. Green Commit Checkpoints before merge to `feature/multiplatform-dart`.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-034-flutter-soft-guidance-ui/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/windows_host/
  lib/
    builds/
      soft_guidance_format.dart        # pure tier/target labels
      builds_library_controller.dart   # + coverage query + soft targets save
      builds_library_page.dart         # + Soft guidance section
  test/
    soft_guidance_format_test.dart
    soft_guidance_page_test.dart
```

## Implementation approach

1. **Pure helpers** — format coverage tier label, soft-stat target summary, advisory caption string, optional chip tone key (success/warn/danger/muted).
2. **Controller** — after compose load for variant: `queryVariantCoverage`; expose `CoverageQueryResult?`; `saveSoftStatTargets(SoftStatTargets)`; draft map for UI fields; never call nudge accept without user action; never mutate attachments from coverage.
3. **UI** — Soft guidance section: advisory caption; Wrap of synergy chips; lists for set-bonus/element/soft-stat warnings; soft targets form (six stats) + Save soft targets button.
4. **Tests** — missing chip with unmatched evidence; soft target save; attach still works with soft miss; coverage does not clear attachments.
5. **Finish-spec** — merge to `feature/multiplatform-dart`; roadmap DART-034 done → pointer DART-035; note P3 gate complete.

## Structure Decision

UI only in `apps/windows_host`. Soft evaluators already in domain (DART-004); query use case in app (DART-028). No new package.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
