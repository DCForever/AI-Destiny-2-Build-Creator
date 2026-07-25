# UI Atlas

Local Revyl/Airbnb-style screen + journey map.

## Browse

```powershell
npm run atlas:view
```

Open http://127.0.0.1:4173

## Capture

```powershell
npm run dev:https
# once:
npm i -D playwright
npx playwright install chromium
npm run atlas:auth
$env:ATLAS_BASE_URL="https://127.0.0.1:3000"
$env:ATLAS_STORAGE_STATE=".atlas/auth.json"
npm run atlas:capture
```
