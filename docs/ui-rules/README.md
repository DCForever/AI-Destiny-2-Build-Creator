# UI ↔ Rules map

Production UI inventory mapped to domain acceptance criteria (`DAC-*`), domain business rules (`DBR-*`), feature business rules (`BR-*`), and slice-level acceptance blocks (`NNN:SC-*`, `NNN:US*-AS*`).

Complements the screenshot [UI Atlas](../atlas/README.md). This map is for **traceability and editing rules**, not visual QA captures.

## Artifacts

| Path | Role |
|------|------|
| [`inventory.yaml`](./inventory.yaml) | Curated UI tree + rule ID links per node (**structure** source of truth) |
| [`ui-map.drawio`](./ui-map.drawio) | Generated multi-page Draw.io diagram (full rule text on shapes, **read-only**) |
| [`companion/`](./companion/) | Local web app to browse map + **edit rule text** |
| `specs/domain-acceptance-criteria.md` | Canonical **DAC** text |
| `specs/domain-business-rules.md` | Canonical **DBR** text |
| `specs/business-rules.md` | Canonical **BR** text |
| `specs/00N-*/spec.md` | Slice SC / acceptance scenarios |

## Workflow

```text
inventory.yaml  ──┐
                  ├── generate ──► ui-map.drawio  (labels only; re-run after doc changes)
rule markdown  ───┘

companion editor ── write-back ──► rule markdown  (never auto-commits)
                 └── optional regenerate draw.io
```

1. **Structure / which rules attach to which UI** → edit `inventory.yaml`, then regenerate.
2. **Rule wording** → companion only (or edit markdown directly), then regenerate diagram so labels match.
3. **Review** with git; commit yourself.

## Commands

```powershell
# Generate / refresh the Draw.io file
npm run ui-rules:generate

# Companion (browse + edit + write-back + regenerate)
npm run ui-rules:view
# → http://127.0.0.1:4174
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
