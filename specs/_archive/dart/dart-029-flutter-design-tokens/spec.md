# Feature Specification: DART-029 Flutter Design Tokens

**Feature Branch**: `dart-029-flutter-design-tokens`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Shared design tokens + FlapBoard layout contracts (no full brand rewrite). Documented tokens; Windows theme stub without Material-card default."

**Program ID**: DART-029  
**Phase**: P3  
**Depends**: DART-019 (Flutter Windows host skeleton)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Product design source**: [DESIGN.md](../../DESIGN.md) (Matte Flap Ledger)

## Scope boundary

**In scope:**

- Shared **pure Dart** design token package (`packages/ui_tokens` / `destiny2_ui_tokens`) with Matte Flap Ledger colors, spacing, radii, typography metrics, and element ink — **no Flutter/Jaspr widget tree**
- **FlapBoard layout contracts** as documented constants (rail width, row gap, board not cards, square radius, named column templates for Sets / Synergy / Build libraries)
- Package **README documentation** of tokens + layout contracts for Flutter Windows and future Jaspr CSS mapping
- **Windows host theme stub**: `ThemeData` built from tokens so default Material cards are square, elevation-0, matte surfaces (not rounded elevated Material cards)
- Wire `Destiny2WindowsApp` (and bootstrap error app if convenient) to the token theme
- Unit tests: token ARGB values match DESIGN.md hexes; layout contract constants stable; Flutter theme asserts card/shape defaults

**Out of scope (later slices):**

- Full brand rewrite of every Settings/Catalog widget to FlapRow boards (DART-030+)
- Complete FlapRow / FlapBoard Flutter widget library (layout contracts only here)
- Shipping custom font binaries (Barlow Condensed / IBM Plex) — metrics + family name strings only; system fallbacks OK
- Light theme preference UI / ThemeToggle (tokens may expose light palette constants for later)
- Jaspr CSS token file (DART-042)
- Compose UI (Sets/Synergy/Build identity) — DART-030–034
- Soft guidance auto-apply (forbidden); hard DBR UI
- Node sidecar / CLIENT_SECRET

### Assumptions

- **A1**: Token package is **pure Dart** (SDK only at runtime) so Jaspr can map the same hex/spacing later without depending on Flutter.
- **A2**: Existing `Card` widgets in Settings may remain; theme `cardTheme` MUST strip Material defaults (radius 0, elevation 0, surface color from tokens) — “without Material-card default.”
- **A3**: Dark Matte Flap Ledger is the **default** Windows theme for this slice (matches product dark default).
- **A4**: FlapBoard “layout contracts” are constants + docs, not a full widget suite. Named column templates are string specs hosts can apply to CSS grid or Flutter `Table`/`Row` later.
- **A5**: No full brand rewrite — NavigationRail / Catalog stay functional; chrome tinted by theme only.
- **A6**: Soft suggestions never auto-apply; no product domain behavior changes.
- **A7**: Pure Dart I/O only in packages; no CLIENT_SECRET.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Documented shared tokens (Priority: P1)

As a multiplatform developer, I can import shared Matte Flap Ledger color/spacing/radius tokens from a pure package and match DESIGN.md values in tests.

**Why this priority**: Exit criterion — “Documented tokens.”

**Independent Test**: `dart test packages/ui_tokens` asserts key ARGB hexes (void, surface, accent, danger, element-arc, …) and spacing/radius constants.

**Acceptance Scenarios**:

1. **Given** `destiny2_ui_tokens`, **When** I read dark palette constants, **Then** background is `#050608`, surface `#0c0e12`, accent `#e6b35c`, danger `#e2654f`.
2. **Given** the package, **When** I read radius, **Then** flap/container radius is `0` (square board rule).
3. **Given** the package README, **When** a contributor opens it, **Then** tokens and anti-rules (no steel, board not cards) are documented.

---

### User Story 2 - FlapBoard layout contracts (Priority: P1)

As a Windows compose UI implementer (DART-030+), I can rely on stable FlapBoard layout contracts (rail width, zero row gap, column templates) without inventing ad-hoc denseness.

**Why this priority**: Exit criterion — “FlapBoard layout contracts.”

**Independent Test**: Unit tests assert `kFlapLibraryRailWidth == 320`, row gap `0`, and named column template strings are non-empty and documented.

**Acceptance Scenarios**:

1. **Given** layout contracts, **When** I read library rail width, **Then** it is `320` logical pixels (DESIGN Workspace rail preference).
2. **Given** FlapBoard contracts, **When** I read row gap, **Then** it is `0` (board not cards — continuous ruled rows).
3. **Given** column templates for sets/synergy/builds, **When** tests run, **Then** each template is present and lists expected cell roles in package docs.

---

### User Story 3 - Windows theme stub without Material-card default (Priority: P1)

As a Windows user, the host shell uses a Matte Flap Ledger-tinted `ThemeData` where Material `Card` defaults are square, flat (no elevation), and surface-colored — not rounded elevated Material cards.

**Why this priority**: Exit criterion — “Windows theme stub without Material-card default.”

**Independent Test**: Widget/unit test pumps `buildFlapTheme()` (or app under theme) and asserts `cardTheme.elevation == 0`, shape radius `0`, and scaffold/background colors from tokens.

**Acceptance Scenarios**:

1. **Given** the Windows host theme stub, **When** `ThemeData` is built, **Then** `cardTheme.elevation` is `0` and shape uses zero border radius.
2. **Given** the theme, **When** scaffold background is resolved, **Then** it matches token void/background (`#050608` dark).
3. **Given** `Destiny2WindowsApp`, **When** it builds `MaterialApp`, **Then** it uses the flap theme (not `ColorScheme.fromSeed` blue seed).
4. **Given** Settings `Card` widgets, **When** rendered under the theme, **Then** they inherit square flat card theme without per-widget rewrite of all surfaces.

---

### Edge Cases

- Light palette constants exist for documentation/future ThemeToggle but are not required as the live Windows default in this slice.
- Missing custom fonts: theme uses family name strings with system sans fallbacks; no crash.
- Pure package must not import `package:flutter/*`.
- Soft guidance never auto-applies; no domain package changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repo MUST include package `packages/ui_tokens` (`destiny2_ui_tokens`) with pure Dart tokens (no Flutter/Jaspr runtime deps).
- **FR-002**: Package MUST expose dark Matte Flap Ledger neutrals, accent/status lamps, and Destiny element ink as ARGB ints (or equivalent) matching DESIGN.md / `globals.css` dark values.
- **FR-003**: Package MUST expose spacing scale and **radius 0** for flap/containers.
- **FR-004**: Package MUST expose FlapBoard layout contracts: library rail width `320`, flap row gap `0`, and named column templates for Sets, Synergy, and Build library boards.
- **FR-005**: Package MUST document tokens + layout contracts + design anti-rules in `packages/ui_tokens/README.md` (or package doc entry).
- **FR-006**: Windows host MUST provide a theme stub builder that produces `ThemeData` from tokens with `useMaterial3: true` (or equivalent) and **cardTheme** without Material elevated/rounded defaults (elevation 0, square shape, surface color).
- **FR-007**: `Destiny2WindowsApp` MUST apply the flap theme stub (replace seed-blue `ColorScheme.fromSeed` default).
- **FR-008**: Package MUST be listed in workspace `pubspec.yaml` `workspace:`; host may depend on it.
- **FR-009**: Tests MUST cover token values, layout contracts, and theme card defaults.
- **FR-010**: Soft suggestions MUST NOT auto-apply; no CLIENT_SECRET; pure domain packages unchanged.

### Key Entities

- **FlapColorTokens** — void/surface/line/foreground/accent/status/element ARGB
- **FlapSpacing** — density scale (2…24, panel/page paddings)
- **FlapRadii** — all-zero square board radii
- **FlapBoardLayout** — rail width, gaps, column template strings + cell role labels
- **buildFlapTheme()** — Windows host ThemeData factory

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/ui_tokens` green; documented tokens match DESIGN.md hexes under test.
- **SC-002**: Windows host theme test asserts non-default Material card (elevation 0, radius 0) and void background.
- **SC-003**: Specs under `specs/dart-029-flutter-design-tokens/`; branch merges to `feature/multiplatform-dart` only.
- **SC-004**: Roadmap DART-029 → done; Current pointer → DART-030.

## Assumptions

See scope Assumptions A1–A7.
