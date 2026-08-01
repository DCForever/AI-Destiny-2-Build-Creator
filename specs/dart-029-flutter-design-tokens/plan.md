# Implementation Plan: DART-029 Flutter Design Tokens

**Branch**: `dart-029-flutter-design-tokens` | **Date**: 2026-07-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-029-flutter-design-tokens/spec.md`

## Summary

Add a **pure Dart** `destiny2_ui_tokens` package documenting Matte Flap Ledger colors, spacing, radii, and **FlapBoard layout contracts**. Wire the Flutter Windows host to a **theme stub** built from those tokens so Material cards are square, flat, and surface-tinted — not seed-blue elevated cards. No full brand rewrite; no FlapRow widget suite.

## Technical Context

**Language/Version**: Dart SDK ^3.5 (workspace); Flutter for host theme only  
**Primary Dependencies**: Pure package: none; host: `destiny2_ui_tokens` + Flutter  
**Storage**: N/A  
**Testing**: `dart test packages/ui_tokens`; `flutter test` in `apps/windows_host` for theme  
**Target Platform**: Shared tokens (all shells later); theme stub on Flutter Windows  
**Project Type**: Pure design-tokens library + host theme wiring (P3)  
**Performance Goals**: Trivial constants; suite &lt; 10s  
**Constraints**: No Flutter in pure package; no full UI rewrite; no CLIENT_SECRET; soft never auto-applies  
**Scale/Scope**: One new package + host theme file + app wire + tests + docs

## Constitution Check

- I. Small Testable Increments: US1 tokens, US2 layout contracts, US3 theme stub.
- II. Test-First: co-land tests; green before merge.
- III. Green Commit Checkpoints: `dart test packages/ui_tokens` + host theme test.
- IV-V. Co-located tests under package/app `test/`.

## Project Structure

### Documentation (this feature)

```text
specs/dart-029-flutter-design-tokens/
├── plan.md
├── research.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code

```text
packages/ui_tokens/
  pubspec.yaml
  README.md
  lib/
    destiny2_ui_tokens.dart
    src/
      colors.dart           # dark + light + elements ARGB
      spacing.dart
      radii.dart
      typography.dart       # family names + metrics
      flap_board_layout.dart
  test/
    ui_tokens_test.dart

apps/windows_host/
  pubspec.yaml              # + destiny2_ui_tokens
  lib/
    theme/
      flap_theme.dart       # buildFlapTheme()
    app.dart                # use flap theme
  test/
    flap_theme_test.dart
```

## Implementation approach

1. Create pure package + workspace membership; export barrel.
2. Port DESIGN.md / globals.css dark values to ARGB ints; light palette constants; spacing; radii 0; typography metrics.
3. Define FlapBoard layout contracts (rail 320, gap 0, column templates for sets/synergy/builds).
4. Document in package README (tokens table + anti-rules + how hosts map).
5. Implement `buildFlapTheme()` in windows_host; apply in `Destiny2WindowsApp`.
6. Tests for tokens + theme card defaults; run suites.
7. Update packages/README + roadmap on finish-spec merge.

## Structure Decision

Tokens live in **`packages/ui_tokens`** (pure). Theme factory lives in **`apps/windows_host`** (Flutter). Do not put Flutter ThemeData in the pure package. Do not implement FlapRow widgets here.

## Complexity Tracking

> No constitution violations requiring justification.
