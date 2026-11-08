# Contract: Debug Lookup Parity

**Feature**: 012-build-pipeline-consistency  
**Type**: Debug UI / shared picker contract  
**Related**: [debug-service-contract.md](../../001-build-sets-synergies/contracts/debug-service-contract.md), [spec.md](../spec.md) FR-010–FR-013

## Purpose

Define the **minimum lookup capabilities and result identity fields** each debug surface must provide for shared entity kinds, so Builds/Sets/Synergies/Catalog stay consistent on the happy path.

## Discovery model (all kinds)

```text
search / filter → result list → select → form state updated
```

- Empty results → explicit empty state (no unrelated rows, no silent no-op).
- Errors → JSON panel / inline message with API `code` when present.
- Optional raw hash/ID fields → labeled **Advanced** and not required for happy-path scripts.

## Parity matrix

| Entity kind | Required filters / search | Result identity fields | Primary pages | Data source |
|-------------|---------------------------|------------------------|---------------|-------------|
| Exotic armor | `q` (name); class filter when available | `hash`, `name`, class/slot if known | Builds (create + list filter), Catalog | `GET /api/manifest/search?category=exotic-armor` and/or `GET /api/catalog/armor` |
| User set | `type`; `tags` (AND, comma-separated) | `id`, `name`, `type`, tag labels | Builds (attach), Sets (list) | `GET /api/user/sets?type=&tags=` |
| User synergy | `q` and/or `type` filter | `id`, `name`, `type` | Builds (designate), Synergies (list) | `GET /api/user/synergies` (+ existing type filter if present) |
| Build variant | Scoped to selected build | `id`, `name`, `isDefault` | Builds only | `GET /api/user/builds/:id` → `variants[]` |
| Catalog item / perk / trait / set bonus | Existing 008–011 / 006 behaviors | Existing fields + description where already shown | Sets, Synergies, Catalog | Existing catalog + synergy-picker routes |

## Shared components (implementation targets)

| Component | Owns |
|-----------|------|
| `ExoticArmorLookup` | Exotic armor search → `{ hash, name }` |
| `SynergyMultiSelect` | Multi-select designations → `synergyIds[]` |
| `SetAttachPicker` | type + tags + set + mode → attachment intent |
| `VariantSelect` | `selectedVariantId` |
| `SubclassStructuredForm` | Builds `subclass` object without raw JSON as primary path |

Pages MAY keep page-specific layout but MUST use these behaviors for the entity kinds above.

## Non-goals

- Identical CSS/layout across pages
- Production design system
- Changing catalog filter semantics beyond reuse
