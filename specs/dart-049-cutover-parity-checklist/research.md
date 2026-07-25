# Research: DART-049 Cutover Parity Checklist

**Date**: 2026-07-25

## Decisions

### R1 — Dual gate (program vs production cutover)

**Decision**: Separate **PROGRAM_GATE** (DART workstream / P5 complete) from **PRODUCTION_CUTOVER** (Next no longer production host).

**Rationale**: Port decisions left “when Next stops being production host” open. Finishing planned slices is not the same as flipping production traffic. A single GO would either block the program forever on residual polish or falsely green-light cutover.

**Rejected**: One combined verdict — collapses documentation completion with release risk.

### R2 — Production nav source = AppShell NAV_LINKS

**Decision**: Canonical product production nav is `src/components/AppShell.tsx` `NAV_LINKS`: loadouts, build, synergy, sets, catalog, settings.

**Rationale**: PRODUCT.md and AppShell agree that these are primary surfaces; `/debug/*` is operator tooling (404 in production); `/analyze` is adjacent/legacy and not in AppShell.

**Rejected**: Parity against every `src/app/**` folder — would force non-goals into the gate.

### R3 — Host matrix includes reduced mobile density

**Decision**: Mobile may ship Builds + Settings only; missing Sets/Synergy/Catalog top-level nav on mobile is **not** an automatic production-cutover blocker for **web** Next retirement.

**Rationale**: Roadmap P4 intentionally reduced mobile compose; web cutover target is Jaspr + desktop Flutter, not phone-first full dual-pane.

### R4 — Checklist is the product of this slice (docs + validator)

**Decision**: Deliverable is `docs/multiplatform-dart-cutover-parity-checklist.md` plus a small Dart test that asserts required headings/markers. No new UI.

**Rationale**: Exit criteria are written checklist + go/no-go + P5 gate — not another shell feature.

### R5 — Initial PRODUCTION_CUTOVER = NO-GO with residual list

**Decision**: Author residual blockers honestly (e.g. In-Game Loadouts surface, web inventory-owned polish, dual-run ops checklist, prod Public app redirects) and set PRODUCTION_CUTOVER to **NO-GO** until `RC-*` pass.

**Rationale**: Spec success does not require lying about readiness. PROGRAM_GATE can still be **GO**.

### R6 — Retirement criteria freeze open architecture questions as pass conditions

**Decision**: Map open items from `multiplatform-dart-port-decisions.md` into `RC-*` where they affect cutover (Next host retirement, entity bundle distribution, accessibility open item stays non-blocking unless product locks WCAG).

**Rationale**: Closes the “still open” Next retirement question with an actionable list without inventing new architecture.

## Product nav inventory (evidence)

| Key | Path | Label |
| --- | ---- | ----- |
| loadouts | `/loadouts` | In-Game Loadouts |
| build | `/build` | Build |
| synergy | `/synergy` | Synergy |
| sets | `/sets` | Sets |
| catalog | `/catalog` | Catalog |
| settings | `/settings` | Settings |

## Dart shell nav inventory (evidence)

| Host | Nav |
| ---- | --- |
| Windows Flutter | Catalog, Sets, Synergies, Builds, Settings (rail) |
| Mobile Flutter | Builds, Settings (bottom nav) |
| Jaspr web | Catalog, Builds, Sets, Synergies, Settings (+ `/auth/callback`) |

## Open notes (not blocking this slice)

- Exact date of dual-run window and DNS/hosting cutover procedure is ops follow-on.
- Accessibility WCAG target remains open in PRODUCT.md — not a DART program gate.
