# Product map update checklist

Use when shipping **user-visible UI** (screens, tabs, modals, flows, gates) or **product rules** that attach to UI.

## Same change as code

- [ ] **Surfaces** — add/update rows in `surfaces.yaml` (`npm run product-map:add-surface` if new)
- [ ] **Flows / phases** — add/update `flows.yaml` (include / branch / loop for subflows)
- [ ] **Transitions** — map edges in `transitions.yaml` if navigation changed
- [ ] **Rules** — attach `DAC-*` / `DBR-*` / `BR-*` / slice ids; edit **wording** in domain markdown if needed
- [ ] **Sync** — `npm run product-map:sync`
- [ ] **Check** — `npm run product-map:check`
- [ ] **Capture** (optional) — partial atlas capture for touched `captureId`s
- [ ] **PR note** — list surface/flow ids under a “Product map” subsection

## Do not

- Hand-edit generated `docs/ui-rules/inventory.yaml`, `ui-map.drawio`, or Atlas path blocks
- Fork DBR/DAC per platform — add `platforms.flutter-windows` (etc.) on the same surface

## Commands

```powershell
npm run product-map:add-surface -- --id area.name --title "Title" --area build --path /build
npm run product-map:add-flow -- --id flow.example --title "Example"
npm run product-map:sync
npm run product-map:check
npm run ui-rules:view
```
