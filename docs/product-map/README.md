# Product map hub (structure SSoT)

Platform-agnostic **surfaces**, **flows**, and **rule attachments**.  
Rule **wording** stays in `specs/domain-*.md`, `specs/business-rules.md`, and feature specs.

## Files

| File | Role |
|------|------|
| [`meta.yaml`](./meta.yaml) | Title, version, notes |
| [`platforms.yaml`](./platforms.yaml) | nextjs, flutter-windows, … |
| [`surfaces.yaml`](./surfaces.yaml) | Product UI places + rules + platform bindings |
| [`flows.yaml`](./flows.yaml) | Journeys / subflows / phases |
| [`transitions.yaml`](./transitions.yaml) | Navigation edges (Atlas Map) |

**Do not hand-edit** generated projections:

- `docs/ui-rules/ui-map.drawio`
- `docs/ui-rules/inventory.yaml` (compat projection)
- `docs/atlas/manifest.json` screens/paths/transitions (after generate)
- `docs/atlas/ui-rules-links.json`

## Commands

```powershell
# Validate hub + resolve rule IDs
npm run product-map:validate

# Validate → generate → route drift check
npm run product-map:sync

# Drift only / dirty generate / orphan domain rules / CI bundle
npm run product-map:check
npm run product-map:check-dirty
npm run product-map:orphan-rules
npm run product-map:ci

# Flutter Windows stubs + parity
npm run product-map:seed-flutter
npm run product-map:parity
npm run product-map:capture-stub -- --platform=flutter-windows --write-plan

# Scaffold
npm run product-map:add-surface -- --id area.name --title "Title" --area build
npm run product-map:add-flow -- --id flow.example --title "Example flow"

# One-time / re-import from legacy inventory + atlas (overwrites hub surfaces/flows)
npm run product-map:import
```

Feature checklist: [`CHECKLIST.md`](./CHECKLIST.md).

## Unified viewer

```powershell
npm run ui-rules:view
# http://127.0.0.1:4174
```

| Mode | Purpose |
|------|---------|
| **Flows** | Nested phases (include/branch/loop/gate); add phase stubs |
| **Screens** | Surfaces by area + Atlas shots; attach rule IDs to hub |
| **Map** | Transitions |
| **Rules** | Edit DAC/DBR/BR/slice wording → markdown write-back |
| **Export** | Sync/generate, download draw.io, quick-add surface |

Structure writes go to `surfaces.yaml` / `flows.yaml` (never auto-commit).

## Edit workflow

1. Change surfaces/flows in this folder (or scaffold).
2. If rule **wording** changes → domain markdown or companion write-back.
3. `npm run product-map:sync`
4. Optional: `npm run atlas:capture` for touched capture ids.
5. Commit hub + generated artifacts together.

## Surface sketch

```yaml
- id: build.compose.general
  title: Build compose — General
  kind: screen
  area: build
  auth: signed-in
  parent: null
  rules: [DAC-P1-001, DBR-SYN-003]
  refs:
    - { type: error, id: NO_SYNERGY }
  platforms:
    nextjs:
      path: /build
      captureId: build-edit-general
```

## Flow sketch

```yaml
- id: flow.build.create
  title: Create new build
  type: subflow
  priority: P1
  phases:
    - id: library
      title: Open library
      surface: build.library
    - id: draft
      title: Draft General
      surface: build.create.general
```

See plan: Unified Product Map — layered SSoT, multi-platform, easy updates.
