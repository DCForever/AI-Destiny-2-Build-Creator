# Product map hub (structure SSoT)

Platform-agnostic **surfaces**, **flows**, **transitions**, and **rule attachments** for Destiny 2 Build Creator.

| Layer | Location | What you edit |
|-------|----------|----------------|
| **Structure** | this folder | Screens, phases, platforms, which rule IDs apply |
| **Wording** | `specs/domain-*.md`, `business-rules.md`, feature specs | Full DAC / DBR / BR / slice text |
| **Projections** | generated | Draw.io, Atlas manifest/paths, inventory.yaml — **do not hand-edit** |

Root project overview: [../../README.md](../../README.md).  
Whole-product framing: [../../PRODUCT.md](../../PRODUCT.md).  
**Product descriptions** (domain concepts + UI areas): **Obsidian** `Projects/Destiny 2 Build Creator/Products.md` — git pointer [`../products/`](../products/).  
Agent rules: [../../AGENTS.md](../../AGENTS.md).

## Files

| File | Role |
|------|------|
| [`meta.yaml`](./meta.yaml) | Title, version, `updated` stamp (used for stable generate) |
| [`platforms.yaml`](./platforms.yaml) | nextjs, flutter-windows, flutter-mobile, jaspr-web |
| [`surfaces.yaml`](./surfaces.yaml) | Product UI places + `rules:` + platform bindings |
| [`flows.yaml`](./flows.yaml) | Journeys / subflows / phases (`include`, `branch`, `loop`, `gate`) |
| [`transitions.yaml`](./transitions.yaml) | Navigation edges (Map mode) |
| [`CHECKLIST.md`](./CHECKLIST.md) | Same-change checklist for UI PRs |
| [`FLUTTER.md`](./FLUTTER.md) | Flutter Windows stubs and parity |
| [`orphan-rules.md`](./orphan-rules.md) | Generated: domain rules not attached on the map |
| [`parity-flutter-windows.md`](./parity-flutter-windows.md) | Generated: Flutter stub parity report |

**Generated elsewhere (commit with hub changes):**

- `docs/ui-rules/ui-map.drawio`
- `docs/ui-rules/inventory.yaml`
- `docs/atlas/manifest.json`
- `docs/atlas/ui-rules-links.json`

## Day-to-day workflow

```powershell
# 1. Edit hub (or use viewer structure forms / scaffold)
# 2. Validate + generate + drift check
npm run product-map:sync

# 3. Browse / edit rules
npm run product-map:view
# → http://127.0.0.1:4174

# 4. Before PR / with gate
npm run product-map:ci
# npm run gate   # includes product-map:ci
```

1. Change surfaces/flows in this folder (or scaffold / companion).
2. If rule **wording** changes → domain markdown or companion **Rules** mode.
3. `npm run product-map:sync`
4. Optional: `npm run atlas:capture` for touched Next `captureId`s.
5. Commit **hub + generated artifacts** together.

## Commands

| Script | Purpose |
|--------|---------|
| `product-map:view` / `ui-rules:view` | Unified companion (:4174) |
| `product-map:validate` | Hub structure + rule ID resolve |
| `product-map:generate` | Hub → Draw.io, inventory, Atlas manifest/links |
| `product-map:sync` | validate → generate → check |
| `product-map:check` | Routes vs hub, missing surface refs, orphan screens (warn) |
| `product-map:check-dirty` | Fail if generate would change committed outputs |
| `product-map:orphan-rules` | Report unattached DAC/DBR/BR → `orphan-rules.md` |
| `product-map:ci` | Full map gate (used by `npm run gate` + GitHub Actions) |
| `product-map:add-surface` / `add-flow` | Scaffold YAML stubs |
| `product-map:import` | Re-seed hub from legacy inventory + atlas (**overwrites**) |
| `product-map:seed-flutter` | Seed `platforms.flutter-windows` stubs |
| `product-map:parity` | Flutter parity report |
| `product-map:capture-stub` | Flutter capture plan (no real PNGs yet) |

```powershell
npm run product-map:add-surface -- --id build.foo --title "Foo" --area build --path /build
npm run product-map:add-flow -- --id flow.example --title "Example"
npm run product-map:capture-stub -- --platform=flutter-windows --write-plan
```

Gate escape hatch: `GATE_SKIP_PRODUCT_MAP=1`. Soft map CI: `PRODUCT_MAP_CI_SOFT=1`.

## Unified viewer

```powershell
npm run product-map:view
# http://127.0.0.1:4174
```

| Mode | Purpose |
|------|---------|
| **Flows** | Nested phases; add phase stubs to `flows.yaml` |
| **Screens** | Surfaces by area; Next / Flutter filter; shots; attach rule IDs |
| **Map** | Transitions |
| **Rules** | Edit wording → markdown write-back (never auto-commit) |
| **Export** | Sync/generate, download Draw.io, quick-add surface |

Deep links: `?mode=flows&flow=…`, `?mode=screens&node=…&platform=flutter-windows`, `?mode=rules&rule=DAC-P1-007`.

Also: [ui-rules README](../ui-rules/README.md) (projections + APIs), [Atlas README](../atlas/README.md) (capture + visual QA).

## Surface sketch

```yaml
- id: build.edit.general
  title: Build compose — General
  kind: screen
  area: build
  auth: signed-in
  parent: null
  rules: [DAC-P1-001, DBR-SYN-003]
  platforms:
    nextjs:
      path: /build
      captureId: build-edit-general
    flutter-windows:
      status: stub
      route: /build
      captureId: build-edit-general
```

## Flow sketch

```yaml
- id: journey.p1.intent-compose-equip
  title: P1 — Intent → compose → equip
  type: journey
  priority: P1
  phases:
    - id: create
      title: Create build
      include: flow.build.create
    - id: compose
      title: Compose default
      include: flow.build.compose-default

- id: flow.build.armor-set
  type: subflow
  phases:
    - id: path
      title: Choose path
      branch:
        - { id: reuse, title: Reuse, surface: build.edit.armor.reuse }
        - { id: create, title: Create, surface: build.edit.armor.create }
    - id: fill
      title: Fill slots
      surface: sets.fill-slot
      loop: until-required-slots
```

Phase fields: `surface`, `include`, `branch[]`, `loop`, `gate`, `rules`.

## Multi-platform

- **Same surface id and rule IDs** across Next and Flutter — do not fork DBR/DAC per shell.
- Flutter Windows is the first Dart shell; see [FLUTTER.md](./FLUTTER.md).
- Captures: Next flat `docs/atlas/screenshots/{captureId}__*.png`; Flutter nested `screenshots/flutter-windows/`.

## Related reports

| Report | Command |
|--------|---------|
| Orphan domain rules | `npm run product-map:orphan-rules` |
| Flutter parity | `npm run product-map:parity` |
