# Research: DART-042 Jaspr App Skeleton

**Date**: 2026-07-25  
**Branch**: `dart-042-jaspr-app-skeleton`

## Decisions

### R1 — Rendering mode: client SPA

| Option | Pros | Cons |
| ------ | ---- | ---- |
| Client | Simplest Hello Settings; static deploy later; matches thin skeleton | No SSR SEO (irrelevant for authenticated app shell) |
| Static SSG | Deployable HTML | Overkill for stub; build complexity |
| Server SSR | Dynamic | Needs Dart server host; not required for exit |

**Choice**: `jaspr.mode: client` + single-page routing.  
**Rationale**: Exit criteria is Hello Settings + routing + tokens. OPFS (DART-043) is browser-side; SSR not a prerequisite.

### R2 — Package location & naming

**Choice**: `apps/web_host` / pub name `destiny2_web_host`.  
**Rationale**: Mirrors `destiny2_windows_host` and `destiny2_mobile_host`. CLI scaffolded short name `web_host` — rename for consistency.

### R3 — Design tokens CSS strategy

**Choice**: Pure-Dart map of CSS custom properties derived from `destiny2_ui_tokens` (`argbToCssHex`, spacing, radii), applied via Jaspr `@css` global rules and/or `:root` variables.  
**Rationale**: Single source of truth with Flutter (DART-029); unit-testable without browser.

### R4 — Settings without DB

**Choice**: Static Hello Settings stub; no Drift/OPFS open.  
**Rationale**: Parallels progressive shell growth (DART-019 opened DB because Windows P1 needed it; web DB is DART-043). Keeps slice under ~25 tasks and exit-focused.

### R5 — Testing

**Choice**: `package:test` for token CSS map; `jaspr_test` for Settings/shell component tests if compatible with workspace SDK; fallback component-string assertions if jaspr_test wiring is heavy.  
**Rationale**: Constitution test-first for new behavior; skeleton must prove Hello Settings + token hexes.

## References

- [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) — D-WEB-DB, D-WEB-AUTH, D-NOT-FLUTTER-WEB
- [docs/multiplatform-dart-slice-roadmap.md](../../docs/multiplatform-dart-slice-roadmap.md) — DART-042 row
- Jaspr CLI 0.23.x / jaspr_router 0.8.x
- packages/ui_tokens (DART-029)
