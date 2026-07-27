# UI Atlas

Runtime **screenshots**, journey browse, and navigation map for Destiny 2 Build Creator.

**Structure and journeys are authored in the product-map hub**, not by hand-editing this folder forever:

- Hub: [`docs/product-map/`](../product-map/README.md) (`surfaces.yaml`, `flows.yaml`, `transitions.yaml`)
- After hub edits: `npm run product-map:sync` regenerates `manifest.json` (screens, nested **paths/phases**, transitions) and `ui-rules-links.json`

This app is optimized for **capture QA and visual browse**. For rules, hub structure edits, and Draw.io export, use the **unified product map**:

```powershell
npm run product-map:view
# → http://127.0.0.1:4174
# Modes: Flows | Screens | Map | Rules | Export
```

## Browse (Atlas-only)

```powershell
npm run atlas:view
```

Open http://127.0.0.1:4173 — **Report** (journeys / nested phases when present), **Screens**, **Map**, full-size lightbox.

When the companion is also running on **4174**, header **UI rules map** and per-screen **Rules** / **Open node** links jump into the product-map viewer (`?node=…`). Override base URL: `?uiRulesBase=http://127.0.0.1:4174/`.

You can also open Atlas under the companion: http://127.0.0.1:4174/atlas/

## What is generated vs captured

| Artifact | Source |
|----------|--------|
| `manifest.json` screens / paths / transitions | **Generated** from product-map (do not hand-edit as primary workflow) |
| `ui-rules-links.json` | **Generated** reverse map Atlas screen → surface |
| `screenshots/*.png` | **Captured** via Playwright (`atlas:capture`); gitignored |
| `screenshots/flutter-windows/` | Flutter capture plan / future PNGs ([FLUTTER.md](../product-map/FLUTTER.md)) |

Manifest currently tracks production + debug capture targets (~46 screens). **Paths** include hierarchical phases from product-map flows (subflows, branches, loops).

## Capture (Next.js)

```powershell
npm run dev:https
# once:
npm i -D playwright
npx playwright install chromium
npm run atlas:auth   # saves .atlas/auth.json
$env:ATLAS_BASE_URL="https://127.0.0.1:3000"
$env:ATLAS_STORAGE_STATE=".atlas/auth.json"
npm run atlas:capture
```

Partial: `$env:ATLAS_ONLY="catalog-weapon-detail,catalog-armor-detail"`

PNGs land in `docs/atlas/screenshots/` as `{captureId}__{variant}.png` (e.g. `build-edit-general__signed-in.png`). Those **captureId** values should match `platforms.nextjs.captureId` on surfaces in the product-map hub.

## Atlas → product map links

- Generated [`ui-rules-links.json`](./ui-rules-links.json) maps each Atlas screen id → primary surface id.
- Screen detail and journey steps offer **Open node** (companion) and **Download .drawio**.
- Nested **Phases** UI on journey detail reflects product-map `include` / `branch` / `loop` / `gate`.

Regenerate links after hub changes:

```powershell
npm run product-map:sync
# or
npm run product-map:generate
```

## Flutter captures (planned)

```powershell
npm run product-map:capture-stub -- --platform=flutter-windows --write-plan
npm run product-map:parity
```

See [product-map FLUTTER.md](../product-map/FLUTTER.md). Same logical `captureId` as Next when possible; files under `screenshots/flutter-windows/`.

## Related

| Doc | Contents |
|-----|----------|
| [product-map README](../product-map/README.md) | Structure SSoT, sync, CI |
| [ui-rules README](../ui-rules/README.md) | Draw.io + companion |
| [product-map CHECKLIST](../product-map/CHECKLIST.md) | Same-change UI update checklist |
