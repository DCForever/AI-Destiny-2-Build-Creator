# Feature Specification: DART-042 Jaspr App Skeleton

**Feature Branch**: `dart-042-jaspr-app-skeleton`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Jaspr app shell + routing + design tokens (CSS). Hello Settings page; no Next dependency."

**Program ID**: DART-042  
**Phase**: P5  
**Depends**: DART-011 (domain parity gate), DART-013 (Drift schema — available for later OPFS slices; not required at runtime in this skeleton)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Create a **Jaspr client-mode** web application shell under `apps/web_host` (first user-visible Jaspr host)
- **App shell** layout: chrome header/nav + page content region (not full product compose)
- **Client-side routing** via `jaspr_router` with at least Settings route reachable and titleable
- **Design tokens as CSS**: map Matte Flap Ledger tokens from pure package `destiny2_ui_tokens` (DART-029) into CSS custom properties / global styles used by the shell
- **Hello Settings page**: minimal Settings surface showing a clear “Hello” / Settings stub (no OAuth, no DB, no OPFS)
- Wire app into monorepo workspace (`pubspec.yaml` workspace + packages README notes)
- Automated tests for token CSS mapping and Settings page content
- Document how to serve (`jaspr serve`) without any Next.js process

**Out of scope (later slices):**

- Drift WASM + OPFS + single-tab writer (DART-043)
- Prebuilt entity bundles / catalog on web (DART-044)
- Browser Public+PKCE OAuth (DART-045)
- Compose spine UI (DART-046)
- Equip / DIM on web (DART-047)
- Legacy DB import (DART-048)
- Flutter Web as product target (explicit non-goal — D-NOT-FLUTTER-WEB)
- Node sidecar, CLIENT_SECRET in clients, Next as runtime dependency of the Jaspr host
- Soft guidance auto-apply (forbidden)

### Assumptions

- **A1**: Package name `destiny2_web_host` under `apps/web_host/` (Jaspr scaffold may leave short name `web_host`; rename to `destiny2_web_host` for monorepo consistency with other hosts).
- **A2**: **Client mode** Jaspr (SPA) + **single-page (client-side) routing** — no SSR/static pre-render required for Hello Settings exit criteria; later slices may revisit mode if OPFS/SSR needs differ.
- **A3**: No SQLite/OPFS open in this slice — Settings is a static Hello stub (parity with “thin skeleton before data” pattern of DART-019, but without DB until DART-043).
- **A4**: Design tokens CSS is generated/derived from `destiny2_ui_tokens` ARGB/spacing constants (via `argbToCssHex` or equivalent), not a hand-copied one-off palette that can drift from Flutter tokens.
- **A5**: Default route is Settings (Hello Settings) at `/` or `/settings` with shell nav; secondary route optional for routing smoke only.
- **A6**: Soft guidance never auto-applies; no hard DBR UI in this slice.
- **A7**: Pure Dart I/O only; no `CLIENT_SECRET`; no Next.js import/dependency from the Jaspr package.
- **A8**: `jaspr_test` + `package:test` for component/unit tests; full browser E2E not required for exit.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Jaspr shell launches with routing (Priority: P1)

As a web developer, I can run the Jaspr web host and see an app shell with client-side routing that loads a Settings page without starting Next.js.

**Why this priority**: Roadmap exit — “Jaspr app shell + routing”; “no Next dependency.”

**Independent Test**: Package has `jaspr: mode: client`; `pubspec` has no next/node deps; router exposes Settings route; component test pumps shell and finds Settings content.

**Acceptance Scenarios**:

1. **Given** the monorepo, **When** I inspect `apps/web_host/pubspec.yaml`, **Then** it depends on Jaspr packages and path `destiny2_ui_tokens` only among product packages — not Next, not Node.
2. **Given** the app, **When** the router builds routes, **Then** a Settings route exists and is the default landing (or is linked as primary from `/`).
3. **Given** shell chrome, **When** Settings is active, **Then** header/nav indicates Settings without OAuth controls.

---

### User Story 2 - Hello Settings page (Priority: P1)

As a user opening the web host, I land on a Settings-oriented page that clearly greets (“Hello”) and identifies itself as Settings.

**Why this priority**: Roadmap exit — “Hello Settings page.”

**Independent Test**: `jaspr_test` pumps Settings page (or App at Settings route) and asserts Hello + Settings text.

**Acceptance Scenarios**:

1. **Given** Settings page, **When** rendered, **Then** visible text includes “Settings” and “Hello” (or “Hello Settings”).
2. **Given** Settings page, **When** user looks for sign-in / OAuth / CLIENT_SECRET, **Then** none are present.
3. **Given** Settings page, **When** rendered, **Then** it does not require Drift/OPFS bootstrap (no crash if DB absent).

---

### User Story 3 - Design tokens as CSS (Priority: P1)

As a multiplatform developer, the Jaspr shell applies Matte Flap Ledger design tokens as CSS (custom properties and/or global styles) sourced from `destiny2_ui_tokens`, matching dark palette hexes used by Flutter hosts.

**Why this priority**: Roadmap goal — “design tokens (CSS).”

**Independent Test**: Unit test asserts CSS variable map / generated rules include background `#050608`, surface `#0c0e12`, accent `#e6b35c`, radius `0`.

**Acceptance Scenarios**:

1. **Given** token CSS mapping, **When** dark background is read, **Then** it is `#050608`.
2. **Given** token CSS mapping, **When** accent is read, **Then** it is `#e6b35c`.
3. **Given** global shell styles, **When** applied, **Then** body/background uses flap void and radii stay square (`0`) per board rule.
4. **Given** `destiny2_ui_tokens`, **When** Jaspr maps colors, **Then** it uses shared package helpers (e.g. `argbToCssHex`) rather than inventing a divergent palette.

---

### Edge Cases

- Unknown route → router falls through without crashing the shell (default empty/not-found handling acceptable for skeleton).
- CSS tokens missing a light palette is OK (dark default only, matching DART-029 Windows stub).
- Soft guidance never auto-applies.
- Multi-tab OPFS writer: out of scope until DART-043.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Host MUST be a Jaspr app under `apps/web_host` with `jaspr.mode: client` (or documented equivalent client SPA).
- **FR-002**: Host MUST use `jaspr_router` for client-side routing including a Settings route.
- **FR-003**: Host MUST render a Hello Settings page as the primary landing experience.
- **FR-004**: Host MUST map Matte Flap design tokens from `destiny2_ui_tokens` into CSS used by the shell.
- **FR-005**: Host MUST NOT depend on Next.js, Node sidecars, or embed `CLIENT_SECRET`.
- **FR-006**: Host MUST NOT open Drift/OPFS or implement OAuth in this slice.
- **FR-007**: Soft guidance never auto-applies.
- **FR-008**: Automated tests MUST cover Settings Hello content and token CSS hex mapping.
- **FR-009**: Workspace root MUST list `apps/web_host` as a workspace member.

### Key Entities

- **WebHost App / Shell**: Root Jaspr component + Router + header chrome.
- **Settings page**: Hello Settings stub surface.
- **Flap tokens CSS**: CSS custom property set derived from pure UI tokens.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test` (web_host package) passes Settings + token CSS tests.
- **SC-002**: Package resolves via workspace `dart pub get` without Next dependencies.
- **SC-003**: Dev can `jaspr serve` from `apps/web_host` and load Hello Settings (manual smoke; documented in README/quickstart).
- **SC-004**: No CLIENT_SECRET and no Next runtime dependency in the Jaspr host package.

## Assumptions

See A1–A8 above. Defaults chosen to avoid NEEDS CLARIFICATION while matching roadmap exit criteria and locked web decisions (Jaspr, not Flutter Web; pure Dart I/O; Public+PKCE later).
