# UI Atlas

Local Revyl/Airbnb-style screen + journey map for Destiny 2 Build Creator.

Screenshots are also wired into the **UI ↔ rules companion** ([`docs/ui-rules`](../ui-rules/README.md)): select an inventory node to see the matching capture next to ACs/BRs. Combined view:

```powershell
npm run ui-rules:view
# → http://127.0.0.1:4174  (tree + shots + rules)
```

**Atlas → diagram links:** each linked screen has **Open node** (companion deep link `?node=…`) and **Download .drawio**. Mapping is generated as [`ui-rules-links.json`](./ui-rules-links.json) via `npm run ui-rules:generate`.

## Browse (Atlas-only)

```powershell
npm run atlas:view
```

Open http://127.0.0.1:4173 — **Report** (journeys), **Screens**, **Map**, full-size lightbox.

With companion running on 4174, header **UI rules map** and per-screen **Rules** buttons open the diagram. Override base: `?uiRulesBase=http://127.0.0.1:4174/`.

## Capture

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

Manifest v3 covers ~47 screens: compose tabs, Catalog weapons/armor + detail (signed-out + signed-in), sets/synergy libraries, loadouts, settings, analyze, debug.

Partial: `$env:ATLAS_ONLY="catalog-weapon-detail,catalog-armor-detail"`

Generated PNGs are gitignored under `docs/atlas/screenshots/`.
