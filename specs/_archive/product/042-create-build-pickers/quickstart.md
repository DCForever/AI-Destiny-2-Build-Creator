# Quickstart: 042-create-build-pickers

## Prerequisites

- App running with manifest entity cache
- Signed-in user with optional library synergies linked to exotic armor

## Manual validation

1. Open Builds → Create build.
2. Pick class Warlock + subclass Broodweaver.
3. **Super**: Browse supers — only Broodweaver-valid supers; pick one — search collapses; Clear restores search.
4. **Exotic**: Browse — groups by slot A–Z names; rows with library links show chips; pick — search collapses.
5. Change class — exotic clears; super options follow new class/subclass.
6. Edit an existing build — same collapse + scope + grouping behavior.

## Automated

```powershell
npx vitest run src/lib/manifest/exoticArmorSearchGroups.test.ts src/app/api/user/synergies/by-target
npm run gate
```

## Mockup

Open `docs/ui-mocks/create-build-search-pickers.html` for visual reference.
