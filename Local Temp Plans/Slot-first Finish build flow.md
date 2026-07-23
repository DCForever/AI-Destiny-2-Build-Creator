# Slot-first Finish build flow
## Problem
Finish build / create-set UX is clunky: multi-control gates before filling slots. Goal: **inherit from build**, optional tags out of Finish, and for **Armor** after create: set **set-bonus goals + stat targets**, **run the existing 026 optimizer**, show **proposed full kits**, apply one — not piece-by-piece as the primary armor path.
## Current state (verified)
* Finish walkthrough: `FinishBuildWalkthrough.tsx` still mounts Create form + full SetAttachPicker before fill.
* One-tap create API exists: `POST .../create-set-attach` → `createSetAndAttach` (name `{build.name} Armor`, optional `tagIds`).
* Capture: `POST .../create-sets` / `createSetsFromBuild` seeds armor `optimizerConstraints` via `seedConstraintsFromBuild` (exotic + soft stats; **setBonusGoals empty**).
* Optimizer (026, production APIs already):
    * `POST /api/user/sets/[id]/optimize` → `optimizeFromSet` (body: `overrides?`, `maxResults?`) returns `combinations[]` (pieces, estimatedStats, setBonusSummary, assumedMods, score…).
    * `POST /api/user/sets/[id]/apply-combination` → apply kit **in place** on that Armor Set.
    * `POST /api/user/armor/optimize/materialize` → new set from combination (attachNow optional).
    * Freeform optimize also at `POST /api/user/armor/optimize` (debug-oriented).
* Constraint model: `ArmorSetOptimizerConstraints` in `src/lib/optimizer/types.ts` (`lockedExoticItemHash`, `setBonusGoals[{setBonusKey,minPieces:2|4}]`, `statPriorities`, `statThresholds`, `includeModEstimates`, `preferReuse`).
* Seed helper: `seedConstraintsFromBuild` (`src/lib/optimizer/seedConstraintsFromBuild.ts`).
* Persist constraints: `PATCH /api/user/sets/[id]` via `updateSetSchema.optimizerConstraints`.
* Production Sets UI has **no** optimizer chrome yet — only `/debug/sets` table UI.
* Weapons/Mods still gap-driven; slot fill via `SlotFillPanel` remains for non-armor (and armor fallback).
## Decisions (this iteration)
1. Finish hides link/tags/attach-mode; link stays on variant Sets tab.
2. **Weapons/Mods** (and armor fallback): one-tap create/capture → **slot-first fill loop**.
3. **Armor primary path** after Create (or after Capture when user wants better kit / empty goals):
    1. Create+attach empty Armor set (inherit name/type from build) **or** use Capture when claims exist.
    2. **Constraint + results UI (locked):** **V2 + V5 hybrid** on desktop/wide; **V6** as the phone/narrow adaptation.
    3. Persist constraints on the set, then **Run optimizer** (`POST .../sets/{id}/optimize`).
    4. **Results:** default to **top-3 compare** (V5: per-stat bars vs thresholds, Apply per column); escape hatch **See all N** as ranked list in the kits pane.
    5. User confirms → **Apply in place** (`apply-combination`) on the attached set (preferred; keeps attachment).
4. Manual per-slot fill remains secondary for Armor (optimizer empty / user opts out).
5. Concept tags not collected in Finish.
6. **Responsive armor chrome (locked):**
    * **Wide (≥ ~900px):** V2 split workspace — left **goals** (exotic, synergy-first set bonuses, stats, toggles, Find/refresh), right **kits** (V5 top-3 compare by default; list mode optional). Goals stay visible while picking so iterate-rerun is one click.
    * **Narrow / phone:** V6 compact rail — stacked single column, collapsed goal chips (+ edit expands full bonus/stat editors), kit cards with five-slot piece rail, **sticky Apply** CTA; top-3 first, then “See all”. Do not force side-by-side split on small viewports.
## Proposed changes
### Finish walkthrough armor branch
* After Armor create/capture: navigate to **armor optimize workspace** (not first empty slot). Prefer one step that hosts both goals + results (V2), not a dead-end constraints-only screen that discards context on navigate.
* **Goals pane** (V2 left / V6 collapsed chips):
    * Seed display/edit from `seedConstraintsFromBuild({ exoticArmorHash, softStatTargets })` + build.className.
    * Set-bonus goals: add/remove rows (`setBonusKey` / armor set identity + 2/4) from entity `set-bonuses` store.
    * **Synergy grouping (required):** when listing/searching set bonuses to add as goals, **group bonuses that synergy with this build at the top**. Verified match path: designated/bridged library synergies expose `armor_set_bonus` links (`armorSetHash` / `armorSetName` / `bonusPieces`) via the same bridge used by `coverageService` / `resolveDesignatedSynergies` + synergy links — not free-text guesswork. UI: section **“Linked to your synergies”** first (show synergy name(s)), then **“All set bonuses”** (searchable). Pre-suggest 2pc goals from required/evidence links when clear.
    * Stat thresholds for EoF six + optional priority order; toggles `includeModEstimates` / `preferReuse` with sensible defaults (mods on, reuse off).
    * Primary CTA: **Find armor kits** / **Refresh kits** → PATCH constraints on set id, then optimize; results fill the kits pane without leaving the workspace.
* **Kits pane** (V2 right / V6 stacked):
    * **Default: V5 top-3 compare** — three columns (stack on phone), score + bonus chips + per-stat bars vs thresholds (hit = success tint) + short piece list + **Apply** per kit.
    * Secondary: **See all N** ranked list (compact rows) for kits beyond top 3.
    * Apply → `apply-combination`; refresh build; mark armor gap satisfied if five slots filled.
* Empty/error: surface `emptyReason` from optimize response; offer **Fill slots manually** fallback into slot-first loop.
* **Phone (V6):** sticky bottom Apply for selected kit; goal editor behind “+ edit” / expand so first paint stays short; touch targets ≥44px; no dual-pane.
### Weapons / Mods / shared Finish chrome
* Same as prior plan: one-tap create/capture, no link picker, slot-first loop, Skip for now, inherit names.
### APIs (compose; avoid new stack)
* Create: existing create-set-attach.
* Constraints: PATCH set `optimizerConstraints`.
* Optimize: existing set optimize route (pass `classType` via set items after apply, or ensure optimizeFromSet gets build class — today class resolved from set items; **empty set may need classType override** — verify/fix: inject build.className into optimize call path if candidates load needs it).
* Apply: existing apply-combination.
* Do not require materialize for Finish armor if apply-in-place on the just-created attached set works; materialize remains optional alternative.
### Implementation notes / risk
* `optimizeFromSet` resolves `classType` from **active set item hashes**; empty armor set has none → must pass class from build (extend optimize body or pre-seed a dummy — **prefer extending optimize API/input to accept optional `classType` from client** when set has no pieces).
* Inventory must be synced or optimize returns NO_INVENTORY — Finish should show clear sync CTA.
### Tests
* Helpers: seed → user edits → constraints payload shape.
* **Set-bonus picker ranking:** bonuses referenced by build synergy `armor_set_bonus` links sort into the synergy group ahead of unrelated sets (pure helper + fixture links).
* Optimize empty-set + explicit classType (if API extended).
* Walkthrough state machine: create → constraints → results → apply → armor satisfied.
* Regression: createSetAndAttach / finishGaps / apply-combination existing tests.
### Out of scope
* Full DIM LO port; Pair; Fashion; silent auto-apply; rewriting debug optimizer UI.
## Implementation sketch
1. Confirm/fix optimize classType when set has zero items (build.className).
2. Pure helpers for Finish armor steps + nextEmptySlot for weapons + synergy-bonus ranking.
3. Finish UI: strip create/link chrome; **V2+V5** armor workspace (responsive → **V6** phone); apply-combination.
4. Weapons/Mods slot-first path.
5. HTML mocks + gate.
## Success check
Finish → Create Armor (one tap) → wide: split goals|kits with synergy-first bonuses; narrow: V6 chip goals + sticky Apply → Find kits → **top-3 compare** → Apply → armor slots filled on attached set. Weapons still slot-first.
## UI mocks
* Canonical: `docs/ui-mocks/finish-build-slot-first.html` — V2+V5 desktop workspace + V6 phone frame.
* Exploration archive: `docs/ui-mocks/armor-picking-variants.html` (V1–V6; selection noted).
