# Implementation Plan: DART-066 Synergy Picker + Manage + Sets Library

**Branch**: `dart-066-synergy-picker-manage-sets-library` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-066-synergy-picker-manage-sets-library/spec.md`

## Summary

Close synergy picker/manage and sets library fidelity gaps on Windows Flutter + Jaspr: catalog evidence search with BR-SYN-011 omit-linked and BR-SYN-012 perk labels; Jaspr dual-pane manage; library filters; delete synergy; sets search+tag AND, readiness/Fill next/used-by, delete with SET_IN_USE. Soft never auto-applies; no CLIENT_SECRET; cutover GO unchanged.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_app`, `destiny2_domain`, `destiny2_db`, `destiny2_manifest`, `destiny2_sandbox_data`, Flutter Windows host, Jaspr web host  

**Storage**: Drift sets/synergies/attachments; OfflineCatalog entity rows  

**Testing**: `dart test` packages; Flutter widget tests; Jaspr controller tests  

**Target Platform**: Windows Flutter + Jaspr web  

**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no cutover re-gate  

## Constitution Check

- I. Small Testable Increments: US1–US8 independently testable  
- II. Test-First: pure helpers + host tests with implementation  
- III. Green Commit: package + host tests green before merge  
- IV–V. Co-located tests; exit criteria map  

## Project Structure

### Documentation (this feature)

```text
specs/dart-066-synergy-picker-manage-sets-library/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/app/lib/src/
  library_filters.dart              # filterSets / filterSynergies
  synergy_picker_presentation.dart  # coverage keys, omit-linked, perk labels, catalog→link
  set_library_presentation.dart     # readiness / fill-next / used-by labels
apps/windows_host/lib/synergies/
  synergies_library_controller.dart # filters, delete, catalog search
  synergies_library_page.dart       # search/filter chrome, picker, delete
apps/windows_host/lib/sets/
  sets_library_controller.dart      # filters, delete, readiness accessors
  sets_library_page.dart            # search/tags, readiness strip, delete
apps/web_host/lib/synergies/
  synergies_controller.dart         # full manage + filters + delete
  synergies_page.dart               # dual-pane manage + picker
apps/web_host/lib/sets/
  sets_controller.dart
  sets_page.dart
```

## Implementation approach

1. **Pure filters**: Port product `filterSets` / `filterSynergies` (query + type multi + tags AND / subtype AND).
2. **Pure synergy picker**: Port `coverageKeyFromLink`, `linkDedupeKey`, `filterOutLinkedWeapons/Items`, `formatWeaponPerkSourceLabel`; catalog search → `SynergyLinkWrite`.
3. **Pure set readiness**: filledCount, firstEmptySlot, readiness label, usedBy display lines.
4. **Controllers**: client-side filter state; deleteSelected wrapping use cases; catalog search API for evidence.
5. **Windows UI**: filter fields/chips; catalog search list for links; delete confirm; sets readiness + fill next + used-by + delete.
6. **Jaspr UI**: select opens detail; edit/save/links/delete; same sets features.
7. **Docs**: close GAP rows; roadmap done; pointer → DART-068.

## Risks / mitigations

| Risk | Mitigation |
| ---- | ---------- |
| No plug store for weapon_perk density | A1 residual free-text + hash; labels when source known |
| Tag labels missing | fall back to tag id; sandbox concept tags for chips |
| Scope into designation icons | Out of scope DART-068 |
