# UI Atlas

Local Revyl/Airbnb-style screen + journey map for Destiny 2 Build Creator.

## Browse

```powershell
npm run atlas:view
```

Open http://127.0.0.1:4173 — **Report** (journeys), **Screens**, **Map**, full-size lightbox.

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
