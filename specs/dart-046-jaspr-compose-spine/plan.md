# Implementation Plan: DART-046 Jaspr Compose Spine

**Branch**: `dart-046-jaspr-compose-spine` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-046-jaspr-compose-spine/spec.md`

## Summary

Port the **compose spine** (Builds / Sets / Synergies / Catalog nav) to the Jaspr web host using the same in-process `destiny2_app` use cases as Flutter. Writer-tab Drift DB owns library data; soft coverage is display-only; hard DBR gates stay hard. Exit: Intent→compose with hard/soft parity.

## Technical Context

**Language/Version**: Dart SDK ^3.10 (web_host), packages ^3.5+

**Primary Dependencies**: Jaspr + jaspr_router; destiny2_app, destiny2_db, destiny2_domain, destiny2_manifest, destiny2_bungie, destiny2_ui_tokens; Drift WASM (existing)

**Storage**: Writer-tab AppDatabase (OPFS/WASM in browser; memory in tests)

**Testing**: `dart test` + jaspr_test component tests in `apps/web_host/test`

**Target Platform**: Browser (Jaspr client SPA)

**Project Type**: Web SPA host app + shared pure packages

**Performance Goals**: Interactive compose on local DB; no network for library CRUD

**Constraints**: No CLIENT_SECRET; soft never auto-applies; no Node sidecar; blocked tab cannot write

**Scale/Scope**: Four compose surfaces + format helpers + controllers; ~15–20 tasks

## Constitution Check

- I. Small Testable Increments: US1 build create → US2 libraries → US3 attach/pins → US4 soft → US5 nav
- II. Test-First: Controller tests with memory DB before/with UI wiring; pure format unit tests
- III. Green Commit Checkpoints: `dart test` in apps/web_host green before finish-spec merge
- IV-V. Co-located tests under `apps/web_host/test/`; validation in use cases already

## Project Structure

### Documentation (this feature)

```text
specs/dart-046-jaspr-compose-spine/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
apps/web_host/
├── lib/
│   ├── app.dart                          # routes: /builds, /builds/:id, /sets, /synergies
│   ├── main.client.dart                  # wire ComposeServices when writer DB ready
│   ├── components/shell_header.dart      # nav spine
│   ├── compose/
│   │   ├── compose_services.dart
│   │   ├── build_format.dart
│   │   ├── soft_guidance_format.dart
│   │   ├── variant_compose_format.dart
│   │   └── set_slot_mapping.dart
│   ├── builds/
│   │   ├── builds_controller.dart
│   │   ├── builds_page.dart
│   │   └── build_compose_page.dart
│   ├── sets/
│   │   ├── sets_controller.dart
│   │   └── sets_page.dart
│   └── synergies/
│       ├── synergies_controller.dart
│       └── synergies_page.dart
└── test/
    ├── build_format_test.dart
    ├── soft_guidance_format_test.dart
    ├── variant_compose_format_test.dart
    ├── builds_controller_test.dart
    ├── sets_controller_test.dart
    ├── synergies_controller_test.dart
    ├── builds_page_test.dart
    └── shell_nav_compose_test.dart
```

**Structure Decision**: Extend existing `apps/web_host` only. Reuse packages `destiny2_app` / `destiny2_db` / `destiny2_domain`. Controllers mirror mobile DART-041 (jaspr `ChangeNotifier`), not Flutter widgets.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Multiple page files | Spine has four destinations | Single mega-page hurts testability and nav |
