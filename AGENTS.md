<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

## Domain & feature rules (always consult + keep current)

When **planning** or **implementing** product behavior:

1. **Read first** (domain wins on conflict):
   - [`specs/domain-business-rules.md`](specs/domain-business-rules.md) — `DBR-*`
   - [`specs/domain-acceptance-criteria.md`](specs/domain-acceptance-criteria.md) — `DAC-*`
   - [`specs/business-rules.md`](specs/business-rules.md) — `BR-*` (feature layer)

2. **Update those docs in the same change** when you ship or decide a product rule that is not already captured (new/changed DBR, DAC, BR; supersession notes; **Updated** date). Do not leave rules only in commits or chat.

3. **Pure UI polish** (density, chrome collapse, viewport lock) stays out of domain P1/P2 gates unless it encodes product semantics — note trackers under `docs/` if needed.

4. Feature specs under `specs/00N-*/` remain slice-level; still align them with domain when they contradict DBR/DAC.

## Product map / App Atlas (UI structure SSoT)

When **planning** or **implementing** user-visible UI (screens, tabs, modals, flows, gates):

1. **Read / update** [`docs/product-map/`](docs/product-map/) in the **same change**:
   - `surfaces.yaml` — product places + `rules:` attachments + platform bindings
   - `flows.yaml` — journeys / subflows / phases
   - `transitions.yaml` — map edges
2. Rule **wording** still lives in domain markdown (above); hub holds **IDs** and structure only.
3. After hub edits: `npm run product-map:sync` (regenerates Draw.io, Atlas manifest paths, inventory projection).
4. Scaffold: `npm run product-map:add-surface` / `product-map:add-flow`.
5. Do **not** hand-edit generated `docs/ui-rules/ui-map.drawio`, `docs/ui-rules/inventory.yaml`, or generated Atlas path blocks — edit the hub and sync.
6. Multi-platform: same surface id; add `platforms.flutter-windows` (etc.) when shells exist — do not fork DBR/DAC per platform.
