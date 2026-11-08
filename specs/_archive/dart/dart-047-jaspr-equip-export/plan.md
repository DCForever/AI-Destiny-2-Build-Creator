# Implementation Plan: DART-047 Jaspr Equip Export

**Branch**: `dart-047-jaspr-equip-export` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-047-jaspr-equip-export/spec.md`

## Summary

Port **equip-ready**, **DIM jsonOnly clipboard export**, and **optional equip** to the Jaspr web host on Build compose. Reuse the same pure domain packages as Flutter (DART-006/010/037): `computeEquipReady`, `buildJsonOnlyDimExport`, `planEquipSteps` / `executeEquipPlan`. Soft never auto-applies; hard equip-ready gates stay hard. Exit: same domain packages as Flutter; tests with memory DB + mock write/clipboard.

## Technical Context

**Language/Version**: Dart SDK ^3.10 (web_host)

**Primary Dependencies**: Jaspr; destiny2_app, destiny2_db, destiny2_domain, destiny2_bungie; existing WebOAuthSession

**Storage**: Writer-tab AppDatabase (memory in tests)

**Testing**: `dart test` in `apps/web_host` (unit + light component)

**Target Platform**: Browser (Jaspr client SPA)

**Project Type**: Web SPA host + shared pure packages

**Performance Goals**: Local readiness + clipboard; equip write is best-effort network

**Constraints**: No CLIENT_SECRET; soft never auto-applies; no Node sidecar; no dim.gg

**Scale/Scope**: Format helpers + two controllers + compose sections + tests; ~15 tasks

## Constitution Check

- I. Small Testable Increments: US1 readiness → US2 DIM → US3 optional equip
- II. Test-First: format + controller tests before/with UI wiring
- III. Green Commit Checkpoints: `dart test` in apps/web_host green before merge
- IV-V. Co-located tests under `apps/web_host/test/`

## Project Structure

### Documentation (this feature)

```text
specs/dart-047-jaspr-equip-export/
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
│   ├── equip/
│   │   ├── equip_format.dart
│   │   └── equip_controller.dart
│   ├── dim_export/
│   │   ├── dim_export_format.dart
│   │   └── dim_export_controller.dart
│   ├── builds/build_compose_page.dart   # sections for equip + DIM
│   ├── compose/compose_services.dart    # optional equip/dim wiring
│   ├── app.dart
│   └── main.client.dart                 # profile/write clients + public API key
└── test/
    ├── equip_format_test.dart
    ├── dim_export_format_test.dart
    ├── equip_controller_test.dart
    ├── dim_export_controller_test.dart
    └── no_client_secret_equip_test.dart
```

**Structure Decision**: Extend `apps/web_host` only. Controllers mirror Windows DART-038/039 logic with Jaspr `ChangeNotifier` (no Flutter widgets). Domain packages unchanged.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Separate equip + dim controllers | Independent gates and tests | One mega-controller mixes clipboard and write paths |
