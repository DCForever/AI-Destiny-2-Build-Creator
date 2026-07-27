# UI ↔ Rules map (+ Atlas screenshots)

Production UI inventory mapped to domain acceptance criteria (`DAC-*`), domain business rules (`DBR-*`), feature business rules (`BR-*`), and slice-level acceptance blocks (`NNN:SC-*`, `NNN:US*-AS*`).

**Structure SSoT** is now [`docs/product-map/`](../product-map/README.md). This folder holds **generated** inventory/drawio projections plus the companion app.

**Combined with** the screenshot [UI Atlas](../atlas/README.md): the companion links inventory nodes to Atlas screen IDs and shows captures next to rules. The standalone Atlas viewer remains available for journeys/element density.

## Artifacts

| Path | Role |
|------|------|
| [`../product-map/`](../product-map/) | **Structure SSoT** (surfaces, flows, platforms) |
| [`inventory.yaml`](./inventory.yaml) | **Generated** UI tree projection (do not hand-edit) |
| [`ui-map.drawio`](./ui-map.drawio) | Generated multi-page Draw.io diagram (full rule text + 📷 Atlas ids, **read-only**) |
| [`companion/`](./companion/) | Local web app: inventory tree, **screenshots**, edit rule text |
| [`../atlas/`](../atlas/) | Manifest, journeys, screenshots (PNGs gitignored) |
| `specs/domain-acceptance-criteria.md` | Canonical **DAC** text |
| `specs/domain-business-rules.md` | Canonical **DBR** text |
| `specs/business-rules.md` | Canonical **BR** text |
| `specs/00N-*/spec.md` | Slice SC / acceptance scenarios |

## Workflow

```text
inventory.yaml  ──┐
rule markdown  ───┼── generate ──► ui-map.drawio  (labels + Atlas screen ids)
Atlas manifest ───┘

companion ── screenshots from docs/atlas/screenshots
         ── write-back ──► rule markdown  (never auto-commits)
         ── optional regenerate draw.io
```

1. **Structure / which rules attach to which UI** → edit `inventory.yaml`, then regenerate.
2. **Screenshots** → `npm run atlas:capture` (see Atlas README); companion serves them at `/atlas/screenshots/…`.
3. **Rule wording** → companion (or markdown), then regenerate diagram so labels match.
4. **Review** with git; commit yourself.

## Atlas linking (bidirectional navigation)

| Direction | How |
|-----------|-----|
| **Inventory → Atlas shot** | Companion resolves node → screen id → PNG |
| **Atlas → diagram** | Atlas UI links to companion `?node=…` + `.drawio` download |

Resolution order for each inventory node:

1. Explicit `atlas:` field on the node (`string` or list of Atlas screen ids)
2. Alias table in `scripts/ui-rules/lib/atlas-link.mjs` (name mismatches)
3. Auto: `node.id` with `.` → `-` if it matches `docs/atlas/manifest.json` screen id
4. Inherit nearest ancestor’s link (fields show parent screen shots)

Generate also writes reverse map [`docs/atlas/ui-rules-links.json`](../atlas/ui-rules-links.json) (Atlas screen → primary inventory node).

Deep link examples:

```text
http://127.0.0.1:4174/?node=build.finish&page=build
http://127.0.0.1:4174/ui-map.drawio
```

Example explicit link:

```yaml
- id: build.finish
  kind: screen
  title: Finish tab
  atlas: build-edit-finish   # or [id1, id2]
  rules: [DAC-P1-007]
```

## Commands

```powershell
# Preferred: validate hub + regenerate all projections
npm run product-map:sync

# Unified product map viewer (Flows | Screens | Map | Rules | Export)
npm run ui-rules:view
# → http://127.0.0.1:4174
# Deep links: ?mode=flows&flow=…  ?mode=screens&node=…  ?mode=rules&rule=DAC-P1-007
```

Optional env:

- `UI_RULES_PORT` (default `4174`)
- `UI_RULES_HOST` (default `127.0.0.1`)

## Draw.io

- Format: **uncompressed** multi-page `.drawio` (git-friendly).
- Open in [diagrams.net](https://app.diagrams.net/) / VS Code Draw.io extension.
- **Do not treat shape text as editable source** — regenerate after companion or markdown edits.
- Pages: Overview, Build, Catalog, Sets, Synergy, Loadouts, Settings, Analyze, Cross-cutting.

## Inventory schema (YAML)

```yaml
pages:
  - id: build
    label: Build
    description: optional
    nodes:
      - id: build.library          # stable id
        kind: screen               # screen|subscreen|surface|field|flow|gate|auth
        title: Build library
        path: /build               # optional route
        auth: signed-in            # signed-in|signed-out|any
        notes: optional
        rules:                     # rule IDs (see below)
          - DAC-P1-001
          - DBR-SYN-003
          - BR-TAG-008
          - 001:SC-002
        children: []               # nested UI
        flowsTo: [build.create]    # optional edge targets (same page)
```

### Rule ID forms

| Form | Example | Source |
|------|---------|--------|
| Domain AC | `DAC-P1-007` | `domain-acceptance-criteria.md` |
| Domain BR | `DBR-EQP-001` | `domain-business-rules.md` |
| Feature BR | `BR-BLD-008` | `business-rules.md` |
| Slice SC | `001:SC-001` | `specs/001-…/spec.md` success criteria |
| Slice acceptance scenario | `002:US1-AS2` | User story acceptance scenario #2 |

Ranges like `DBR-EQP-001–008` expand when generating.

## Companion write-back

- **PUT** `/api/rules/:id` with `{ "body": "...", "title": "...", "regenerate": true }`.
- Updates the matching heading block (DAC), table row (DBR/BR), or SC/AS line (slice).
- Leaves git dirty; **never commits**.

## Scope

- **In:** production routes + signed-in/out variants; Analyze; shared pickers; P1/P2 journeys.
- **Out:** `/debug/*` (add later in inventory if needed).

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/ui-rules/generate.mjs` | inventory + docs → `ui-map.drawio` |
| `scripts/ui-rules/server.mjs` | companion HTTP API + static files |
| `scripts/ui-rules/lib/parse-rules.mjs` | parse DAC/DBR/BR/slice |
| `scripts/ui-rules/lib/writeback.mjs` | write rule text into markdown |
| `scripts/ui-rules/lib/drawio.mjs` | uncompressed mxfile builder |
