# Data Model: DART-020 Flutter Catalog Offline

## CatalogItem

Unified browse row (inventory-agnostic for this slice).

| Field | Type | Notes |
| ----- | ---- | ----- |
| hash | int | Item definition hash |
| name | string | Display name |
| icon | string? | Relative icon path if known |
| slot | string? | Weapon slot or armor slot label |
| element | string? | Element label |
| ammo | string? | Primary/Special/Heavy (weapons) |
| itemTypeName | string? | e.g. Hand Cannon; ability kind for abilities |
| frame | string? | Weapon frame or armor archetype |
| classType | string? | Titan/Hunter/Warlock |
| description | string? | Search/display projection |
| isExotic | bool | Weapons: not used as exotic store yet — exotic armor true; weapons false unless name/store implies; MVP weapons store is general weapons (isExotic false unless we detect later) |
| owned | bool | **Always false** (DART-020) |
| ownedCount | int | **Always 0** (DART-020) |
| sourceStore | string | Optional: weapons / exotic-armor / … for debugging UI |

### isExotic projection rules (MVP)

| Store | isExotic |
| ----- | -------- |
| exotic-armor | true |
| weapons | false (MVP store does not split exotic weapons) |
| aspects / fragments / abilities / mods | false |

## FacetFilter

```text
include: List<String>  // OR within dimension
exclude: List<String>  // any match drops
```

## CatalogClientFilters

| Field | Semantics |
| ----- | --------- |
| query | Free-text AND after facets |
| slots / elements / ammos / archetypes / classNames | FacetFilter or legacy List&lt;String&gt; as include-only |
| exotic | true = only exotic; false = exclude exotic; null = off |
| synergies / itemHashesInclude / itemHashesExclude | Optional pure API; UI optional |

## OfflineCatalog load result

| Field | Meaning |
| ----- | ------- |
| version | Entity cache version or null |
| items | Full projected base list |
| error | Optional load error message |
| emptyReason | none / no_version / no_stores |

## Filter composition

- Across dimensions: **AND**
- Within include: **OR**
- Exclude: drop on any match
- Free-text: further AND
