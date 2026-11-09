# Research: DART-068 Presentation Shell / Loadouts / Settings

**Date**: 2026-07-25

## Decisions

### A1 — Nav order & labels

- Product `AppShell.tsx` `NAV_LINKS` order: Loadouts, Build, Synergy, Sets, Catalog, Settings.
- Short labels: Loadouts, Build, Synergy, Sets, Catalog, Settings (singular Build/Synergy).
- Paths remain `/builds`, `/synergies`; mobile bottom nav stays Builds|Settings (DART-057).

### A2 — Icons

- Entity `icon` fields are relative Bungie paths; resolve with `bungieContentUrl` (`https://www.bungie.net` + path).
- Hosts use Image.network / img with error/placeholder; no offline icon pack required for exit.

### A3 — Loadout exotics

- Port `resolveLoadoutExoticsFromInstances` + catalog index builders from Next into `destiny2_bungie`.
- Hosts supply instanceId→hash from Drift inventory and exotic hashes/names from OfflineCatalog / MVP stores when available.

### A4 — Designation chrome without full icon index

- Primary exit is human Verb:/Element: labels + element color chrome.
- Full Bungie designation icon map (Next `buildDesignationNameIconIndex`) is optional residual if entity tables unavailable offline — not blocking if labels + element tokens ship.

### A5 — Settings timestamps

- Mirror Next `formatLastSyncLabel`: same calendar day → locale time; else short month/day + time; null → Never.
- ONLINE when lastFullSyncAt present (hasSynced).

### A6 — Soft / secrets

- No soft auto-apply paths.
- No CLIENT_SECRET.

## References

- `src/components/AppShell.tsx`
- `src/components/ui/LoadoutColorBar.tsx`
- `src/lib/loadouts/resolveLoadoutExoticsFromInstances.ts`
- `src/lib/settings/formatInventorySync.ts`
- `src/components/settings/ManifestCard.tsx`, `InventorySyncCard.tsx`
- `docs/multiplatform-dart-ui-fidelity.md` GAP-UI-* for this slice
