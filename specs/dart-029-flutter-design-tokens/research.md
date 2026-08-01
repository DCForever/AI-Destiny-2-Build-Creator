# Research: DART-029 Flutter Design Tokens

**Date**: 2026-07-24  
**Branch**: `dart-029-flutter-design-tokens`

## Decision 1 — Pure Dart package vs Flutter-only theme file

**Decision**: New workspace package `packages/ui_tokens` (`destiny2_ui_tokens`) with **SDK-only** runtime deps.

**Rationale**: Port decisions: “Share tokens, layout contracts, and in-process use cases only” — not one shared widget tree. Jaspr (DART-042) needs the same hex/spacing without Flutter. Pure package keeps graph clean.

**Rejected**: Tokens only inside `apps/windows_host` (blocks Jaspr reuse). Flutter ThemeExtension package as sole source (couples to Flutter).

## Decision 2 — Color representation

**Decision**: ARGB `int` constants (`0xFF050608`) for colors; hosts map to `Color(int)` or CSS `#rrggbb`.

**Rationale**: No Flutter in pure package; ints are portable and testable.

## Decision 3 — FlapBoard contracts without widgets

**Decision**: Constants for rail width (320), row gap (0), radius (0), and CSS-grid-style column template strings plus cell role labels. No `FlapRow` widget in this slice.

**Rationale**: Exit criteria say “layout contracts,” not full UI library. DART-030+ consumes contracts when building Sets library.

## Decision 4 — Material Card defaults

**Decision**: Keep existing `Card(...)` widgets; override via `ThemeData.cardTheme` (elevation 0, `RoundedRectangleBorder` radius 0, surface color). Replace `ColorScheme.fromSeed` blue with explicit ColorScheme from tokens.

**Rationale**: “No full brand rewrite” — do not redesign every Settings card into FlapRow boards here.

## Decision 5 — Typography / fonts

**Decision**: Export family name strings + size/weight metrics only; do not bundle font files in this slice.

**Rationale**: Font packaging is polish; metrics document the board grammar. System fallbacks acceptable for stub.

## Sources

- [DESIGN.md](../../DESIGN.md) Matte Flap Ledger
- [src/app/globals.css](../../src/app/globals.css) dark CSS variables
- [src/components/ui/README.md](../../src/components/ui/README.md) FlapBoard composition notes
- [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) shell split / shared tokens
