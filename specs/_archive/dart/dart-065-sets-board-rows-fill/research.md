# Research: DART-065 Sets Board, Dense Rows, Slot Fill

**Date**: 2026-07-25

## Product references

| Concern | Next.js source |
| ------- | -------------- |
| Armor board + item cards | `src/components/sets/SetsDetail.tsx` — `ArmorPieceStatRow`, totals, traits, linked synergies |
| Enrichment | `src/lib/sets/enrichSetItems.ts` — catalog meta, trait filter, base stats, reverse synergies |
| Armor totals | `src/lib/sets/sumArmorSetStats.ts` |
| Slot fill + replace | `src/components/sets/SlotFillPanel.tsx` — `pendingReplace` confirm |
| Domain | DAC-NME-004, BR-SET-010/011, BR-SLOT-006, BR-ROLL-001, DBR-STAT-008 |

## Dart today

| Area | Status |
| ---- | ------ |
| Set CRUD + fill | Windows dual-pane + catalog picker (text ListTiles); Jaspr hash+name form |
| `selectedPerks` column / use case | Present; hosts pass `[]` |
| Armor base board pure | `buildArmorBaseStatBoard` in packages/db (DART-063) |
| Plug cards / traits | `buildResolvedPlugCards` + `isTrait` |
| Replace confirm | Missing — `replaceExisting: true` always |
| Armor set totals pure | Missing |

## Decisions

1. **Board source**: Reuse inventory `statValues` → `buildArmorBaseStatBoard` per pinned instance; sum via new pure helper. Do not block on raw plug investment defs (PROC-06 residual documented).
2. **Trait extraction for fill**: Prefer socket plugs with `columnKind == trait` / trait label; else fall back to trait-flagged plug cards; else empty for wishlist.
3. **Jaspr fill**: Introduce embedded search panel fed by compose OfflineCatalog / OwnedCatalogBridge when host has them; hash fields demoted secondary or removed from primary path.
4. **Replace UX**: Host-level dialog (Flutter) / two-step confirm (Jaspr) before `fillSlot`; pure helper decides if confirm needed.
5. **Icons**: Use CatalogItem.icon when available as lightweight avatar/text residual; full ItemIcon → DART-068.

## Open residuals (not this slice)

- Library search/tag filters, readiness, delete → DART-066
- Dense icon art polish → DART-068
- True armor_stats investment base when plug defs unavailable offline
