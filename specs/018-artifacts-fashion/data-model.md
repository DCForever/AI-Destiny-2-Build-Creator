# Data Model: Artifacts & Fashion

## Entities

### ArtifactSelection (on `build_variants`)

| Field | Type | Notes |
|-------|------|-------|
| artifactHash | number \| null | Must exist in manifest `artifacts` store when set |
| artifactName | string \| null | Denormalized |
| artifactConfig | number[] | Selected unlock/perk hashes; empty when unset/cleared |

**Rules**: At most one artifact identity per variant. Switching hash clears or replaces config in the same write.

### FashionSet

Existing `sets` row with `type = "fashion"`. Items in `set_items` use `FASHION_SLOTS` only.

### FashionAttachment

Existing `variant_set_attachments` row. **Constraint (app)**: ≤1 fashion attachment per variant.

### ResolvedFashionLayer

Derived on read: specified slots only (omit empty). Not merged into combat `equipment`.

### ResolvedArtifact

Derived on read from variant columns; `null` if no hash.

## Migration

1. Add `artifact_hash`, `artifact_name`, `artifact_config` to `build_variants`.
2. Backfill: existing variants → `artifact_hash` NULL, `artifact_config` `'[]'`.
3. No change to attachment table schema.

## Non-identity

Artifact and fashion are **variant** concerns (DBR-ID-010). Changes do not trigger identity confirm/fork.
