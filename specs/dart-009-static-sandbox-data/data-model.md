# Data Model: DART-009 Static Sandbox Data

## Enums / wire names

| Type | Wire values |
| ---- | ----------- |
| ArmorStatName | Health, Melee, Grenade, Super, Class, Weapons |
| SynergyElement | Kinetic, Solar, Arc, Void, Stasis, Strand, Prismatic |
| ChampionType | Barrier, Overload, Unstoppable |
| ConceptTagFacet | activity, element, playstyle, role |
| GuardianClass | Titan, Hunter, Warlock |

## Core tables

### StatBenefitDefinition

- `stat`, `baseEffects`, `baseScaling[]`, `enhancedScaling[]`, `enhancedNotes`
- ScalingBenefit: `template` with `{v}`, `max`, optional `precision`
- Constants: `STAT_MAX=200`, `ENHANCED_THRESHOLD=100`

### SynergyVerbEntry

- `name`, `description`, `element` (nullable)
- Aliases map free text → canonical name

### ExoticAbilityRequirement

- optional `hash`, required `name`, optional ability pins (super/melee/grenade/classAbility)
- Lookup: hash wins over case-insensitive name

### ArmorArchetype

- `name`, `primary`, `secondary`, `addedIn970`

### FrameOverrideRule / champion maps

- Base family → ChampionType
- Frame override rules (frame prefix + optional weapon type)
- Subclass verb counters + damage buffs

### ConceptTag

- `id`, `label`, `facet`

### AbilityTiming

- optional cooldownSeconds, durationSeconds, charges

### SubclassesByClass

- Titan / Hunter / Warlock → ordered subclass display names
