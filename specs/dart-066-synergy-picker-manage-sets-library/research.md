# Research: DART-066

**Date**: 2026-07-25

## Product parity sources

| Concern | Product source | Dart port target |
| ------- | -------------- | ---------------- |
| Evidence omit-linked | `src/lib/synergies/filterLinkedPickerResults.ts` | `synergy_picker_presentation.dart` |
| Coverage keys | `src/lib/synergies/coverageKeys.ts` | same |
| Weapon perk labels | `src/lib/synergies/weaponPerkSourceLabel.ts` | same |
| Synergy list filters | `src/lib/synergies/filterSynergies.ts` | `library_filters.dart` |
| Sets list filters | `src/lib/sets/filterSets.ts` | `library_filters.dart` |
| Readiness / fill next | `src/components/sets/SetsDetail.tsx` | `set_library_presentation.dart` |
| SET_IN_USE | `deleteUserSet` / BR-DEL-001 | existing use case + host messaging |

## Decisions

1. **Client-side filters** after `listUserSets` / `listUserSynergies` — matches product SetsPage/SynergyPage; avoids new repo queries.
2. **Catalog evidence search** reuses OfflineCatalog/OwnedCatalogBridge items; kind filter via composition heuristics + link kind mapping (DART-063).
3. **Mod sets**: readiness shows mod count; Fill next omitted (product `mods_only`).
4. **PROC-06 residual**: full weapon_perk entity extract density when catalog lacks plug rows — free-text/hash + optional source labels still satisfy BR-SYN-011/012 when data present.

## Non-goals

- Designation icons (DART-068)
- Mobile library surfaces
- Cutover re-gate
