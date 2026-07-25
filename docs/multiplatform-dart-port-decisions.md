# Multiplatform Dart port — architecture decisions

**Status:** decided (exploration follow-up)  
**Updated:** 2026-07-25  
**Source:** workflow `explore-flutter-port` + product follow-up answers  
**Related report:** session scratch `flutter-port-exploration.md` (run `explore-flutter-port`)  
**Branching / worktrees:** [`multiplatform-dart-branching.md`](./multiplatform-dart-branching.md) — **all** Spec Kit work for this port lives on `feature/multiplatform-dart` (+ child feature branches), in the dedicated worktree — not on product slices (e.g. `043-*`).  
**Slice roadmap (all phases, small Spec Kit slices):** [`multiplatform-dart-slice-roadmap.md`](./multiplatform-dart-slice-roadmap.md) — IDs **`DART-001`…** (parallel workstream; not product `0NN`)  
**Feature gaps vs Next (planned work):** [`multiplatform-dart-feature-gaps.md`](./multiplatform-dart-feature-gaps.md) — GAP-* → DART-050+

This note freezes port *architecture* choices. It does **not** change live product domain rules (DBR/DAC/BR). Next.js remains production until explicit cutover gates pass.

## Target platforms

| Platform | UI shell |
| -------- | -------- |
| Web | **Jaspr** (Dart) |
| Windows desktop | **Flutter** |
| Android | **Flutter** |
| iOS | **Flutter** |

Shared pure-Dart packages own domain/data contracts. UI is **not** one shared widget tree (Jaspr DOM/CSS vs Flutter widgets). Share tokens, layout contracts, and in-process use cases only.

## Strategic path

**Extract pure domain first, then grow shells** (not big-bang rewrite; not permanent Node sidecar).

1. Pure Dart domain + optimizer with parity tests against existing vitest / DBR-GUID hard-vs-soft rules.
2. Drift/data + manifest adapters (pure Dart I/O).
3. First user-visible shell: **Flutter Windows**.
4. Flutter mobile (reduced density).
5. Jaspr web + cutover gates; retire Next domain routes when parity is proven.

## Locked decisions

| ID | Topic | Decision |
| -- | ----- | -------- |
| D-PATH | Migration shape | Incremental monorepo: pure domain → data/manifest → Flutter Windows → mobile → Jaspr |
| D-SHELL-1 | First shell after domain | **Windows Flutter** |
| D-IO | Sidecar / dual runtime | **Pure Dart I/O only** — no temporary Node/Next host for DB, domain, or Bungie token exchange in new shells. Next.js stays the *current* product binary until cutover; it is not a runtime dependency of Dart shells. |
| D-WEB-DB (Q1) | Jaspr SQLite | **1a — Drift + sqlite WASM + OPFS**, with an explicit **single-tab writer** policy (other tabs read-only or blocked with UX). No local helper process for DB. Prefer **prebuilt entity bundles** on web; full raw manifest rebuild is a desktop (Windows) concern first. |
| D-WEB-AUTH | Jaspr vs confidential cookies | **Public + PKCE** on pure clients. Do **not** pursue confidential + iron-session cookie parity via a local BFF/helper for Jaspr. Do **not** embed `BUNGIE_CLIENT_SECRET` or `SESSION_SECRET` in Flutter/Jaspr. |
| D-BUNGIE (Q2) | Bungie application layout | **Hybrid** (see below). |
| D-NOT-FLUTTER-WEB | Web stack | Prefer Jaspr for web; **not** Flutter Web as the product web target. |

### D-BUNGIE hybrid detail

- **Dart shells (Flutter Windows/Android/iOS + Jaspr):** OAuth type **Public + PKCE** (S256). Tokens in platform secure storage (not plaintext prefs; not shipping refresh tokens in SQLite).
- **Legacy Next (until cutover):** keep existing **Confidential** app + httpOnly session cookies. Secrets stay server-only.
- **Dev:** one Public application with a **multi-redirect matrix** (loopback / debug schemes per platform) is fine while Windows is the only shell.
- **Prod:** start with one Public app + production redirects; **split** (e.g. mobile vs desktop/web, or per store) when redirect/ops/store-review pain warrants it — not required on day one.
- Document platform → exact `redirect_uri` → Bungie app name the same way README documents `https://127.0.0.1:3000/api/auth/callback` today.

## Implications by phase

| Phase | Implication of these decisions |
| ----- | ------------------------------ |
| 0 Domain | Zero IO/UI deps in domain packages; port hard/soft evaluators + golden tests first. |
| 1 Data | Drift schema mirrors `src/lib/db`; Flutter Windows uses native SQLite; app-support path (not repo `.cache` CWD). |
| 2 Auth | New Public+PKCE Bungie app; Windows loopback/deep-link first; no client secret in binary. |
| 3–4 Compose/equip | In-process use cases on Flutter hosts; optimizer off UI isolate on mobile. |
| 5 Jaspr | Same Drift schema package via WASM/OPFS; single-writer UX; Public+PKCE; prebuilt entities; legacy `app.db` import path: DART-048 (desktop dry-run/apply → StorageRoot; see `docs/multiplatform-dart-legacy-db-import.md`). |

## Still open (not decided here)

- When Next.js stops being production host — **criteria documented** in [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md) (DART-049). As of 2026-07-25: `PRODUCTION_CUTOVER: NO-GO` until residual blockers / `RC-*` pass; `PROGRAM_GATE: GO`.
- Entity-cache / raw-manifest tree copy from Next `.cache` (DART-048 covers `app.db` only; re-refresh on Windows).
- ~~Prebuilt entity bundle distribution channel~~ — **decided (DART-059):** **hybrid** (ship-in-app primary + optional CDN); see [multiplatform-dart-entity-bundle-channel.md](./multiplatform-dart-entity-bundle-channel.md). RB-05 cleared / RC-WEB-DATA PASS.
- Accessibility WCAG target (still open in PRODUCT.md) and whether mobile raises the bar before web cutover.

## Explicit non-goals for early port slices

- `/debug/*` and gap-scan operator surfaces as first-class Dart nav.
- Multi-pass LLM generator / Analyze as primary spine.
- dim.gg share and full DIM product parity.
- Re-cloning the full Next `/api` tree as the multiplatform contract.
- Cloud multi-tenant / Edge multi-worker SQLite.
- Local Node/Dart helper solely for web DB or confidential cookie parity.

## Preserve from product domain

- Soft suggestions never auto-apply; hard blocks only where the game/system is hard.
- Local-first single-writer SQLite semantics (web multi-tab must not invent multi-worker writers).
- Builds/sets/synergies private per user.
- Equip/DIM require owned instance pins where domain says so.

Domain truth remains `specs/domain-business-rules.md`, `specs/domain-acceptance-criteria.md`, and `specs/business-rules.md`.
