# Implementation Plan: DART-063 Catalog Universal Modes, Synergy Tags, Owned Detail

**Branch**: `dart-063-catalog-universal-modes-synergy-tags` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-063-catalog-universal-modes-synergy-tags/spec.md`

## Summary

Close catalog fidelity gaps on Windows Flutter + Jaspr: Weapons|Armor|Universal kind modes with kind-appropriate facets; Universal Set/Synergy composition CTAs (no Build kit attach); library synergy membership filter + BR-SYN-004 reverse tags on detail; human-readable owned instance perk/trait cards and armor base-stat board when inventory data is resolvable.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_manifest`, `destiny2_db`, `destiny2_app`, Flutter Windows host, Jaspr web host  

**Storage**: Drift inventory + synergies; entity stores / prebuilt bundles  

**Testing**: `dart test` packages; Flutter widget tests; Jaspr component tests  

**Target Platform**: Windows Flutter + Jaspr web  

**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no cutover re-gate  

## Constitution Check

- I. Small Testable Increments: US1–US5 independently testable  
- II. Test-First: pure mode/composition/annotate/projection + reverse-lookup tests with implementation  
- III. Green Commit: package + host catalog tests green before merge  
- IV–V. Co-located package tests; exit criteria map  

## Project Structure

### Documentation (this feature)

```text
specs/dart-063-catalog-universal-modes-synergy-tags/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/manifest/lib/src/catalog/
  catalog_browse_mode.dart      # NEW Weapons|Armor|Universal filter
  composition_kinds.dart        # NEW composition kind + hitActions
  linked_synergies.dart         # NEW annotate linkedSynergyIds
  filter_options.dart           # mode-specific facet option helpers
packages/db/lib/src/repos/
  instance_projection.dart      # enrich plugs/stats presentation
  synergy_repository.dart       # findSynergiesByTarget / byItemHashes
packages/app/lib/src/
  synergy_use_cases.dart        # reverse-lookup wrappers + annotate helper
apps/windows_host/lib/catalog/catalog_page.dart
apps/web_host/lib/pages/catalog_page.dart
apps/*/lib/catalog/owned_catalog_bridge.dart  # synergy annotate on refresh
```

## Implementation approach

1. **Browse modes**: `CatalogBrowseMode` filters by `sourceStore`; hosts mode chips reset kind-inappropriate facets.
2. **Composition kinds**: Port subset of product `compositionKinds.ts` for Set/Synergy eligibility labels.
3. **Linked synergies**: Build itemHash → synergyId map from library links (`weapon`, `exotic_armor`); annotate base; wire `CatalogClientFilters.synergies`.
4. **Reverse tags**: DB `findSynergiesByTarget` / batch by itemHash; detail badges from selected item.
5. **Instance detail**: Projection carries socketPlugs/statValues/gearTier + `ResolvedPlugCard` when names available; hosts render cards/board.
6. **Universal actions**: Dialogs create set (with first slot fill) or synergy (with weapon/exotic_armor link) via use cases; no Build attach.
7. **Docs**: Close GAP rows; roadmap done.

## Risks / mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Perk-link membership incomplete without perk index | Document residual; itemHash primary for filter |
| Plug names missing offline on web | Show columnLabel + hash; never invent |
| Universal set wizard scope creep | Minimal create + fill path only |

## Test plan

- `packages/manifest/test/catalog_browse_mode_test.dart`
- `packages/manifest/test/composition_kinds_test.dart`
- `packages/manifest/test/linked_synergies_test.dart`
- `packages/db/test/synergy_reverse_lookup_test.dart`
- `packages/db/test/instance_projection_detail_test.dart` (or extend inventory tests)
- Host catalog mode/synergy/detail tests

## Complexity Tracking

Dual-shell UI duplication required by D-SHELL architecture.
