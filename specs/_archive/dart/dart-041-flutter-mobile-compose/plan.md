# Implementation Plan: DART-041 Flutter Mobile Compose

**Branch**: `dart-041-flutter-mobile-compose` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-041-flutter-mobile-compose/spec.md`

## Summary

Extend **`apps/mobile_host`** with reduced-density compose: create-build sheet, linear detail (variants → attach sheet → pins → soft guidance). Reuse `destiny2_app` use cases already proven on Windows (DART-033/034). Soft never auto-applies; hard blocks stay hard. **P4 phase gate**.

## Technical Context

**Language/Version**: Dart SDK ^3.5 / Flutter 3.41+  
**Primary Dependencies**: Flutter Material 3, `destiny2_app`, `destiny2_db`, `destiny2_domain`, existing mobile shell  
**Storage**: Single Drift `AppDatabase` (DART-040 bootstrap)  
**Testing**: `flutter test` in `apps/mobile_host`  
**Target Platform**: Android + iOS mobile host  
**Project Type**: UI shell density slice (P4)  
**Performance Goals**: Local-only compose ops; soft coverage query on variant select  
**Constraints**: Pure Dart I/O; no Node; no CLIENT_SECRET; sheets + linear scroll; soft never auto-applies  
**Scale/Scope**: Create + attach + pins + soft on existing Focus Swap detail only

## Constitution Check

- I. Small Testable Increments: US1 create, US2 attach/pins, US3 soft, US4 linear density.
- II. Test-First: format + compose widget tests co-landed.
- III. Green Commit Checkpoints: mobile_host tests green before finish-spec.
- IV-V. Co-located tests under `apps/mobile_host/test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-041-flutter-mobile-compose/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/mobile_host/lib/
  builds/
    builds_controller.dart      # extend: create, variants, attach, pins, soft
    builds_list_page.dart       # FAB + create sheet
    build_detail_page.dart      # linear compose sections
    build_format.dart           # existing list helpers
    variant_compose_format.dart # pin/attachment labels
    soft_guidance_format.dart   # chips / soft targets / advisory
    create_build_sheet.dart     # modal create form
    attach_set_sheet.dart       # modal set picker
  ...
apps/mobile_host/test/
  variant_compose_format_test.dart
  soft_guidance_format_test.dart
  mobile_compose_test.dart      # create → attach → soft path
  builds_list_test.dart         # keep empty/seeded + create entry
```

## Implementation approach

1. Port pure format helpers (variant pin + soft guidance) into mobile_host (no Windows import).
2. Expand `BuildsController` with compose state/methods mirrored from Windows `BuildsLibraryController` (local-library only — no OAuth session deps).
3. Create-build bottom sheet from list FAB; on success push Focus Swap detail.
4. Rewrite detail as linear ListView sections + attach sheet + soft targets fields.
5. Tests with memory DB: create, attach wishlist pin, soft missing chip + non-auto-apply.
6. README + roadmap finish-spec merge to `feature/multiplatform-dart`.

## Structure Decision

Stay inside `apps/mobile_host`. Do not share Windows widget trees. Domain/use cases only via packages.
