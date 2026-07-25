# Research: DART-028 App Use Cases Build

**Date**: 2026-07-24

## Product save pipeline (TS)

Source: `src/lib/builds/buildService.ts`

### Create build order

1. Normalize synergy designations → `assertTypesPresent` (`NO_SYNERGY`)
2. `assertSubclassKitLegal` (entity aspects for fragment capacity)
3. `assertExoticAbilityPins` (sandbox exotic ability table + pure match)
4. Insert build + default variant
5. If default attachments present → `prepareAttachments` + `validateVariantSave`; on failure **delete build** (R2)

### Update variant equipment order (`validateVariantSave`)

1. Load build/variant/attachments
2. `resolveVariantEquipment` (expand attachments; fashion skip)
3. `assertNoSlotConflicts`
4. `assertExoticLimits` (entity exotic stores + claim sources)
5. `assertModEnergyForAttachments`
6. If `variant.isDefault` → `assertFullCombatLoadout` (weapons + armor + class + subclass + mods)

**Not in save path:** soft coverage (`coverageService` is a separate query). Soft stat targets never hard-block.

## Dart pure surface already available

| Concern | Domain API |
| ------- | ---------- |
| Exotic limits | `evaluateExoticLimits` |
| Subclass kit | `evaluateSubclassKit` |
| Mod energy | `evaluateModEnergy` |
| Exotic ability | `evaluateExoticAbilityMatch` |
| Synergy required | `evaluateSynergyRequirement` |
| Resolve/conflicts/completeness | `resolveVariantClaims`, `assertNoSlotConflicts`, `assertFullCombatLoadout` |
| Soft coverage | `evaluateCoverage` |

## Decisions

| Topic | Decision |
| ----- | -------- |
| Soft in save? | **No** — query use case only |
| Manifest in app package? | **No** — ports with defaults; host wires entity cache later |
| Empty default on create | **Allowed** (product staged pipeline) |
| Non-default completeness | **Not** full combat; soft misses never block |
| Sandbox ability table | Default port via `destiny2_sandbox_data` |

## Open follow-ons (not this slice)

- Wire `HardGatePorts` from Flutter host using `destiny2_manifest` adapters (post DART-028 UI slices)
- Identity fork confirm UX (product `IDENTITY_CONFIRM_REQUIRED`) — can soft-land as optional later; not required for exit criteria
