# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Primary users are **endgame Destiny 2 players** who already know the sandbox and want a durable, equippable loadout identity—not a one-shot randomizer.

**Situation:** They juggle class-bound kits across activities, inventory rolls, artifact seasons, and variants of the same play pattern (e.g. several loadouts that all create Ionic Traces and Jolt).

**Job:** State **intent** (synergy types / play verbs), **compose** a Build from sets, synergies, and variants with soft guidance, then **equip** in-game or export (DIM) when the variant is owned-instance ready.

Secondary audience jobs (supporting, not primary): curate a reusable library of synergies and sets; browse catalog/owned inventory as composition aids; optional LLM-assisted discovery that proposes for confirmation.

## Product Purpose

**Destiny 2 Build Creator** is a **local-first** web app for assembling and maintaining Destiny 2 builds on the final **9.7.0 / Edge of Fate** sandbox model (Armor 3.0 stats, set bonuses, artifacts, etc.).

Primary success journey: **intent → compose → equip**.

Secondary success journey: **curate a reusable library** of sets and synergies so compose gets faster over time. Users may create synergies and sets **in-flow** during compose; a deep library is not a hard gate to start.

Success means a player can leave a session with a class-bound Build that has a stable identity, at least one coherent (default) combat loadout, clear soft guidance on gaps, and a path to equip or export when pins exist—not merely a pretty sheet of unvalidated names.

## Positioning

The distinctive mechanism is **synergy-type intent + set-based composition with variants and soft guidance**:

- Builds are created **intent-first** via designated **Synergy Types** (type + optional subType), bridged to curated Type+Object synergies for coverage—not free-text “build vibes” alone.
- **Sets** (Weapon / Armor / Mod / Pair / Fashion) are the normal composition path, with live attachments, slot overrides, and variants that preserve identity while swapping kits.
- **Soft guidance** (coverage, stats, required links on default variant) steers quality without turning every soft miss into a hard block on non-default variants.
- Inventory, catalog browse, armor optimization, Bungie equip, and DIM export are supporting capabilities for that compose→equip loop—not the product’s sole reason to exist.

Neighboring tools (DIM loadouts, LO, generic AI generators) can move gear or spit names; they do not center **designated play-pattern identity + reusable set library + variant-aware composition** the same way.

## Operating Context

- **Desktop-first browser** app (Next.js), typically `npm run dev` / local HTTPS for Bungie OAuth (`https://127.0.0.1:3000`).
- **Bungie API**: manifest refresh, OAuth sign-in, inventory sync, in-game equip / transfer.
- **SQLite** local DB (`.cache/app.db`) for inventory, builds, sets, synergies—single-process local use.
- Optional **local or remote LLM** (OpenAI-compatible / Ollama / Grok) for generation and propose-for-confirm synergy discovery; not required for core manual compose.
- Optional **DIM** export / dim.gg when configured.
- Production surfaces include Build, Sets, Catalog, Synergy, Loadouts, Analyze, Settings; **`/debug/*`** remains operator/service tooling, not primary nav.
- Domain truth lives in `specs/domain-business-rules.md` (`DBR-*`), `specs/domain-acceptance-criteria.md` (`DAC-*`), and feature BRs in `specs/business-rules.md`.

## Capabilities and Constraints

### Confirmed capabilities (product surfaces)

- **Build composer**: identity (synergies, optional exotic armor / shared exotic weapon / pinned Super), variants, set attachments, slot pins, soft stat targets, soft guidance, wishlist vs equip-ready pins.
- **Library**: Sets CRUD by type; Synergies with evidence links (required/evidence); concept tags as filter metadata (not identity).
- **Catalog**: multi-facet browse/filter as a composition aid for filling sets/slots.
- **Inventory**: Bungie sync of owned instances; instance-aware pickers and stale-pin handling.
- **Armor set optimizer**: constrained full-kit search, materialize/refresh constrained Armor Sets, soft improvement suggestions (suggest-then-confirm).
- **Equip / export**: Bungie equip path and DIM export for equip-ready variants; gaps leave character gear as-is after confirmation on non-default variants.
- **LLM**: optional generator and **manual propose-for-confirm** synergy/evidence pass—nothing becomes canonical without user confirmation.
- **Legacy/adjacent**: Analyze and older generator entry points may still exist; they are not the primary product job for new design work.

### Durable constraints (must preserve)

- **Local-first / single-process SQLite** — not a multi-tenant cloud product architecture; no Edge/serverless multi-worker assumption against one DB file.
- **Bungie OAuth + inventory sync** required for real owned-instance work and in-game equip.
- **Builds, sets, and synergies are private per user.** Shareable read-only links are planned, not required for the first equippable composer slice.
- Domain rules win on product behavior conflicts; pure UI polish stays out of domain P1/P2 gates unless it encodes semantics.
- Manifest-validated composition: illegal subclass kits, over-capacity mods, and >1 exotic weapon/armor hard-block save where domain says so.
- Soft suggestions (optimizer improvements, guidance) **never auto-apply**.

### Explicit non-goals (unless product direction changes)

- Full **DIM parity** (notes, ornaments, full transfer UI, etc.).
- Restoring **Generator / multi-pass LLM** as the primary nav tab.
- Deleting `/debug/*` power-user tools.
- Fabricating testimonials, competitive benchmarks, or cloud multi-user claims.

### Open product decisions

- Exact accessibility standard (e.g. WCAG target level) not yet product-specified.
- Shareable read-only build links: planned, scope/UX undecided.
- How far production nav should promote power tools (e.g. synergy gap-scan) beyond debug.

## Brand Commitments

- **Product name:** Destiny 2 Build Creator.
- **UI system name in-repo:** “Vault Terminal” (`src/components/ui`) — shared primitives (Panel, Workspace, chips, hotspots, etc.); production screens should compose these rather than one-off chrome.
- **Voice:** Operator / arsenal clarity—precise Destiny terminology (class, subclass, synergy type, set, variant, pin, equip-ready). Prefer plain status and coverage language over hype.
- **Visual world is not decided here.** Incumbent implementation exists (dark terminal-adjacent app shell, Chakra Petch + IBM Plex, Destiny iconography). Document or redesign via Impeccable `document` / design commands; do not invent a new brand system in this file.
- Binding external brand: Destiny 2 / Bungie game terminology and official-ish icon paths where the app already vendors or maps them; do not invent official Bungie marketing claims.

## Evidence on Hand

- Canonical domain: `specs/domain-business-rules.md`, `specs/domain-acceptance-criteria.md`, `specs/business-rules.md`.
- Feature slices: `specs/00N-*/` (through armor set optimizer and prior compose/equip work).
- Operator docs: `README.md`, `DEBUG.md`, `PLAN.md`, `docs/ui-polish-tracker.md`.
- UI primitives notes: `src/components/ui/README.md`.
- Runnable app with production routes under `src/app/` (build, sets, catalog, synergy, loadouts, analyze, settings) and debug under `src/app/debug/`.
- **Do not fabricate:** user testimonials, press, usage metrics, App Store listings, or multiplayer/social proof.

## Product Principles

1. **Compose-to-equip is the spine** — every primary surface should shorten intent → coherent loadout → owned pins → equip/export.
2. **Identity over inventory clutter** — designated synergies and explicit identity fields define “same build”; tags and rolls support filtering and equip, they don’t redefine the build by accident.
3. **Sets and library accelerate, never gate** — in-flow create stays valid; library depth is a readiness bar, not a wall.
4. **Hard only when the game is hard** — illegal kits, capacity, exotic slot rules, and equip-ready pins are firm; soft coverage and optimizer suggestions coach without silent mutation.
5. **Local trust and manifest truth** — player data stays local-first; names and plugs resolve against real Bungie manifest data before they look “done.”

## Accessibility & Inclusion

No product-specific accessibility standard was locked in init. Default expectation for future UI work: keyboard-reachable primary actions, visible focus, and text that doesn’t rely on color alone for critical save/equip blockers—formal WCAG target remains open.
