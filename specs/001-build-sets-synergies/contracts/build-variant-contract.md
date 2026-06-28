# Contract: Build Variant API

**Type**: REST-style internal API (`/api/user/builds`)

**Business rules**: [../../business-rules.md](../../business-rules.md)

## Endpoints

| Method | Path | Purpose | Rule IDs |
|--------|------|---------|----------|
| GET | `/api/user/builds` | List builds with variant summaries | BR-VAR-004, BR-TAG-007 |
| POST | `/api/user/builds` | Create build + default variant | BR-SAVE-001, BR-SAVE-003, BR-BLD-001 |
| GET | `/api/user/builds/:id` | Build detail + all variants | BR-BLD-001 |
| PATCH | `/api/user/builds/:id` | Update shared fields (subclass, exotic armor, synergies, tags) | BR-BLD-002, BR-BLD-005, BR-TAG-006 |
| DELETE | `/api/user/builds/:id` | Delete build and variants | BR-BLD-001 |
| POST | `/api/user/builds/:id/variants` | Add variant | BR-VAR-001 |
| PATCH | `/api/user/builds/:id/variants/:variantId` | Update variant attachments / exotic weapon / notes | BR-ATT-001, BR-BLD-004 |
| DELETE | `/api/user/builds/:id/variants/:variantId` | Delete variant (not if sole default) | BR-BLD-006 |
| GET | `/api/user/builds/:id/variants/:variantId/resolved` | Resolved equipment slot map | BR-FASH-003, BR-CONF-001 |
| POST | `/api/user/builds/:id/variants/:variantId/suggest-sets` | Explicit set suggestions | BR-SUG-001, BR-TAG-010 |

All routes require authenticated user (**BR-AUTH-001**).

## Create Build Request

**Rules**: BR-BLD-001–003, BR-SAVE-001, BR-SAVE-003, BR-TAG-006 — [FR-022](../spec.md#functional-requirements), [FR-024](../spec.md#functional-requirements), [FR-030](../spec.md#functional-requirements)

```ts
type CreateBuildRequest = {
  name: string;
  className: 'Titan' | 'Hunter' | 'Warlock';
  subclass: object; // BR-VAL-001: generatedBuildSchema.subclass
  exoticArmorHash: number; // BR-BLD-003
  synergyIds: string[]; // BR-SAVE-003: min length 1
  tagIds?: ConceptTagId[]; // BR-TAG-006
  defaultVariant: {
    name?: string; // default "Default"
    notes?: string | null;
    exoticWeaponHash?: number; // BR-BLD-004
    attachments?: SetAttachmentInput[]; // BR-ATT-001
  };
};
```

**Response**: `201` with full build + default variant if save validation passes (**BR-SAVE-001**, **BR-SAVE-002**).

## List / Filter Query Params

**Rules**: BR-VAR-004, BR-TAG-007 — [FR-015](../spec.md#functional-requirements), [FR-031](../spec.md#functional-requirements)

| Param | Rule ID | FR |
|-------|---------|-----|
| `exoticArmorHash` | BR-VAR-004 | [FR-015](../spec.md#functional-requirements) |
| `exoticWeaponHash` | BR-VAR-004 | [FR-015](../spec.md#functional-requirements) |
| `synergyId` | BR-SYN-003 | [FR-024](../spec.md#functional-requirements) |
| `tags` | BR-TAG-007 | [FR-031](../spec.md#functional-requirements) |

- `tags` — comma-separated concept tag ids; **AND semantics** (**BR-TAG-007**)

## Variant Compare Response

**Rules**: BR-VAR-003 — [FR-014](../spec.md#functional-requirements), [FR-015](../spec.md#functional-requirements)

```ts
type VariantCompare = {
  shared: {
    exoticArmor: { hash: number; name: string }; // BR-BLD-003
    subclass: object; // BR-BLD-002
    synergies: Synergy[]; // BR-SYN-003
  };
  variants: Array<{
    id: string;
    name: string;
    notes?: string | null;
    exoticWeapon?: { hash: number; name: string }; // BR-BLD-004
    attachments: VariantSetAttachment[];
    diffSlots: EquipmentSlot[]; // BR-VAR-003
    diffNotes?: boolean; // true when notes differ from default variant
  }>;
};
```

## Error Shape

**Rule**: BR-VAL-001

```ts
type ApiError = {
  error: string;
  code: string; // see set-attachment-contract.md Validation Responses
  details?: Record<string, unknown>;
};
```

Validation uses zod at route boundary (**BR-VAL-001**).

See [set-attachment-contract.md](./set-attachment-contract.md) for shared error codes and [business-rules.md](../../business-rules.md) for full rule definitions.
