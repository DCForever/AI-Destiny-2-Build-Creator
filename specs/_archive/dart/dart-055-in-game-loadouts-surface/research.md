# Research: DART-055 In-Game Loadouts Surface

**Date**: 2026-07-25

## Product source of truth

| Concern | Product path |
| ------- | ------------ |
| Parse 206 | `src/lib/bungie/characterLoadouts.ts` |
| Fetch | `src/lib/bungie/fetchInGameLoadouts.ts` |
| Profile components | `src/lib/bungie/profile.ts` — `components=200,206` |
| UI | `src/components/LoadoutsPage.tsx` — Bungie slots section primary |
| Nav | `src/components/AppShell.tsx` NAV_LINKS loadouts → `/loadouts` |

## Dart state before slice

- Drift `loadouts` table exists (local generated snapshots schema parity) — **not** Bungie in-game slots
- Profile client: memberships, characters (200), full inventory — **no** 206
- Manifest `downloadRawTables` already includes DestinyLoadoutIcon/Color/NameDefinition
- Windows nav: Catalog, Sets, Synergies, Builds, Settings — **no** Loadouts
- Jaspr ShellHeader: Catalog, Builds, Sets, Synergies, Settings — **no** Loadouts

## Decisions

| Decision | Choice | Rationale |
| -------- | ------ | --------- |
| Exit path | Ship UI (not demote) | Product keeps loadouts; cutover wants parity |
| Persistence | Live fetch only | Matches product; avoids new migration |
| Presentation | Optional tables | Fallback names always work; icons when raw cached |
| Exotic enrich | Deferred optional | Not required for RB-01 list parity |
| Mobile nav | Out of scope | RC-NAV = Windows + Jaspr |
| Local snapshot library | Out of scope | Product Bungie section is the GAP |

## Risks

- Raw Loadout* tables not downloaded yet → names fallback only (acceptable)
- Web without raw tables → same fallback
- FakeProfileClient interface break → update all fakes in same change
