# Contract: Set Item Instance Attachment

**Feature**: 010-instance-disambiguation
**Type**: Additive extension to set item attachment (008 / 001)
**Auth**: Signed-in user (existing set ownership rules)

## Purpose

Let the picker attach a **specific owned copy** to a set slot, recording the copy's `instanceId` alongside the user-selected perks (US3 / FR-012, FR-013). Backward compatible: `instanceId` is optional; existing clients and set items are unaffected (SC-007).

---

## PUT `/api/user/sets/{id}/items` (extended request)

### Request body (`setItemInputSchema`)

```json
{
  "slot": "Helmet",
  "itemHash": 123,
  "itemName": "First Ascent Hood",
  "instanceId": "6917529…",
  "selectedPerks": [111, 222],
  "confirmReplace": false
}
```

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| `slot` | yes | string (min 1) | Existing slot rules for the set type. |
| `itemHash` | yes | positive int | Manifest item identity (unchanged). |
| `itemName` | no | string | Existing. |
| `instanceId` | **no (new)** | string (min 1) | The specific owned copy chosen in the carousel. `NULL`/absent = unspecified copy (legacy behavior). |
| `selectedPerks` | no | int[] | Perk plug hashes to record. For weapons, the user's selection; defaults to the copy's equipped plug hashes when omitted (FR-013). |
| `masterworkHash` | no | int \| null | Existing. |
| `modHashes` | no | int[] | Existing. |
| `confirmReplace` | no | bool | Existing occupied-slot replace confirmation. |

### Response 200

```json
{ "set": { "id": "…", "items": [ { "id": "…", "slot": "Helmet", "itemHash": 123, "instanceId": "6917529…", "selectedPerks": [111,222], "…": "…" } ] } }
```

Each set item (`SetItemRecord`) now includes `instanceId: string | null`.

### Behavior

- Persists `instanceId` on the `set_items` row (nullable `instance_id` column).
- Two different copies of the same `itemHash` attached in turn produce set items distinguishable by `instanceId` (and roll) — FR-012 acceptance.
- **Occupied slot**: unchanged — returns `409 { error: "SLOT_OCCUPIED" }` unless `confirmReplace: true` (FR-019). On confirm, previous occupant is soft-removed and the new copy inserted.
- **Slot compatibility**: unchanged — invalid slot for the set type is rejected as today (FR-019).

### Errors

| Status | Condition |
|--------|-----------|
| `400` | schema validation failure (e.g., empty `instanceId` string, bad `itemHash`) |
| `401` | unsigned |
| `404` | set not found / not owned |
| `409` | `SLOT_OCCUPIED` without `confirmReplace` (unchanged) |

---

## Persistence

| Column | Table | Type | Migration |
|--------|-------|------|-----------|
| `instance_id` | `set_items` | `TEXT NULL` | `ensureSetItemInstanceIdColumn` (idempotent `PRAGMA table_info` + `ALTER TABLE ADD COLUMN`) in `src/lib/db/client.ts`; drizzle `setItems.instanceId` in `schema.ts`; asserted by `schema.test.ts` |

Read shape `SetItemRecord` (`src/lib/sets/setItemService.ts`) gains `instanceId: string | null`.

## Test expectations

- Attaching with `instanceId` persists and returns it on the set item.
- Attaching two copies (same `itemHash`, different `instanceId`) yields two distinguishable set items across sequential add/replace.
- Omitting `instanceId` behaves exactly as today (legacy path; `instance_id` NULL).
- `selectedPerks` omitted → equipped plug hashes recorded by default (verified via service test with an instance's plugs).
- Occupied-slot `409` + `confirmReplace` flow unchanged (regression).
- Migration smoke test: `set_items` has `instance_id` after `runMigrations`; existing rows/tests unaffected.
