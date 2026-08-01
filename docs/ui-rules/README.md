# UI rules projections + unified companion

This folder holds **generated** Draw.io / inventory projections and the **unified product-map companion** (served by `scripts/ui-rules/server.mjs`).

**Structure source of truth is not here** — edit [`docs/product-map/`](../product-map/README.md) (`surfaces.yaml`, `flows.yaml`, …).  
**Rule wording** stays in `specs/domain-*.md`, `specs/business-rules.md`, and feature specs.

| Need | Go to |
|------|--------|
| Add/edit screens & flows | [`../product-map/`](../product-map/README.md) + `npm run product-map:sync` |
| Browse map + edit rules | `npm run product-map:view` (or `ui-rules:view`) → http://127.0.0.1:4174 |
| Screenshots only | [`../atlas/README.md`](../atlas/README.md) |

## Artifacts in this directory

| Path | Role |
|------|------|
| [`ui-map.drawio`](./ui-map.drawio) | **Generated** multi-page Draw.io (structure + full rule labels + flow pages). Read-only; regenerate after hub/doc changes. |
| [`inventory.yaml`](./inventory.yaml) | **Generated** tree projection for legacy tooling / reverse Atlas links. **Do not hand-edit.** |
| [`companion/`](./companion/) | Unified viewer UI (Flows · Screens · Map · Rules · Export) |

Related elsewhere:

| Path | Role |
|------|------|
| [`../product-map/`](../product-map/) | Structure SSoT |
| [`../atlas/`](../atlas/) | Screenshots (gitignored PNGs), Atlas-only app, generated `manifest.json` + `ui-rules-links.json` |
| `specs/domain-acceptance-criteria.md` | `DAC-*` wording |
| `specs/domain-business-rules.md` | `DBR-*` wording |
| `specs/business-rules.md` | `BR-*` wording |

## Architecture

```text
docs/product-map/          (edit: surfaces, flows, platforms, rule IDs)
        │
        ▼  npm run product-map:sync  /  product-map:ci
        │
        ├──► docs/ui-rules/ui-map.drawio
        ├──► docs/ui-rules/inventory.yaml
        ├──► docs/atlas/manifest.json      (screens, paths/phases, transitions)
        └──► docs/atlas/ui-rules-links.json

specs/*.md  ◄── write-back ── companion Rules mode
                (never auto-commits)

docs/atlas/screenshots/*.png  ──► companion Screens / Flows (view)
```

1. **Structure** → edit product-map hub (or companion structure forms).
2. **Sync** → `npm run product-map:sync` (commit hub + generated files).
3. **Rule wording** → companion **Rules** mode or edit markdown; regenerate so Draw.io labels update.
4. **Screenshots** → `npm run atlas:capture` (Next); Flutter path when shell exists ([FLUTTER.md](../product-map/FLUTTER.md)).

## Unified viewer

```powershell
npm run product-map:view
# alias: npm run ui-rules:view
# → http://127.0.0.1:4174
```

| Mode | Purpose |
|------|---------|
| **Flows** | Nested phases (`include` / `branch` / `loop` / `gate`); add phase stubs to hub |
| **Screens** | Surfaces by area; Next vs `flutter-windows` filter; Atlas shots; attach rule IDs |
| **Map** | Transitions from product-map |
| **Rules** | Edit DAC/DBR/BR/slice body → write markdown |
| **Export** | Sync/generate, download `.drawio`, quick-add surface |

Deep links:

```text
http://127.0.0.1:4174/?mode=flows&flow=journey.p1.intent-compose-equip
http://127.0.0.1:4174/?mode=screens&node=build.finish&platform=flutter-windows
http://127.0.0.1:4174/?mode=rules&rule=DAC-P1-007
http://127.0.0.1:4174/ui-map.drawio
```

Env: `UI_RULES_PORT` (default `4174`), `UI_RULES_HOST` (default `127.0.0.1`).

Standalone Atlas (journeys + lightbox without hub editor): `npm run atlas:view` → :4173, or `/atlas/` when companion is running.

## Atlas ↔ surface linking

| Direction | How |
|-----------|-----|
| Surface → screenshot | `platforms.nextjs.captureId` (and aliases / id auto-map) → PNG under `docs/atlas/screenshots/` |
| Atlas → companion | Header / per-screen **Rules** links → `?node=…` (see [Atlas README](../atlas/README.md)) |

Reverse map: generated [`../atlas/ui-rules-links.json`](../atlas/ui-rules-links.json).

Capture binding on a surface (in **product-map**, not inventory.yaml):

```yaml
# docs/product-map/surfaces.yaml
- id: build.finish
  kind: screen
  title: Finish tab
  rules: [DAC-P1-007, DBR-EQP-003]
  platforms:
    nextjs:
      path: /build
      captureId: build-edit-finish
    flutter-windows:
      status: stub
      route: /build
      captureId: build-edit-finish
```

## Draw.io

- Uncompressed multi-page `.drawio` (git-friendly).
- Open in [diagrams.net](https://app.diagrams.net/) or a VS Code Draw.io extension.
- **Shape text is not editable source** — change rules in specs / companion, structure in product-map, then sync.
- Pages include area structure + hierarchical **flow** pages.

## Rule ID forms

| Form | Example | Source |
|------|---------|--------|
| Domain AC | `DAC-P1-007` | `domain-acceptance-criteria.md` |
| Domain BR | `DBR-EQP-001` | `domain-business-rules.md` |
| Feature BR | `BR-BLD-008` | `business-rules.md` |
| Slice SC | `001:SC-001` | feature `spec.md` |
| Slice acceptance scenario | `002:US1-AS2` | user story scenarios |

Ranges like `DBR-EQP-001–008` expand when generating labels.

## Companion APIs (local only)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/hub` | Surfaces, flows, transitions |
| GET | `/api/hub/flows` | Flows + expanded phase trees |
| PUT | `/api/hub/attach-rules` | Write `rules:` on a surface |
| POST | `/api/hub/add-phase` | Append phase stub to a flow |
| POST | `/api/hub/add-surface` | Append surface stub |
| PUT | `/api/rules/:id` | Write rule wording to markdown |
| POST | `/api/sync` | Run `product-map:sync` |
| POST | `/api/generate` | Regenerate projections |

Never auto-commits.

## Commands (canonical)

Prefer **product-map** scripts (see [product-map README](../product-map/README.md)):

```powershell
npm run product-map:sync      # day-to-day after hub edits
npm run product-map:ci        # full map gate (also part of npm run gate)
npm run product-map:view      # companion
npm run product-map:check-dirty
npm run product-map:orphan-rules
```

`npm run ui-rules:generate` is an alias for `product-map:generate`.

## Scripts under `scripts/ui-rules/`

| Script | Purpose |
|--------|---------|
| `server.mjs` | Companion HTTP server + hub/rule APIs |
| `lib/parse-rules.mjs` | Parse DAC/DBR/BR/slice from markdown |
| `lib/writeback.mjs` | Write rule text into markdown |
| `lib/drawio.mjs` | Uncompressed mxfile builder |
| `lib/atlas-link.mjs` | Surface ↔ Atlas screen / screenshot resolution |

Generate/import/CI live under `scripts/product-map/`.

## Scope

- **In:** production routes, signed-in/out variants, hierarchical P1/P2 flows, Analyze, shared pickers, Flutter stubs.
- **Out of first-class map:** `/debug/*` (may appear in Atlas captures only).
