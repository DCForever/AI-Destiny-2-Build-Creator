# Implementation Plan: DART-068 Presentation Shell / Loadouts / Settings

**Branch**: `dart-068-presentation-shell-loadouts-settings` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-068-presentation-shell-loadouts-settings/spec.md`

## Summary

Close P9 host UI fidelity polish residuals: AppShell label/order parity; catalog/set-fill icons + dense meta; loadout color bar/swatch/exotic names/details expand; Settings READY/entity chips + inventory ONLINE/Refresh chrome; designation Verb/Element chrome; variant read-only icon overview. Soft never auto-applies; no CLIENT_SECRET; **not** cutover re-gate.

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: Flutter (Windows), Jaspr (web), destiny2_bungie, destiny2_app, destiny2_manifest, destiny2_sandbox_data  

**Storage**: No schema change  

**Testing**: `dart test` packages/bungie + packages/app; Flutter windows_host tests; Jaspr web_host tests  

**Target Platform**: Flutter Windows + Jaspr web (mobile nav matrix unchanged)  

**Project Type**: Multiplatform monorepo (Melos)  

**Constraints**: Soft never auto-applies; pure Dart I/O; no CLIENT_SECRET; not cutover re-gate  

**Scale/Scope**: Presentation GAPs only; ≤ ~20 tasks

## Constitution Check

- I. Small Testable Increments: shell, catalog icons, loadouts, settings, designation/variant independently testable.
- II. Test-First: pure helpers + host tests with fixture data.
- III. Green Commit Checkpoints: package then host tests before merge.
- Soft/hard: no soft auto-apply paths introduced.

## Project Structure

### Documentation (this feature)

```text
specs/dart-068-presentation-shell-loadouts-settings/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code (planned)

```text
packages/bungie/lib/src/
  profile/loadout_exotics.dart      # resolveLoadoutExoticsFromInstances
  sync/format_last_sync.dart        # formatLastSyncLabel / ONLINE helpers
  profile/character_loadouts.dart   # bungieContentUrl (existing)
packages/app/lib/src/
  catalog_dense_meta.dart           # buildCatalogDenseMetaChips
  designation_chrome.dart           # human Verb/Element labels
  manifest_readiness.dart           # READY/STALE/NOT DOWNLOADED
apps/windows_host/lib/
  app.dart                          # nav order/labels
  catalog/catalog_page.dart         # icons + meta chips
  sets/set_catalog_picker.dart      # icons + meta
  sets/sets_library_page.dart       # filled row icon
  loadouts/loadouts_page.dart       # color bar, expand, exotic names
  loadouts/loadouts_controller.dart # exotic enrich hook
  settings/inventory_sync_card.dart # ONLINE + human last sync + Refresh
  settings/settings_page.dart       # Manifest READY + chips
  synergies/synergy_designation.dart + library page chrome
  builds/builds_library_page.dart   # variant overview strip
apps/web_host/lib/
  components/shell_header.dart
  pages/catalog_page.dart
  loadouts/loadouts_page.dart
  settings/inventory_sync_card.dart
  synergies/* designation chrome
  builds/* variant overview
```

## Implementation approach

### Phase A — Pure helpers

1. Loadout exotic resolution (Next parity) + enrich list helper.
2. formatLastSyncLabel + inventory online flag.
3. Catalog dense meta chips (definition-oriented).
4. Designation chrome formatter (Verb:/Element:).
5. Manifest readiness label helper.

### Phase B — Shell

1. Windows navLabels + NavigationRail destinations reorder.
2. Jaspr ShellHeader.routes reorder + labels.
3. Update host nav tests.

### Phase C — Catalog / sets / variant / designation

1. Icon leading widget (network with fallback) + dense chips on catalog + set picker + set detail filled row.
2. Variant read-only overview strip on Windows (+ Jaspr if compose exposes pins).
3. Designation display on synergy list/detail.

### Phase D — Loadouts + Settings

1. Loadout tile: color bar, swatch, icon plate, exotic line, expand.
2. Controller optional enrich from inventory + catalog.
3. Manifest READY chips; inventory ONLINE/human last sync/Refresh status (Windows + Jaspr inventory).

### Phase E — Docs + merge

1. Close GAP rows; roadmap DART-068 done; Current pointer (P9 complete / next note).
2. Merge to feature/multiplatform-dart.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Nav order breaks IndexedStack tests | Centralize navLabels + index map; update all find.text taps |
| Network images flaky in tests | Prefer Key presence + errorBuilder; mock not required if Icon fallback |
| Exotic enrich needs inventory | Optional injector; pure unit tests cover resolution |

## Complexity Tracking

None — presentation only; reuses bungieContentUrl and existing models.
