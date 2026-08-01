# Research: DART-040 Flutter Mobile Shell Nav

**Date**: 2026-07-25  
**Branch**: `dart-040-flutter-mobile-shell-nav`

## Decisions

### R1 — Separate app package (`apps/mobile_host`) vs multi-platform windows_host

**Decision**: New Flutter app `apps/mobile_host` (android+ios), not enabling mobile targets on `windows_host`.

**Rationale**: Windows host is dense dual-pane / NavigationRail. Mobile needs bottom nav + Focus Swap routes and reduced surfaces. Separate package keeps platform entrypoints, bootstrap, and density choices clean (aligned with D-SHELL / mobile reduced-density roadmap).

### R2 — Focus Swap implementation

**Decision**: Nested `Navigator` under the Builds tab. List is the root route; detail is pushed. Bottom `NavigationBar` switches top-level IndexedStack/tabs so Builds stack state can be preserved or reset on tab change (reset detail when leaving Builds is acceptable).

**Rationale**: Matches DESIGN.md Focus Swap Rule (library XOR detail on narrow). Avoids dual-pane Row layout from Windows.

### R3 — Shared use cases only (no duplicated domain)

**Decision**: Call `destiny2_app` `listUserBuilds` / `getBuildDetail` / `ensureUser` + `destiny2_db` for local library user. No reimplementation of build rules.

### R4 — Auth on mobile

**Decision**: Defer mobile OAuth. Use offline `local-library` membership (same as Windows signed-out path). Settings shows storage + manifest status only.

**Rationale**: Slice exit is shell + Settings + Build list; OAuth deep links are not in exit criteria and would expand scope.

### R5 — Manifest status

**Decision**: Host holds injectable `ManifestRefreshApi`. Production can use a lightweight status reader; tests inject fakes. Full Windows-style isolate rebuild not required.

### R6 — Installable builds evidence

**Decision**: On Windows port machine: `flutter build apk --debug`. Ship `ios/` from `flutter create` for macOS later. Document A7.

## Alternatives considered

- Single multi-platform app with adaptive layout — rejected for this slice (would couple desktop density to mobile nav).
- Full compose on mobile — deferred to DART-041.
