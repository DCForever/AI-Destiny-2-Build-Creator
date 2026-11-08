# Implementation Plan: DART-042 Jaspr App Skeleton

**Branch**: `dart-042-jaspr-app-skeleton` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-042-jaspr-app-skeleton/spec.md`

## Summary

Stand up the first **Jaspr** web host (`apps/web_host` / `destiny2_web_host`): client-mode SPA with shell + `jaspr_router`, **Hello Settings** as primary page, and **Matte Flap design tokens as CSS** mapped from pure `destiny2_ui_tokens`. No Next.js, no OPFS/DB, no OAuth. Prove with unit/component tests and workspace membership.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace; scaffold may require ^3.10 for Jaspr 0.23)

**Primary Dependencies**: `jaspr`, `jaspr_router`, `jaspr_builder` (dev), `destiny2_ui_tokens` (path), `test` / `jaspr_test` (dev)

**Storage**: N/A this slice (no Drift/OPFS)

**Testing**: `dart test` in `apps/web_host`; token CSS pure unit tests; Settings component tests

**Target Platform**: Web (browser) via Jaspr client mode

**Project Type**: Jaspr web app host in Melos/pub workspace monorepo

**Performance Goals**: N/A (skeleton)

**Constraints**: No Next dependency; no CLIENT_SECRET; no Flutter Web product path; soft never auto-applies; pure token package remains free of Jaspr

**Scale/Scope**: One app package + docs; ~Hello Settings only

## Constitution Check

- I. Small Testable Increments: Single skeleton slice; stories US1–US3 independently testable.
- II. Test-First: Token CSS tests + Settings tests before/with implementation; green checkpoint before merge.
- III. Green Commit Checkpoints: `dart test` web_host + workspace pub get.
- IV–V. Co-located tests under `apps/web_host/test/`; validation of no-Next via pubspec inspection in tests or checklist.

## Project Structure

### Documentation (this feature)

```text
specs/dart-042-jaspr-app-skeleton/
├── plan.md
├── research.md
├── spec.md
├── quickstart.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code

```text
apps/web_host/
  pubspec.yaml              # destiny2_web_host; jaspr mode client; path ui_tokens
  analysis_options.yaml
  README.md
  lib/
    main.client.dart        # runApp(App)
    app.dart                # shell + Router
    components/
      shell_header.dart     # nav: Settings
    pages/
      settings_page.dart    # Hello Settings
    theme/
      flap_tokens_css.dart  # CSS vars from destiny2_ui_tokens
      theme.dart            # global @css using tokens
  test/
    flap_tokens_css_test.dart
    settings_page_test.dart
  web/
    index.html
    favicon.ico
```

**Structure Decision**: Adapt Jaspr CLI client+SPA scaffold under `apps/web_host`; replace demo Home/About/Counter with shell + Settings; integrate workspace + ui_tokens.

## Complexity Tracking

No constitution violations requiring extra packages beyond standard Jaspr host + existing pure tokens.
