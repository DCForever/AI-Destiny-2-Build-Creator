# Implementation Plan: DART-055 In-Game Loadouts Surface

**Branch**: `dart-055-in-game-loadouts-surface` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-055-in-game-loadouts-surface/spec.md`

## Summary

Ship first-class **In-Game Loadouts** UI on Windows NavigationRail and Jaspr shell (`/loadouts`), backed by pure Dart parse of Bungie GetProfile component **206** (+ characters 200) with optional presentation table resolve — closing GAP-NAV-01 / RB-01 and advancing RC-NAV.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_bungie`, Flutter Windows host, Jaspr web host, `destiny2_manifest` raw tables (Loadout* already in `downloadRawTables`)

**Storage**: No new Drift tables; loadouts are live profile reads (not persisted this slice)

**Testing**: `dart test packages/bungie`; `flutter test` windows_host loadouts/nav; `dart test` web_host shell/loadouts; cutover validator

**Target Platform**: Windows Flutter (primary), Jaspr web (route parity)

**Project Type**: Monorepo multiplatform port slice

**Performance Goals**: Single profile GET for 200+206; UI list <100 rows typical

**Constraints**: Pure Dart I/O; no CLIENT_SECRET; soft never auto-applies; no Node sidecar

**Scale/Scope**: One nav destination + one page per host; pure parse module

## Constitution Check

- I. Small Testable Increments: pure parse → profile client → Windows UI → Jaspr → docs
- II. Test-First: parse tests + host nav tests before/with implementation
- III. Green Commit Checkpoints: after bungie package green; after Windows green; after web+docs
- IV-V. Co-located tests under packages/bungie/test and host test/

## Project Structure

### Documentation (this feature)

```text
specs/dart-055-in-game-loadouts-surface/
├── plan.md
├── research.md
├── quickstart.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/bungie/lib/src/profile/
  character_loadouts.dart          # parse + presentation
  bungie_profile_client.dart       # + getCharacterLoadoutsProfile
  profile_types.dart               # BungieInGameLoadout DTOs (or in character_loadouts)
packages/bungie/test/
  character_loadouts_test.dart
apps/windows_host/lib/
  app.dart                         # nav destination
  loadouts/
    loadouts_controller.dart
    loadouts_page.dart
    loadout_presentation_loader.dart  # optional raw-table load from StorageRoot
apps/windows_host/test/
  loadouts_page_test.dart
  shell_nav_loadouts_test.dart
apps/web_host/lib/
  components/shell_header.dart     # Loadouts link
  app.dart                         # /loadouts route
  loadouts/
    loadouts_controller.dart
    loadouts_page.dart
apps/web_host/test/
  shell_nav_compose_test.dart      # extend
  loadouts_page_test.dart
docs/
  multiplatform-dart-feature-gaps.md
  multiplatform-dart-cutover-parity-checklist.md
  multiplatform-dart-slice-roadmap.md
```

## Implementation approach

1. **Pure layer** — Port `characterLoadouts.ts` to Dart: `isEmptyLoadoutItems`, `resolveLoadoutPresentation`, `parseCharacterLoadoutsResponse`, `presentationTablesFromRaw`, `BungieInGameLoadout`, `LoadoutPresentationTables`.
2. **Profile client** — Add `kCharacterLoadoutsProfileComponents = '200,206'` and `getCharacterLoadoutsProfile` returning raw Response map (or typed wrapper). Convenience `fetchInGameLoadouts` that gets memberships + profile + characters parse + loadouts parse.
3. **Windows** — Controller: session token → profile client → optional presentation loader from StorageRoot raw tables → list. Page: filters, list tiles, refresh. App: insert Loadouts destination (before Settings).
4. **Jaspr** — ShellHeader + Router `/loadouts`; page with controller injectable for tests; thin presentation OK.
5. **Fakes** — Update all `BungieProfileClient` implementors with new method.
6. **Docs** — matrix PASS, RB-01 cleared, GAP closed, roadmap done.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
| --------- | ---------- | ------------------------------------ |
| Live profile (not Drift cache) | Product also fetches live; schema `loadouts` table is local generated builds | Persisting 206 would add migration + stale UX without extra value this slice |
