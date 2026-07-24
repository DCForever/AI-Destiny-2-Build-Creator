# Contract: Default Variant Composer

## UI shell

| Surface | Behavior |
|---------|----------|
| New build | Opens `DefaultVariantComposer` on **General** (draft). No `CreateBuildPanel`. |
| Tabs | General, Subclass, Armor & Mod Set, Weapon Set, **Finish** (always listed) |
| Tab lock | See `composerTabAccess` — blocked tabs non-activatable + reason |
| Non-default | Same tabs; no forced full create rituals |

## Tab contents (behavioral)

### General
- Synergy type multi-select (required to persist create)
- Class, subclass, pinned super, exotic armor (picker scoping per 042)
- Optional shared exotic weapon if product already supports on identity
- Artifact + perks for active variant (live mode)
- Soft guidance panel (read-only coaching)

### Subclass
- Groups: class ability, melee, grenade, movement | aspects, fragments
- Capacity / legality same as current VariantEditPanel

### Armor & Mod Set
- Sub-paths: **Reuse** | **Create**
- Reuse: class-constrained armor set list + mod set list; live attach; optional **Improve kit**
- Create: bonuses + Optimize workspace; confirm → create-set-attach with name + conceptTags; mod set attach/create

### Weapon Set
- Sub-paths: **Reuse** | **Create**
- Reuse: weapon sets attach
- Create: Primary / Secondary / Heavy catalog search; synergy-matching rows first + indicator

### Finish
- Always visible
- Lists missing completeness reasons from finish gaps when incomplete
- Equip / DIM disabled until complete **and** equip-ready; show pin/wishlist status
- Must not be sole path to create sets

## composerTabAccess (pure)

```ts
type ComposerTab = "general" | "subclass" | "armor" | "weapon" | "finish";

function composerTabAccess(input: {
  tab: ComposerTab;
  className: string | null;
  subclassName: string | null;
  buildId: string | null;
}): { allowed: boolean; reason?: string }
```

| tab | allowed when |
|-----|----------------|
| general, finish | always |
| subclass | class set ∧ subclass set |
| armor, weapon | class set (UI open); mutating attach requires buildId (separate guard) |

## finishMissingReasons (pure)

Input: `FinishGapsResult` (+ optional equipReady pin summary)  
Output: ordered human-readable strings for Finish tab (e.g. "Armor set missing", "Weapon slots empty").

## API — create-set-attach (extension)

`POST /api/user/builds/:buildId/create-set-attach`

Existing body plus behavior:

| Field | Behavior |
|-------|----------|
| `name` | Optional; if omitted, server generates from build name + set type |
| `conceptTags` | Optional override; if omitted on armor create-from-composer, derive from build synergy designations per data-model mapping |
| `type`, `variantId`, `attachNow` | Unchanged |

Response unchanged shape: `{ set, attachment }`.

## API — unchanged consumers

| API | Use |
|-----|-----|
| `POST /api/user/builds` | First persist from General draft |
| `PATCH` build / variant | Identity, kit, attachments |
| `GET /api/user/sets` | Reuse lists |
| Optimize routes used by FinishArmorOptimizeWorkspace | Create/Improve |
| Equip / DIM routes | Finish tab actions |
| Manifest/catalog search | Weapon/armor fills |

## Non-goals

- New multi-tenant APIs
- Changing equip-ready math
- LLM tabs
- Forced Improve after Reuse
