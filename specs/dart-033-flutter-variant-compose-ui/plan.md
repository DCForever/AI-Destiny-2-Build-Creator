# Implementation Plan: DART-033 Flutter Variant Compose UI

**Branch**: `dart-033-flutter-variant-compose-ui` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-033-flutter-variant-compose-ui/spec.md`

## Summary

Extend the Flutter Windows **Builds** detail pane with **variant compose**: list/create/select variants, attach/detach library sets, show slot pins (wishlist vs instance), pin/clear instance on live-attached set items, and surface hard conflicts (`SLOT_CONFLICT`) from existing `destiny2_app` use cases.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: `destiny2_app` (variant/attachment/set use cases), `destiny2_db`, `destiny2_domain`, `destiny2_ui_tokens`, Flutter Windows host  
**Storage**: Drift via existing single `AppServices.db` connection  
**Testing**: `flutter test` apps/windows_host (variant compose + pure format helpers)  
**Target Platform**: Flutter Windows host  
**Project Type**: Flutter UI + thin pure helpers  
**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; hard gates via use cases  
**Scale/Scope**: One detail section on Builds library; fixture-scale lists

## Constitution Check

- I. Small Testable Increments: pure helpers → controller → compose UI → tests.
- II. Test-First: co-land widget tests with implementation.
- III. Green Commit Checkpoints before merge to `feature/multiplatform-dart`.
- IV-V. Co-located tests under `apps/windows_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-033-flutter-variant-compose-ui/
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
      build_identity_format.dart       # (existing DART-032)
      builds_library_controller.dart   # + variant compose orchestration
      builds_library_page.dart         # + variant compose section
      variant_compose_format.dart      # pure pin/attachment labels
  test/
    variant_compose_format_test.dart
    variant_compose_page_test.dart
```

## Implementation approach

1. **Pure helpers** — `formatSlotPinLabel(instanceId)`, attachment summary, conflict/error display text.
2. **Controller** — when build selected: load variants; select default; list attachable sets; load attachments + expanded items / resolved claims for pins; `createUserVariant`; attach/detach via `updateUserVariant` with full `SetAttachmentInput` list; pin slot via `upsertUserSetItem` on live set; surface `UseCaseException` messages.
3. **UI** — under Builds detail: Variants strip (list + create name), Attachments (set dropdown + attach + list + detach), Slot pins board (slot · item · wishlist|instance + pin/clear controls).
4. **Tests** — attach set, pin wishlist/instance, slot conflict error, create variant.
5. **Finish-spec** — merge to `feature/multiplatform-dart`; roadmap DART-033 done → pointer DART-034.

## Structure Decision

UI lives only in `apps/windows_host`. Domain hard gates and attachment prepare stay in `destiny2_app` (already implemented DART-027/028). No new package.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
