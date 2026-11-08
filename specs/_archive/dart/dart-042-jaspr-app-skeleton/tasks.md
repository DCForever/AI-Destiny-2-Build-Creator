# Tasks: DART-042 Jaspr App Skeleton

**Input**: Design documents from `/specs/dart-042-jaspr-app-skeleton/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: `dart test` in `apps/web_host` (token CSS + Settings). No live Bungie. No CLIENT_SECRET. No Next.

## Phase 1: Setup

- [x] T001 Create `specs/dart-042-jaspr-app-skeleton/` docs + set `.specify/feature.json`
- [x] T002 Scaffold/adapt `apps/web_host` Jaspr client SPA; rename package to `destiny2_web_host`; document independent pub get (not root workspace — Jaspr/Flutter meta pin)
- [x] T003 Depend on path `destiny2_ui_tokens`; strip demo counter/about noise

---

## Phase 2: Design tokens CSS (US3)

**Goal**: CSS custom properties from pure tokens  
**Independent Test**: `flap_tokens_css_test.dart`

- [x] T004 Implement `lib/theme/flap_tokens_css.dart` mapping dark palette + radii/spacing
- [x] T005 Wire global `lib/theme/theme.dart` `@css` using flap tokens (void background, square radius)
- [x] T006 Write `test/flap_tokens_css_test.dart` (hexes `#050608`, `#0c0e12`, `#e6b35c`, radius 0)

---

## Phase 3: Shell + routing + Hello Settings (US1–US2) 🎯 MVP

**Goal**: App shell, router, Hello Settings page  
**Independent Test**: `settings_page_test.dart`

- [x] T007 Implement `lib/pages/settings_page.dart` (Hello Settings)
- [x] T008 Implement `lib/components/shell_header.dart` + `lib/app.dart` Router (Settings primary)
- [x] T009 Update `lib/main.client.dart` / `web/index.html` titles
- [x] T010 Write Settings/shell tests asserting Hello + Settings; assert no Next package dep in pubspec
- [x] T011 Update `apps/web_host/README.md` + packages/README layout note

**Checkpoint**: `dart test` in web_host green

---

## Phase 4: Polish & finish

- [x] T012 Mark tasks complete; commit remaining work
- [x] T013 Merge into `feature/multiplatform-dart` (--no-edit); update roadmap DART-042 done, pointer → DART-043; commit base

---

## Dependencies & Execution Order

- Setup → Tokens CSS → Shell/Settings → Finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Spec docs + feature.json  
2. Host package + ui_tokens CSS  
3. Shell/router/Settings + tests  
4. Merge + roadmap pointer (next: DART-043 jaspr-opfs-sqlite)
