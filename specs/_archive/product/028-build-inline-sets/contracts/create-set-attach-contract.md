# Contract: Create Set and Attach from Builds

**Type**: Domain service + existing HTTP APIs  
**Stories**: US1, US5  
**Rules**: FR-001–004, FR-011, FR-016, BR-TAG-004, BR-OPT-001, DBR-CMP-003

## HTTP (compose existing)

### Create Set

`POST /api/user/sets`

Body (existing create set schema): `{ name, type, tagIds? }`  
Auth: signed-in.  
Name uniqueness: per user per type; **auto-suffix** via `allocateUniqueSetName` when caller uses finish helper (never fail solely for collision).

### Attach live (replace-by-type)

Preferred finish path uses domain `replaceAttachmentByType(db, userId, variantId, type, newSetId, now)` after create — same as create-sets attach-now.

Alternatively variant PATCH attachments with merge is acceptable only if product tests prove single covering set per type for finish; **plan standard is replace-by-type**.

## Domain helper

```ts
createSetAndAttach(db, userId, {
  buildId: string;
  variantId: string;
  type: "armor" | "weapon" | "mod" | "pair";
  name?: string;       // default `${build.name} ${Label}`
  tagIds?: string[];
  attachNow?: boolean; // default true
}): Promise<{ set: { id; name; type }; attachment?: { setId; mode: "live"; variantId; replacedSetIds?: string[] } }>;
```

## Errors

| Status / code | When |
|---------------|------|
| 401 | Not signed in |
| 404 | Build/variant not found |
| 400 | Invalid type / validation |
| 409 | Exotic/type constraints if any at create time |

## Link existing

Reuse `SetAttachPicker` + variant attachment update; for finish walkthrough, attaching a set of category type SHOULD replace-by-type live same-type sets so one covering set remains.
