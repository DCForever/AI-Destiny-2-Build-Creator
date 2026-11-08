# Contract: Default Loadout Completeness & Naming

**Feature**: 015-build-identity  
**Type**: Validation + naming  
**Related**: [data-model.md](../data-model.md), [resolveVariant.ts](../../../src/lib/builds/resolveVariant.ts)

## Purpose

Enforce **full combat loadout** on the **default** variant and define **default name** generation + **per-class uniqueness**.

## Default variant completeness

When saving/updating a variant with `isDefault: true` (create-with-attachments, update variant, duplicate-as-default paths that validate save):

### Required after resolve

| Category | Requirement |
|----------|-------------|
| Weapons | Non-empty claims: `primary`, `special`, `heavy` |
| Armor | Non-empty claims: `helmet`, `arms`, `chest`, `legs`, `class_item` |
| Subclass | Build has `className` and a populated `subclass` kit object |
| Mods | At least one Mod Set attached to the variant **or** attached gear carrying `modHashes` |

### Failure

```json
{
  "error": "DEFAULT_VARIANT_INCOMPLETE",
  "missing": ["special", "mods"]
}
```

### Non-default variants

May save with any subset of slots empty (including fully empty). Do **not** apply `assertVariantNotEmpty` ≥1-slot rule.

### Create without attachments

Empty default at create remains allowed (012 behavior); completeness is enforced when the default is saved with composition / marked complete via attachment update paths that run `validateVariantSave`.

## Default name generation

### Segments (in order, omit if missing)

1. Class (`className`)
2. Element (from subclass tree / element field used by project)
3. Super (`pinnedSuper` if set, else `subclass.super`)
4. Exotic Armor name/hash label if `exoticArmorHash` set
5. Exotic Weapon name/hash label if build-shared weapon set, else default variant weapon if present at name time
6. Synergy names (designated)

No `"None"` placeholders. Joiner: space or ` · ` (implementation chooses one; tests lock it).

### Create

- If `name` omitted or whitespace-only → server sets derived name.
- If `name` provided → use as-is subject to uniqueness.

### Uniqueness

Within `(userId, className)`, names MUST be unique.

```json
{ "error": "DUPLICATE_BUILD_NAME", "className": "Warlock", "name": "Ionic Trace Kit" }
```

Same display name on Titan vs Warlock is allowed.
