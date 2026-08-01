# Implementation Plan: DART-064 Build Identity, Subclass Kit, Manifest Pickers

**Branch**: `dart-064-build-identity-subclass-compose` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-064-build-identity-subclass-compose/spec.md`

## Summary

Close Build UI fidelity gaps on Windows Flutter + Jaspr: DBR-ID-008 identity Confirm/Fork gate in app use cases + host chrome; full subclass kit composer with capacity plain language; Manifest/catalog name search for exotic armor and Super; client hard-block UX for dual exotic / illegal kit; Jaspr named set attach + per-slot pins. Soft never auto-applies; no CLIENT_SECRET; cutover GO unchanged.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_app`, `destiny2_domain`, `destiny2_db`, `destiny2_manifest`, Flutter Windows host, Jaspr web host  

**Storage**: Drift builds/variants/attachments; OfflineCatalog / entity bundles for pickers  

**Testing**: `dart test` packages; Flutter widget tests; Jaspr component tests  

**Target Platform**: Windows Flutter + Jaspr web  

**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no cutover re-gate  

## Constitution Check

- I. Small Testable Increments: US1–US5 independently testable  
- II. Test-First: package identity/fork/hard-block + host tests with implementation  
- III. Green Commit: package + host build tests green before merge  
- IV–V. Co-located tests; exit criteria map  

## Project Structure

### Documentation (this feature)

```text
specs/dart-064-build-identity-subclass-compose/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/app/lib/src/
  build_use_cases.dart          # identityAction, confirm/fork, IDENTITY_CONFIRM_REQUIRED
  errors.dart                   # identityConfirmRequired code
  identity_change.dart          # NEW pure detect identity field changes
  compose_hard_blocks.dart      # NEW client hard-block aggregator + labels
packages/manifest/lib/src/catalog/
  manifest_search_picks.dart    # NEW name search filter for pickers
apps/windows_host/lib/builds/
  builds_library_controller.dart
  builds_library_page.dart
  subclass_kit_format.dart      # capacity plain language helpers
  manifest_pick_sheet.dart      # searchable pick sheet
apps/web_host/lib/builds/
  builds_controller.dart
  build_compose_page.dart       # identity/kit/pickers/named attach+pins
```

## Implementation approach

1. **Identity detect + gate**: pure `detectIdentityFieldChanges`; `UpdateBuildCommand.identityAction`; throw `IDENTITY_CONFIRM_REQUIRED` without action; confirm in-place; fork new build + snapshot variants.
2. **Subclass kit UI**: bind `SubclassKit` draft on selected build; capacity via aspect fragmentCapacity sum (catalog) or HardGatePorts; plain-language banners.
3. **Manifest pickers**: filter OfflineCatalog base by store/kind + query; host sheets/lists select name→hash.
4. **Client hard blocks**: pure merge of `evaluateExoticLimits` + `evaluateSubclassKit` (+ optional exotic ability if ports available); hosts disable hard-blocked Save; soft never disables.
5. **Jaspr attach**: dropdown/list of attachableSets by name; per-slot pin inputs for each `canEditPin` slot.
6. **Docs**: close GAP rows; roadmap done; pointer → DART-065.

## Risks / mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Class-item exotic mode needs slot lookup | Optional slot from catalog; default classic (any hash change = identity) |
| Fork attachment fidelity | Snapshot configs from active set items / existing snapshot (product parity) |
| Empty catalog offline | Empty picker state + secondary name field residual |
| Scope creep into Finish/optimizer | Explicitly out of scope (DART-067) |
