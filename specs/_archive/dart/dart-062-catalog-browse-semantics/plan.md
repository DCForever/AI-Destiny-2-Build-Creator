# Implementation Plan: DART-062 Catalog Browse Semantics

**Branch**: `dart-062-catalog-browse-semantics` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-062-catalog-browse-semantics/spec.md`

## Summary

Close catalog browse fidelity gaps on Windows Flutter + Jaspr: wire multi-facet include/exclude chips (slot/class/archetype + existing element/ammo/exotic), add pure multi-dimension group-by and alpha display-name sort, and expand MVP entity defs with exotic weapons + legendary armor stores so offline catalog is not legendary-weapons-only / exotic-armor-only.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_manifest` (pure extractors + filter), Flutter Windows host, Jaspr web host  

**Storage**: Entity JSON under StorageRoot (desktop); prebuilt/prod entity bundles (web)  

**Testing**: `dart test` in `packages/manifest`; Flutter widget tests `apps/windows_host`; Jaspr component tests `apps/web_host`  

**Target Platform**: Windows Flutter + Jaspr web (mobile catalog remains N/A)  

**Project Type**: Multiplatform monorepo pure packages + dual UI shells  

**Performance Goals**: Client-side filter/group on in-memory lists; BR-CAT-005 <5s still holds for MVP sizes  

**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no cutover re-gate  

**Scale/Scope**: Two new MVP stores; projector/offline/bundle updates; two host UIs; unit + widget tests  

## Constitution Check

- I. Small Testable Increments: US1–US5 independently testable  
- II. Test-First: extractor/group/sort tests before/with implementation  
- III. Green Commit: `dart test` packages/manifest + host catalog tests green before merge  
- IV–V. Co-located package tests; validation via exit criteria map  

## Project Structure

### Documentation (this feature)

```text
specs/dart-062-catalog-browse-semantics/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/manifest/lib/src/
  catalog/
    filter_catalog.dart       # alpha sort finalize
    group_catalog.dart        # NEW group-by
    sort_by_name.dart         # NEW compareDisplayName
    catalog_projector.dart    # exotic weapons + legendary armor
    offline_catalog.dart      # load new stores
    filter_options.dart       # export group dimension lists (existing chips)
  extractors/
    exotic_weapons.dart       # NEW
    legendary_armor.dart      # NEW
    registry.dart
  types/
    records.dart              # ExoticWeaponRecord, LegendaryArmorRecord
    stores.dart               # MvpStoreName entries
  entity_bundle.dart
  memory_entity_cache.dart    # decode switches
apps/windows_host/lib/catalog/catalog_page.dart
apps/web_host/lib/pages/catalog_page.dart
apps/web_host/web/entities/{prebuilt,prod}/bundle.json
```

## Implementation approach

1. **Records + stores**: Add `ExoticWeaponRecord`, `LegendaryArmorRecord`; `MvpStoreName.exoticWeapons` / `legendaryArmor`.
2. **Extractors**: Port Next exotic weapons; legendary armor = tier 5 armor with slot/class (optional archetype plug).
3. **Project + load**: Merge into `projectMvpStores` / OfflineCatalog / EntityBundle.
4. **Sort + group**: `compareDisplayName`; `filterCatalogClient` returns alpha list; `groupCatalogItems`.
5. **Hosts**: Wire slot/class/archetype facet rows + group-by chips; render flat list or grouped sections.
6. **Fixtures**: Gjallarhorn-like exotic weapon + legendary armor in raw tables; sample rows in web bundles.
7. **Docs**: Close GAP rows in feature-gaps / ui-fidelity when present; roadmap done.

## Risks / mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Older caches missing new stores | Treat missing store as empty list |
| Test order assertions break after alpha sort | Update expected order in filter tests |
| Bundle size | Sample only in ship-in-app; full extract on desktop refresh |

## Test plan

- `packages/manifest/test/filter_catalog_test.dart` — alpha + facets  
- `packages/manifest/test/group_catalog_test.dart` — new  
- `packages/manifest/test/extractors_test.dart` — exotic weapons + legendary armor  
- `packages/manifest/test/entity_bundle_test.dart` / offline — projection counts  
- `apps/windows_host/test/catalog_page_test.dart` — facet/group UI  
- `apps/web_host/test/…` — facet/group UI  

## Complexity Tracking

None beyond dual-shell UI duplication (required by D-SHELL architecture).
