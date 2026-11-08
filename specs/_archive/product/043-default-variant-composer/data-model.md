# Data Model: 043-default-variant-composer

No new SQLite tables. Composer is an interaction layer over existing entities.

## Entities (existing)

### Build
- Identity: class, subclass tree, exotic armor, shared exotic weapon, pinned Super, designated synergy types
- Relationships: has many Variants; default variant flagged `isDefault`

### BuildVariant
- Fields: name, notes, artifact + config, attachments[], slot overrides / resolved equipment
- Modes: default vs non-default (equip-with-gaps)

### Set attachment
- `setId`, `mode` (`live` | `snapshot`), optional snapshot configs
- Types: weapon | armor | mod | pair | fashion

### Set (library)
- `name`, `type`, `conceptTags[]`, items/slots
- Create-from-composer may set name + conceptTags from build synergies

### Finish gap (derived, not stored)
- Categories: armor / weapons / mods (see `finishGaps`)
- Statuses: needs_set | needs_fill | capture_available | ok | skipped

### Equip readiness (derived)
- Per applied combat slot: wishlist | pinned | stale
- `equipReady` iff all applied combat slots pinned

## Composer session state (client)

| Field | Meaning |
|-------|---------|
| `mode` | `draft` (no buildId) \| `live` (persisted) |
| `activeTab` | general \| subclass \| armor \| weapon \| finish |
| `armorSubPath` | reuse \| create |
| `weaponSubPath` | reuse \| create |
| `className` / `subclassName` | Gate inputs |
| `buildId` / `variantId` | Null in draft |
| General form draft | Synergies, exotic, super, name, artifact… |

## Validation rules (unchanged domain)

- Save build without synergy designations → `NO_SYNERGY`
- Illegal subclass kit / mod capacity / exotic limits → hard block
- Soft guidance never mutates pins
- Equip/DIM require equip-ready (+ Finish completeness for default)

## State transitions

```text
New build
  → draft composer (General)
  → [valid General save] create build + default variant
  → live composer (all tabs per gates)
  → attach/create sets, fill kit
  → finishGaps.complete
  → equip-ready pins
  → equip / DIM
```

```text
Tab access
  General, Finish: always
  Subclass: class ∧ subclass
  Armor, Weapon: class ∧ (attach actions need buildId)
```

## Mapping: synergy designations → concept tags

- Prefer exact id match when designation equals a known `CONCEPT_TAGS` id/label
- Otherwise omit tag (do not invent freeform identity)
- Tags are filter metadata only (not build identity)
