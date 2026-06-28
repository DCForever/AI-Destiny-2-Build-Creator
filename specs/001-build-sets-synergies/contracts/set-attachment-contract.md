# Contract: Set Attachment and Variant Composition

**Type**: Internal API + UI contract (P3, P6)

## Equipment Slot Enum

```ts
type WeaponSlot = 'primary' | 'special' | 'heavy';
type ArmorSlot = 'helmet' | 'arms' | 'chest' | 'legs' | 'class_item';
type PairSlot = 'exotic_weapon' | 'exotic_armor';
type EquipmentSlot = WeaponSlot | ArmorSlot | PairSlot;
```

## Set Types and Allowed Slots

```ts
type SetType = 'weapon' | 'armor' | 'mod' | 'pair' | 'fashion';

const SLOTS_BY_SET_TYPE: Record<SetType, EquipmentSlot[] | 'mods_only' | 'cosmetic'> = {
  weapon: ['primary', 'special', 'heavy'],
  armor: ['helmet', 'arms', 'chest', 'legs', 'class_item'],
  mod: 'mods_only',
  pair: ['exotic_weapon', 'exotic_armor'],
  fashion: 'cosmetic',
};
```

## SetItem Shape

```ts
type SetItemInput = {
  slot: EquipmentSlot;
  itemHash: number;
  selectedPerks?: number[];
  masterworkHash?: number;
  modHashes?: number[];
};

type SetItem = SetItemInput & {
  id: string;
  setId: string;
  itemName: string;
  removedAt?: string | null;
};
```

**Replace rule**: `PUT /api/user/sets/:id/items` with occupied `slot` → returns `409` with `{ code: 'SLOT_OCCUPIED', confirmRequired: true }` unless `?confirm=true` (FR-027).

## Set and Build Input Shapes

```ts
import type { ConceptTagId } from '@/data/conceptTags';

type SetInput = {
  name: string;
  type: SetType;
  tagIds: ConceptTagId[]; // zero or more; validated against vocabulary
};

type BuildInput = {
  name: string;
  className: 'Titan' | 'Hunter' | 'Warlock';
  subclass: GeneratedBuild['subclass']; // zod-validated
  exoticArmorHash: number;
  synergyIds: string[]; // min 1
  tagIds?: ConceptTagId[];
};

type BuildVariantInput = {
  name: string;
  isDefault?: boolean;
  exoticWeaponHash?: number | null;
  attachments: SetAttachmentInput[];
};

type SetAttachmentInput = {
  setId: string;
  mode: 'live' | 'snapshot'; // default live
};
```

## Attachment Stored Shape

```ts
type VariantSetAttachment = {
  id: string;
  variantId: string;
  setId: string;
  mode: 'live' | 'snapshot';
  snapshotConfigs?: Array<{
    slot: EquipmentSlot;
    itemHash: number;
    selectedPerks?: number[];
    masterworkHash?: number;
  }> | null;
  attachedAt: string;
};
```

## Validation Responses

| Code | When |
|------|------|
| `SLOT_CONFLICT` | Two attached sets claim same logical equipment slot (FR-026) |
| `PAIR_ARMOR_MISMATCH` | Pair exotic armor ≠ build exotic armor (FR-028) |
| `VARIANT_EMPTY` | No equipment slots filled (FR-025) |
| `NO_SYNERGY` | Build has zero designated synergies (FR-024) |
| `SET_IN_USE` | Delete set while attached; body includes `{ buildIds, variantIds }` (FR-017) |
| `DUPLICATE_SET_NAME` | Same name within set type for user (FR-005) |
| `INVALID_TAG` | Unknown or invalid concept tag id (FR-029) |

## List/Filter API (Sets and Builds)

```ts
// GET /api/concept-tags — returns CONCEPT_TAGS grouped by facet
// GET /api/user/sets?tags=solar,melee&type=armor
// GET /api/user/builds?tags=solar,melee

type TagFilterQuery = {
  tags?: ConceptTagId[]; // AND semantics — entity must have all listed tags
  type?: SetType;        // sets only
};
```

Repository: intersect `set_id` / `build_id` per tagId in junction tables, then join parent entity scoped by userId.

## Slot Resolution Algorithm (service contract)

1. Load build (exotic armor) + variant (exotic weapon) + attachments (live resolve or snapshot).
2. For each attachment, expand set items to slot map (fashion skipped).
3. Apply variant `exoticWeaponHash` to appropriate weapon slot from manifest bucket.
4. Apply build `exoticArmorHash` to armor slot from manifest.
5. Pair Set: validate armor match; apply weapon from pair.
6. If any slot has >1 claimant → `SLOT_CONFLICT`.
7. Return `ResolvedVariantEquipment` for sheet UI.

## UI: SetAttachPicker (extends prior contract)

- Props: `build`, `variant`, `availableSets`, `attachments`, `onAttach`, `onDetach`, `onModeChange`
- Props add: `tagFilter: ConceptTagId[]`, `onTagFilterChange`, `filteredSets`
- **TagFilterBar** above set list: multi-select from vocabulary; AND semantics; match count + empty state ("No sets match Solar · Melee")
- Pair attach: pre-validate armor match; show error inline if mismatch.
- Conflict panel: list conflicting slots and owning sets before save.
- Synergy picker on build form: multi-select; no primary badge (equal weight).

Shared components: `ConceptTagPicker` (assign on create/edit), `TagFilterBar` (filter on list/attach).

## Suggestion Context Payload

```ts
type SuggestionContext = {
  build: Pick<Build, 'subclass' | 'exoticArmorHash'>;
  variant: Pick<BuildVariant, 'exoticWeaponHash'>;
  synergies: Synergy[]; // all designated, equal weight
  attachedSetTags: ConceptTagId[];
  buildTagIds?: ConceptTagId[];
};
```

Explicit suggest endpoint accepts optional `goal: string` plus `SuggestionContext`.

See [data-model.md](../data-model.md) and [quickstart.md](../quickstart.md).
