# Contract: Build Variant API

**Type**: REST-style internal API (`/api/user/builds`)

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/user/builds` | List builds with variant summaries |
| POST | `/api/user/builds` | Create build + default variant |
| GET | `/api/user/builds/:id` | Build detail + all variants |
| PATCH | `/api/user/builds/:id` | Update shared fields (subclass, exotic armor, synergies) |
| DELETE | `/api/user/builds/:id` | Delete build and variants |
| POST | `/api/user/builds/:id/variants` | Add variant |
| PATCH | `/api/user/builds/:id/variants/:variantId` | Update variant attachments / exotic weapon |
| DELETE | `/api/user/builds/:id/variants/:variantId` | Delete variant (not if sole default) |
| GET | `/api/user/builds/:id/variants/:variantId/resolved` | Resolved equipment slot map |
| POST | `/api/user/builds/:id/variants/:variantId/suggest-sets` | Explicit set suggestions |

All routes require authenticated user (same pattern as `/api/user/loadouts`).

## Create Build Request

```ts
type CreateBuildRequest = {
  name: string;
  className: 'Titan' | 'Hunter' | 'Warlock';
  subclass: object; // generatedBuildSchema.subclass
  exoticArmorHash: number;
  synergyIds: string[]; // min length 1
  tagIds?: ConceptTagId[];
  defaultVariant: {
    name?: string; // default "Default"
    exoticWeaponHash?: number;
    attachments?: SetAttachmentInput[];
  };
};
```

**Response**: `201` with full build + default variant if save validation passes.

## List / Filter Query Params

- `exoticArmorHash` — filter builds sharing exotic armor (FR-015)
- `exoticWeaponHash` — filter variants by weapon
- `synergyId` — filter builds designating synergy
- `tags` — comma-separated concept tag ids; **AND semantics** (FR-031)

## Variant Compare Response

```ts
type VariantCompare = {
  shared: {
    exoticArmor: { hash: number; name: string };
    subclass: object;
    synergies: Synergy[];
  };
  variants: Array<{
    id: string;
    name: string;
    exoticWeapon?: { hash: number; name: string };
    attachments: VariantSetAttachment[];
    diffSlots: EquipmentSlot[]; // slots differing from default variant
  }>;
};
```

## Error Shape

```ts
type ApiError = {
  error: string;
  code: string;
  details?: Record<string, unknown>;
};
```

Validation uses zod at route boundary (constitution V).
