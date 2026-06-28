# Contract: Set Attachment and Variant Composition

**Type**: Internal API + UI contract (P3, P6)

**Business rules**: [../../business-rules.md](../../business-rules.md)

## Equipment Slot Enum

**Rules**: BR-SET-002, BR-SLOT-001–003 — [FR-020](../spec.md#functional-requirements)

```ts
type WeaponSlot = 'primary' | 'special' | 'heavy';
type ArmorSlot = 'helmet' | 'arms' | 'chest' | 'legs' | 'class_item';
type PairSlot = 'exotic_weapon' | 'exotic_armor';
type EquipmentSlot = WeaponSlot | ArmorSlot | PairSlot;
```

## Set Types and Allowed Slots

**Rules**: BR-SET-002, BR-FASH-003 — [FR-003](../spec.md#functional-requirements), [FR-018](../spec.md#functional-requirements), [FR-020](../spec.md#functional-requirements)

```ts
type SetType = 'weapon' | 'armor' | 'mod' | 'pair' | 'fashion';

const SLOTS_BY_SET_TYPE: Record<SetType, EquipmentSlot[] | 'mods_only' | 'cosmetic'> = {
  weapon: ['primary', 'special', 'heavy'],
  armor: ['helmet', 'arms', 'chest', 'legs', 'class_item'],
  mod: 'mods_only',
  pair: ['exotic_weapon', 'exotic_armor'],
  fashion: 'cosmetic', // BR-FASH-003: excluded from slot resolution
};
```

## SetItem Shape

**Rules**: BR-ROLL-001, BR-ROLL-005 — [FR-019](../spec.md#functional-requirements), [FR-020](../spec.md#functional-requirements)

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
  removedAt?: string | null; // BR-ROLL-002: soft-remove retains roll history
};
```

**Replace rule** (**BR-SLOT-006**, [FR-027](../spec.md#functional-requirements)): `PUT /api/user/sets/:id/items` with occupied `slot` → returns `409` with `{ code: 'SLOT_OCCUPIED', confirmRequired: true }` unless `?confirm=true`.

## Set and Build Input Shapes

**Rules**: BR-TAG-001, BR-TAG-004–006, BR-TAG-005 — [FR-004](../spec.md#functional-requirements), [FR-005](../spec.md#functional-requirements), [FR-029](../spec.md#functional-requirements), [FR-030](../spec.md#functional-requirements)

```ts
import type { ConceptTagId } from '@/data/conceptTags';

type SetInput = {
  name: string; // BR-TAG-002: user-defined, separate from tags
  type: SetType;
  tagIds: ConceptTagId[]; // BR-TAG-005: multi-select; BR-TAG-001: validated vocabulary
};

type BuildInput = {
  name: string;
  className: 'Titan' | 'Hunter' | 'Warlock';
  subclass: GeneratedBuild['subclass']; // BR-VAL-001: zod-validated
  exoticArmorHash: number;
  synergyIds: string[]; // BR-SAVE-003: min 1
  tagIds?: ConceptTagId[]; // BR-TAG-006
};

type BuildVariantInput = {
  name: string;
  isDefault?: boolean;
  exoticWeaponHash?: number | null; // BR-BLD-004
  attachments: SetAttachmentInput[];
};

type SetAttachmentInput = {
  setId: string;
  mode: 'live' | 'snapshot'; // BR-ATT-002: default live
};
```

## Attachment Stored Shape

**Rules**: BR-ATT-002, BR-ATT-004 — [FR-009](../spec.md#functional-requirements)

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

| Code | Rule ID | When | FR |
|------|---------|------|-----|
| `SLOT_CONFLICT` | BR-CONF-003 | Two attached sets claim same logical equipment slot | [FR-026](../spec.md#functional-requirements) |
| `PAIR_ARMOR_MISMATCH` | BR-PAIR-002 | Pair exotic armor ≠ build exotic armor | [FR-028](../spec.md#functional-requirements) |
| `VARIANT_EMPTY` | BR-SAVE-004 | No equipment slots filled | [FR-025](../spec.md#functional-requirements) |
| `NO_SYNERGY` | BR-SAVE-003 | Build has zero designated synergies | [FR-024](../spec.md#functional-requirements) |
| `SET_IN_USE` | BR-DEL-004 | Delete set while attached; body includes `{ buildIds, variantIds }` | [FR-017](../spec.md#functional-requirements) |
| `DUPLICATE_SET_NAME` | BR-TAG-004 | Same name within set type for user | [FR-005](../spec.md#functional-requirements) |
| `INVALID_TAG` | BR-TAG-003 | Unknown or invalid concept tag id | [FR-029](../spec.md#functional-requirements) |
| `SLOT_OCCUPIED` | BR-SLOT-006 | Occupied slot overwrite without confirm | [FR-027](../spec.md#functional-requirements) |

## List/Filter API (Sets and Builds)

**Rules**: BR-TAG-007, BR-TAG-008 — [FR-031](../spec.md#functional-requirements), [FR-032](../spec.md#functional-requirements)

```ts
// GET /api/concept-tags — BR-TAG-001 / FR-029
// GET /api/user/sets?tags=solar,melee&type=armor
// GET /api/user/builds?tags=solar,melee

type TagFilterQuery = {
  tags?: ConceptTagId[]; // BR-TAG-007: AND semantics
  type?: SetType;        // sets only
};
```

Repository: intersect `set_id` / `build_id` per tagId in junction tables, then join parent entity scoped by userId.

## Slot Resolution Algorithm (service contract)

**Rules**: BR-FASH-003, BR-PAIR-001–003, BR-CONF-001–003 — [FR-018](../spec.md#functional-requirements), [FR-026](../spec.md#functional-requirements), [FR-028](../spec.md#functional-requirements)

1. Load build (exotic armor) + variant (exotic weapon) + attachments (live resolve or snapshot).
2. For each attachment, expand set items to slot map (**BR-FASH-003**: fashion skipped).
3. Apply variant `exoticWeaponHash` to appropriate weapon slot from manifest bucket (**BR-BLD-004**).
4. Apply build `exoticArmorHash` to armor slot from manifest (**BR-BLD-003**).
5. Pair Set: validate armor match (**BR-PAIR-001**); apply weapon from pair (**BR-PAIR-003**).
6. If any slot has >1 claimant → `SLOT_CONFLICT` (**BR-CONF-003**).
7. Return `ResolvedVariantEquipment` for sheet UI.

## UI: SetAttachPicker (extends prior contract)

**Rules**: BR-ATT-001–002, BR-TAG-007–009 — [FR-009](../spec.md#functional-requirements), [FR-032](../spec.md#functional-requirements)

- Props: `build`, `variant`, `availableSets`, `attachments`, `onAttach`, `onDetach`, `onModeChange`
- Props add: `tagFilter: ConceptTagId[]`, `onTagFilterChange`, `filteredSets`
- **TagFilterBar** (**BR-TAG-008**): multi-select from vocabulary; **BR-TAG-007** AND semantics; match count + empty state ("No sets match Solar · Melee" — **BR-TAG-009**)
- Pair attach: pre-validate armor match (**BR-PAIR-001**); show error inline if mismatch.
- Conflict panel: list conflicting slots and owning sets before save (**BR-CONF-002**).
- Synergy picker on build form: multi-select; no primary badge (**BR-SYN-003**).

Shared components: `ConceptTagPicker` (**BR-TAG-005**), `TagFilterBar` (**BR-TAG-008**).

## Suggestion Context Payload

**Rules**: BR-SUG-004, BR-TAG-010, BR-SYN-003 — [FR-010](../spec.md#functional-requirements), [FR-016](../spec.md#functional-requirements), [FR-024](../spec.md#functional-requirements)

```ts
type SuggestionContext = {
  build: Pick<Build, 'subclass' | 'exoticArmorHash'>;
  variant: Pick<BuildVariant, 'exoticWeaponHash'>;
  synergies: Synergy[]; // BR-SYN-003: all designated, equal weight
  attachedSetTags: ConceptTagId[]; // BR-TAG-010
  buildTagIds?: ConceptTagId[];
};
```

Explicit suggest endpoint accepts optional `goal: string` plus `SuggestionContext`.

See [data-model.md](../data-model.md), [quickstart.md](../quickstart.md), and [business-rules.md](../../business-rules.md).
