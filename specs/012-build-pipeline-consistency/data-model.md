# Data Model: Build Pipeline Consistency

**Feature**: 012-build-pipeline-consistency  
**Date**: 2026-07-08

No new persisted tables. This document clarifies **entities and client/debug state** used by the pipeline, and validation rules tightened for explicit synergy designation.

## Entities (existing)

### Build

| Field | Notes |
|-------|--------|
| `id`, `name`, `className` | Unchanged |
| `subclass` | JSON matching `GeneratedBuild.subclass` (name-based ability strings + aspects/fragments arrays + rationale) |
| `exoticArmorHash`, `exoticArmorName` | Hash is identity; name must come from catalog/manifest selection on happy path |
| `tagIds` | Concept tags (AND filter on lists) |
| `synergyIds` / designations | Junction `build_synergies`; **≥1 required** on create and whenever designations are updated |

**Relationships**: 1..* `BuildVariant`; *..* `Synergy` via designations; tags via junction.

### Build Variant

| Field | Notes |
|-------|--------|
| `id`, `buildId`, `name`, `isDefault` | Unchanged |
| `exoticWeaponHash`, `exoticWeaponName` | Optional per variant |
| `notes` | Optional |
| Attachments | Via `build_set_attachments` (`setId`, `mode: live\|snapshot`) |

**Client rule**: Debug UI always has an explicit `selectedVariantId` for variant-scoped actions.

### Set Attachment

| Field | Notes |
|-------|--------|
| `setId`, `mode` | live \| snapshot |
| Replace semantics | PATCH variant with `attachments[]` **replaces entire set** for that variant |

**Client rule**: Before PATCH, load current attachments from build detail, apply add/replace/remove in memory, send complete array.

### Synergy Designation

| Field | Notes |
|-------|--------|
| `synergyId` | Must exist for user |
| Multiplicity | ≥1 on build; equal weight for suggestions (001) |

**Create rule (012)**: Client MUST supply `synergyIds` with length ≥1. Server MUST NOT invent a designation when omitted.

### Debug Lookup (conceptual)

Not persisted. Represents a selection session:

| Attribute | Notes |
|-----------|--------|
| `entityKind` | `exotic_armor` \| `set` \| `synergy` \| `variant` \| (reuse item/perk/trait/bonus on other pages) |
| `query` / filters | Kind-specific (q, type, tags, className, …) |
| `results[]` | Must expose comparable identity: `id` or `hash`, `name`, plus `type`/`kind` when applicable; `description` when that kind already shows it elsewhere |
| `selection` | Chosen identity written into form state |

## Validation rules (012 deltas)

| Rule | Behavior |
|------|----------|
| Explicit synergies on create | Missing/empty `synergyIds` → `NO_SYNERGY` (400); no auto-pick |
| Synergy update | `synergyIds` present ⇒ min 1; unknown ids ⇒ `NO_SYNERGY` |
| Exotic from picker | Happy path sets both hash and catalog name together |
| Variant-scoped action | UI blocks if `selectedVariantId` empty |
| Pair attach | Existing `PAIR_ARMOR_MISMATCH` unchanged |
| Empty variant equipment | Existing `VARIANT_EMPTY` / save rules unchanged; surface in debug messages |

## State transitions (debug client)

```text
[No build] --create(pickers)--> [Build selected]
[Build selected] --load detail--> [Variants listed; default preselected visibly]
[Variant selected] --SetAttachPicker confirm--> [Attachments updated via full replace PATCH]
[Build selected] --SynergyMultiSelect save--> [Designations replaced via PATCH build]
[Variant selected] --resolve/compare/suggest--> [JSON panel; same variantId]
```

## Out of scope for persistence

- Server-side “active variant”
- Hash-based subclass ability references
- New set/synergy tables
